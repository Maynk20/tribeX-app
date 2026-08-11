// Server function to fan out a high-priority "URGENT: spot needed" push to
// nearby users whose interests match the plan's category. Runs on the
// Cloudflare Worker so the OneSignal REST key stays server-side.
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";

const inputSchema = z.object({ activityId: z.string().uuid() });

export const notifyUrgentSpot = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => inputSchema.parse(input))
  .handler(async ({ data, context }) => {
    // Only the host of the activity may fan out urgent pushes for it.
    const { data: owner } = await context.supabase
      .from("activities")
      .select("host_id")
      .eq("id", data.activityId)
      .maybeSingle();
    if (!owner || owner.host_id !== context.userId) {
      return { success: false, sent: 0, reason: "Forbidden" };
    }

    const APP_ID = (process.env.ONESIGNAL_APP_ID ?? "").trim();
    const REST_KEY = (process.env.ONESIGNAL_REST_API_KEY ?? "").trim();
    if (!APP_ID || !REST_KEY) {
      return { success: false, sent: 0, reason: "OneSignal not configured" };
    }

    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");

    const { data: act, error: actErr } = await supabaseAdmin
      .from("activities")
      .select("id, title, category, location, host_id, slots_left")
      .eq("id", data.activityId)
      .maybeSingle();
    if (actErr || !act) {
      return { success: false, sent: 0, reason: actErr?.message ?? "Activity not found" };
    }

    // Host display name for the notification body.
    const { data: hostProfile } = await supabaseAdmin
      .from("profiles")
      .select("full_name, username")
      .eq("id", act.host_id)
      .maybeSingle();
    const hostName = hostProfile?.full_name || hostProfile?.username || "A host";

    // Proximity proxy: match by city substring against activity location
    // (profiles don't currently carry lat/lon). Interests must include the
    // plan category to be considered a "nearby match".
    const firstLocPart = (act.location ?? "").split(",")[0]?.trim().toLowerCase() ?? "";
    const { data: recipients, error: recErr } = await supabaseAdmin
      .from("profiles")
      .select("id, city, push_token")
      .neq("id", act.host_id)
      .not("push_token", "is", null)
      .contains("interests", [act.category]);
    if (recErr) {
      console.error("[urgent-push] recipient query failed", recErr);
      return { success: false, sent: 0, reason: recErr.message };
    }

    const locLower = (act.location ?? "").toLowerCase();
    const tokens = (recipients ?? [])
      .filter((r) => {
        const city = (r.city ?? "").trim().toLowerCase();
        if (!city) return false;
        return locLower.includes(city) || (firstLocPart && city.includes(firstLocPart));
      })
      .map((r) => r.push_token as string)
      .filter(Boolean);

    if (tokens.length === 0) return { success: true, sent: 0 };

    const spots = Math.max(1, act.slots_left ?? 1);
    const heading = "🚨 URGENT: Spot open nearby!";
    const body = `${hostName} needs ${spots} player${spots === 1 ? "" : "s"} for ${act.title} in 30 mins. Tap to join!`;

    const CHUNK = 1000;
    let sent = 0;
    for (let i = 0; i < tokens.length; i += CHUNK) {
      const batch = tokens.slice(i, i + CHUNK);
      const res = await fetch("https://api.onesignal.com/notifications", {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          Authorization: `Key ${REST_KEY}`,
        },
        body: JSON.stringify({
          app_id: APP_ID,
          include_subscription_ids: batch,
          target_channel: "push",
          priority: 10,
          headings: { en: heading },
          contents: { en: body },
          url: `/?activity=${act.id}&join=1`,
          data: { activity_id: act.id, type: "urgent_spot" },
        }),
      });
      if (!res.ok) {
        const errBody = await res.text();
        console.error("[urgent-push] OneSignal API error", res.status, errBody);
        continue;
      }
      sent += batch.length;
    }
    return { success: true, sent };
  });