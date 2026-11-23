import { c as createServerFn } from "./createServerFn-BpgqxZjr.mjs";
import { t as createServerRpc } from "./createServerRpc-D00VjMza.mjs";
import { i as stringType, r as objectType } from "../_libs/zod.mjs";
import { t as requireSupabaseAuth } from "./auth-middleware-CpE-Gg_Y.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/push.functions-BNXYDyoe.js
var inputSchema = objectType({ activityId: stringType().uuid() });
var notifyMatchingUsersPush_createServerFn_handler = createServerRpc({
	id: "6f633a35e95c4fa3aa8de5b5d4fdfdca34939b6f119e9f5f97b744d22b19e44d",
	name: "notifyMatchingUsersPush",
	filename: "src/lib/push.functions.ts"
}, (opts) => notifyMatchingUsersPush.__executeServer(opts));
var notifyMatchingUsersPush = createServerFn({ method: "POST" }).middleware([requireSupabaseAuth]).validator((input) => inputSchema.parse(input)).handler(notifyMatchingUsersPush_createServerFn_handler, async ({ data, context }) => {
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
	const { data: act, error: actErr } = await supabaseAdmin.from("activities").select("id, title, category, location, host_id").eq("id", data.activityId).maybeSingle();
	if (actErr || !act) return {
		success: false,
		sent: 0,
		reason: actErr?.message ?? "Activity not found"
	};
	const firstLocPart = (act.location ?? "").split(",")[0]?.trim().toLowerCase() ?? "";
	const { data: recipients, error: recErr } = await supabaseAdmin.from("profiles").select("id, city, push_token").neq("id", act.host_id).not("push_token", "is", null).contains("interests", [act.category]);
	if (recErr) {
		console.error("[push] recipient query failed", recErr);
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
				headings: { en: `New ${act.category} near you!` },
				contents: { en: `${act.title} · ${act.location}` },
				url: typeof act.id === "string" ? `/?activity=${act.id}` : "/",
				web_url: void 0,
				data: {
					activity_id: act.id,
					type: "event_match"
				}
			})
		});
		if (!res.ok) {
			const body = await res.text();
			console.error("[push] OneSignal API error", res.status, body);
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
export { notifyMatchingUsersPush_createServerFn_handler };
