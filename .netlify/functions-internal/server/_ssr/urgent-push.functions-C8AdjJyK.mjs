import { c as createServerFn } from "./createServerFn-BpgqxZjr.mjs";
import { t as createServerRpc } from "./createServerRpc-D00VjMza.mjs";
import { i as stringType, r as objectType } from "../_libs/zod.mjs";
import { t as requireSupabaseAuth } from "./auth-middleware-CpE-Gg_Y.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/urgent-push.functions-C8AdjJyK.js
var inputSchema = objectType({ activityId: stringType().uuid() });
var notifyUrgentSpot_createServerFn_handler = createServerRpc({
	id: "1c3f60340e6cffa28db7486b10fb3af65e2895164fcc6f0c6290e737ffe6498b",
	name: "notifyUrgentSpot",
	filename: "src/lib/urgent-push.functions.ts"
}, (opts) => notifyUrgentSpot.__executeServer(opts));
var notifyUrgentSpot = createServerFn({ method: "POST" }).middleware([requireSupabaseAuth]).validator((input) => inputSchema.parse(input)).handler(notifyUrgentSpot_createServerFn_handler, async ({ data, context }) => {
	const { data: owner } = await context.supabase.from("activities").select("host_id").eq("id", data.activityId).maybeSingle();
	if (!owner || owner.host_id !== context.userId) return {
		success: false,
		sent: 0,
		reason: "Forbidden"
	};
	const APP_ID = (process.env.ONESIGNAL_APP_ID ?? "").trim();
	const REST_KEY = (process.env.ONESIGNAL_REST_API_KEY ?? "").trim();
	if (!APP_ID || !REST_KEY) return {
		success: false,
		sent: 0,
		reason: "OneSignal not configured"
	};
	const { supabaseAdmin } = await import("./client.server-Blz_ACjp.mjs");
	const { data: act, error: actErr } = await supabaseAdmin.from("activities").select("id, title, category, location, host_id, slots_left").eq("id", data.activityId).maybeSingle();
	if (actErr || !act) return {
		success: false,
		sent: 0,
		reason: actErr?.message ?? "Activity not found"
	};
	const { data: hostProfile } = await supabaseAdmin.from("profiles").select("full_name, username").eq("id", act.host_id).maybeSingle();
	const hostName = hostProfile?.full_name || hostProfile?.username || "A host";
	const firstLocPart = (act.location ?? "").split(",")[0]?.trim().toLowerCase() ?? "";
	const { data: recipients, error: recErr } = await supabaseAdmin.from("profiles").select("id, city, push_token").neq("id", act.host_id).not("push_token", "is", null).contains("interests", [act.category]);
	if (recErr) {
		console.error("[urgent-push] recipient query failed", recErr);
		return {
			success: false,
			sent: 0,
			reason: recErr.message
		};
	}
	const locLower = (act.location ?? "").toLowerCase();
	const tokens = (recipients ?? []).filter((r) => {
		const city = (r.city ?? "").trim().toLowerCase();
		if (!city) return false;
		return locLower.includes(city) || firstLocPart && city.includes(firstLocPart);
	}).map((r) => r.push_token).filter(Boolean);
	if (tokens.length === 0) return {
		success: true,
		sent: 0
	};
	const spots = Math.max(1, act.slots_left ?? 1);
	const heading = "🚨 URGENT: Spot open nearby!";
	const body = `${hostName} needs ${spots} player${spots === 1 ? "" : "s"} for ${act.title} in 30 mins. Tap to join!`;
	const CHUNK = 1e3;
	let sent = 0;
	for (let i = 0; i < tokens.length; i += CHUNK) {
		const batch = tokens.slice(i, i + CHUNK);
		const res = await fetch("https://api.onesignal.com/notifications", {
			method: "POST",
			headers: {
				"Content-Type": "application/json; charset=utf-8",
				Authorization: `Key ${REST_KEY}`
			},
			body: JSON.stringify({
				app_id: APP_ID,
				include_subscription_ids: batch,
				target_channel: "push",
				priority: 10,
				headings: { en: heading },
				contents: { en: body },
				url: `/?activity=${act.id}&join=1`,
				data: {
					activity_id: act.id,
					type: "urgent_spot"
				}
			})
		});
		if (!res.ok) {
			const errBody = await res.text();
			console.error("[urgent-push] OneSignal API error", res.status, errBody);
			continue;
		}
		sent += batch.length;
	}
	return {
		success: true,
		sent
	};
});
//#endregion
export { notifyUrgentSpot_createServerFn_handler };
