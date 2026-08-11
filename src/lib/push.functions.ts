// Server function that sends OneSignal web-push notifications to users whose
// interests + city match a newly created activity. Called from the client
// right after createActivity succeeds; runs on the Cloudflare Worker so the
// REST API key never touches the browser.
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";

const inputSchema = z.object({ activityId: z.string().uuid() });

export const notifyMatchingUsersPush = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input: unknown) => inputSchema.parse(input))
  .handler(async ({ data, context }) => {
    // Only the host of the activity may fan out pushes for it.
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
      .select("id, title, category, location, host_id")
      .eq("id", data.activityId)
      .maybeSingle();
    if (actErr || !act) {
      return { success: false, sent: 0, reason: actErr?.message ?? "Activity not found" };
    }

    // Match: interests contains category AND city is a substring of location (either way).
    const firstLocPart = (act.location ?? "").split(",")[0]?.trim().toLowerCase() ?? "";
    const { data: recipients, error: recErr } = await supabaseAdmin
      .from("profiles")
      .select("id, city, push_token")
      .neq("id", act.host_id)
      .not("push_token", "is", null)
      .contains("interests", [act.category]);
    if (recErr) {
      console.error("[push] recipient query failed", recErr);
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

    // OneSignal caps include_subscription_ids at 2000 per call; chunk defensively.
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
          headings: { en: `New ${act.category} near you!` },
          contents: { en: `${act.title} · ${act.location}` },
          url: typeof act.id === "string" ? `/?activity=${act.id}` : "/",
          web_url: undefined,
          data: { activity_id: act.id, type: "event_match" },
        }),
      });
      if (!res.ok) {
        const body = await res.text();
        console.error("[push] OneSignal API error", res.status, body);
        continue;
      }
      sent += batch.length;
    }
    return { success: true, sent };
  });