import { o as __toESM } from "../_runtime.mjs";
import { c as createServerFn, i as TSS_SERVER_FUNCTION } from "./createServerFn-BpgqxZjr.mjs";
import { t as require_nodemailer } from "../_libs/nodemailer.mjs";
import { i as stringType, r as objectType } from "../_libs/zod.mjs";
import { t as renderErrorPage } from "./error-page-DPAiK6Uh.mjs";
import { t as getServerFnById } from "../__23tanstack-start-server-fn-resolver-BaBkVnL5.mjs";
//#region node_modules/.nitro/vite/services/ssr/index.js
var import_nodemailer = /* @__PURE__ */ __toESM(require_nodemailer());
var lastCapturedError;
var TTL_MS = 5e3;
function record(error) {
	lastCapturedError = {
		error,
		at: Date.now()
	};
}
if (typeof globalThis.addEventListener === "function") {
	globalThis.addEventListener("error", (event) => record(event.error ?? event));
	globalThis.addEventListener("unhandledrejection", (event) => record(event.reason));
}
function consumeLastCapturedError() {
	if (!lastCapturedError) return void 0;
	if (Date.now() - lastCapturedError.at > TTL_MS) {
		lastCapturedError = void 0;
		return;
	}
	const { error } = lastCapturedError;
	lastCapturedError = void 0;
	return error;
}
var createSsrRpc = (functionId) => {
	const url = "/_serverFn/" + functionId;
	const serverFnMeta = { id: functionId };
	const fn = async (...args) => {
		return (await getServerFnById(functionId, { origin: "server" }))(...args);
	};
	return Object.assign(fn, {
		url,
		serverFnMeta,
		[TSS_SERVER_FUNCTION]: true
	});
};
var emailSchema = objectType({ email: stringType().email("Please enter a valid email address") });
var signupSchema = objectType({
	email: stringType().email("Please enter a valid email address"),
	full_name: stringType().min(2, "Full name must be at least 2 characters"),
	username: stringType().min(3, "Username must be at least 3 characters").max(24, "Username must be 24 characters or less").regex(/^[a-z0-9_]+$/, "Username can only contain lowercase letters, numbers, and underscores")
});
var verifySchema = objectType({
	email: stringType().email("Please enter a valid email address"),
	code: stringType().length(6, "Code must be 6 digits").regex(/^\d+$/, "Code must contain digits only")
});
var verifySignupSchema = objectType({
	email: stringType().email("Please enter a valid email address"),
	code: stringType().length(6, "Code must be 6 digits").regex(/^\d+$/, "Code must contain digits only"),
	full_name: stringType().min(2, "Full name must be at least 2 characters"),
	username: stringType().min(3, "Username must be at least 3 characters").max(24, "Username must be 24 characters or less").regex(/^[a-z0-9_]+$/, "Username can only contain lowercase letters, numbers, and underscores")
});
function normalizeEmail(email) {
	return email.trim().toLowerCase();
}
async function sha256Hex(message) {
	const enc = new TextEncoder().encode(message);
	const hash = await crypto.subtle.digest("SHA-256", enc);
	return Array.from(new Uint8Array(hash)).map((b) => b.toString(16).padStart(2, "0")).join("");
}
async function findUserIdByEmail(email) {
	const { supabaseAdmin } = await import("./client.server-Blz_ACjp.mjs");
	const { data: rpcData, error: rpcErr } = await supabaseAdmin.rpc("get_user_id_by_email", { _email: email });
	if (!rpcErr && typeof rpcData === "string" && rpcData.length > 0) return rpcData;
	return null;
}
async function sendOtpEmail(to, code) {
	const GMAIL_USER = (process.env.GMAIL_USER || "").trim();
	const GMAIL_APP_PASS = (process.env.GMAIL_APP_PASS || "").replace(/\s+/g, "");
	if (!GMAIL_USER || !GMAIL_APP_PASS) {
		console.log("\n==========================================");
		console.log(`[DEV / LOCAL FALLBACK] Security Code for ${to}:`);
		console.log(`🔑 OTP CODE:  ${code}`);
		console.log("==========================================\n");
		return { ok: true };
	}
	try {
		const transporter = import_nodemailer.default.createTransport({
			host: "smtp.gmail.com",
			port: 465,
			secure: true,
			auth: {
				user: GMAIL_USER,
				pass: GMAIL_APP_PASS
			}
		});
		const htmlBody = `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; border: 1px solid #1e293b; border-radius: 16px; background-color: #0f172a; color: #f8fafc;">
        <h2 style="color: #38bdf8; text-align: center; margin-bottom: 24px;">tribeX Security Code</h2>
        <p style="font-size: 16px; color: #94a3b8; text-align: center;">Use the code below to log in or create your account:</p>
        
        <div style="background-color: #1e293b; border-radius: 12px; padding: 18px; text-align: center; margin: 24px 0; border: 1px solid #334155;">
          <span style="font-size: 36px; font-weight: 800; letter-spacing: 12px; color: #ffffff;">${code}</span>
        </div>
        
        <p style="font-size: 13px; color: #64748b; text-align: center;">This code will expire in 1 hour (60 minutes). If you did not request this, please ignore this email.</p>
        <hr style="border: none; border-top: 1px solid #334155; margin: 24px 0;" />
        <p style="font-size: 12px; color: #475569; text-align: center;">tribeX — Find Local Fun & Connect with People Nearby</p>
      </div>
    `;
		await transporter.sendMail({
			from: `"tribeX" <${GMAIL_USER}>`,
			to,
			subject: `${code} is your tribeX security code`,
			html: htmlBody
		});
		console.log(`[SMTP] Successfully sent OTP code to ${to}`);
		return { ok: true };
	} catch (err) {
		const errorMsg = err instanceof Error ? err.message : String(err);
		console.error("[SMTP ERROR] Failed to send email:", errorMsg);
		console.log("\n==========================================");
		console.log(`[DEV FALLBACK] Security Code for ${to}:`);
		console.log(`🔑 OTP CODE:  ${code}`);
		console.log("==========================================\n");
		return { ok: true };
	}
}
async function handleRequestSignInOtp(inputData) {
	const email = normalizeEmail(emailSchema.parse(inputData).email);
	const { supabaseAdmin } = await import("./client.server-Blz_ACjp.mjs");
	if (!await findUserIdByEmail(email)) return {
		success: false,
		code: "NO_ACCOUNT",
		message: "No account found with this email. Please Sign Up first!"
	};
	const nowIso = (/* @__PURE__ */ new Date()).toISOString();
	const hourAgo = (/* @__PURE__ */ new Date(Date.now() - 3600 * 1e3)).toISOString();
	const { data: recent, error: recentErr } = await supabaseAdmin.from("auth_otps").select("created_at").eq("email", email).gte("created_at", hourAgo).order("created_at", { ascending: false });
	if (recentErr) {
		console.error("auth_otps rate check error", recentErr);
		throw new Error("Couldn't send security code. Please try again.");
	}
	const rows = recent ?? [];
	if (rows.length > 0) {
		const lastMs = new Date(rows[0].created_at).getTime();
		const secondsSince = Math.floor((Date.now() - lastMs) / 1e3);
		if (secondsSince < 60) throw new Error(`Please wait ${60 - secondsSince}s before requesting another code.`);
	}
	if (rows.length >= 5) throw new Error("Too many code requests. Please try again in about an hour.");
	const code = String(Math.floor(1e5 + Math.random() * 9e5));
	const codeHash = await sha256Hex(`${email}:${code}`);
	const expiresAt = new Date(Date.now() + 3600 * 1e3).toISOString();
	const { error: insertErr } = await supabaseAdmin.from("auth_otps").insert({
		email,
		code_hash: codeHash,
		expires_at: expiresAt,
		created_at: nowIso
	});
	if (insertErr) {
		console.error("auth_otps insert error", insertErr);
		throw new Error("Couldn't create security code. Please try again.");
	}
	if (!(await sendOtpEmail(email, code)).ok) return {
		success: false,
		message: "Failed to send OTP"
	};
	return {
		success: true,
		message: "Security code sent."
	};
}
async function handleRequestSignUpOtp(inputData) {
	const data = signupSchema.parse(inputData);
	const email = normalizeEmail(data.email);
	const username = data.username.trim().toLowerCase();
	const { supabaseAdmin } = await import("./client.server-Blz_ACjp.mjs");
	if (await findUserIdByEmail(email)) return {
		success: false,
		code: "ACCOUNT_EXISTS",
		message: "Account already exists! Please click 'Log In' below."
	};
	const { data: usernameRows, error: usernameErr } = await supabaseAdmin.from("profiles").select("id").eq("username", username).limit(1);
	if (usernameErr) {
		console.error("username check error", usernameErr);
		throw new Error("Couldn't verify username availability. Please try again.");
	}
	if (usernameRows && usernameRows.length > 0) return {
		success: false,
		code: "USERNAME_TAKEN",
		message: "That username is already taken. Try another."
	};
	const nowIso = (/* @__PURE__ */ new Date()).toISOString();
	const hourAgo = (/* @__PURE__ */ new Date(Date.now() - 3600 * 1e3)).toISOString();
	const { data: recent, error: recentErr } = await supabaseAdmin.from("auth_otps").select("created_at").eq("email", email).gte("created_at", hourAgo).order("created_at", { ascending: false });
	if (recentErr) {
		console.error("auth_otps rate check error", recentErr);
		throw new Error("Couldn't send security code. Please try again.");
	}
	const rows = recent ?? [];
	if (rows.length > 0) {
		const lastMs = new Date(rows[0].created_at).getTime();
		const secondsSince = Math.floor((Date.now() - lastMs) / 1e3);
		if (secondsSince < 60) throw new Error(`Please wait ${60 - secondsSince}s before requesting another code.`);
	}
	if (rows.length >= 5) throw new Error("Too many code requests. Please try again in about an hour.");
	const code = String(Math.floor(1e5 + Math.random() * 9e5));
	const codeHash = await sha256Hex(`${email}:${code}`);
	const expiresAt = new Date(Date.now() + 3600 * 1e3).toISOString();
	const { error: insertErr } = await supabaseAdmin.from("auth_otps").insert({
		email,
		code_hash: codeHash,
		expires_at: expiresAt,
		created_at: nowIso
	});
	if (insertErr) {
		console.error("auth_otps insert error", insertErr);
		throw new Error("Couldn't create security code. Please try again.");
	}
	if (!(await sendOtpEmail(email, code)).ok) return {
		success: false,
		message: "Failed to send OTP"
	};
	return {
		success: true,
		message: "Security code sent."
	};
}
async function handleVerifySignInOtp(inputData) {
	const data = verifySchema.parse(inputData);
	const email = normalizeEmail(data.email);
	const { supabaseAdmin } = await import("./client.server-Blz_ACjp.mjs");
	const { data: rows, error: fetchErr } = await supabaseAdmin.from("auth_otps").select("id, code_hash, expires_at, used_at, attempts").eq("email", email).is("used_at", null).order("created_at", { ascending: false }).limit(1);
	if (fetchErr) {
		console.error("auth_otps fetch error", fetchErr);
		throw new Error("Could not verify security code. Please try again.");
	}
	const row = rows?.[0];
	if (!row) throw new Error("Invalid or expired code. Request a new one.");
	if (new Date(row.expires_at).getTime() < Date.now()) throw new Error("Invalid or expired code. Request a new one.");
	if (row.attempts >= 5) throw new Error("Too many attempts. Please request a new code.");
	const expected = await sha256Hex(`${email}:${data.code}`);
	let mismatch = expected.length !== row.code_hash.length ? 1 : 0;
	for (let i = 0; i < expected.length && i < row.code_hash.length; i++) mismatch |= expected.charCodeAt(i) ^ row.code_hash.charCodeAt(i);
	if (mismatch !== 0) {
		await supabaseAdmin.from("auth_otps").update({ attempts: row.attempts + 1 }).eq("id", row.id);
		throw new Error("Invalid code. Please try again.");
	}
	if (!await findUserIdByEmail(email)) throw new Error("NO_ACCOUNT:No account found with this email. Please Sign Up first!");
	const { data: link, error: linkErr } = await supabaseAdmin.auth.admin.generateLink({
		type: "magiclink",
		email
	});
	if (linkErr || !link?.properties?.hashed_token) {
		console.error("generateLink error", linkErr);
		throw new Error("Couldn't complete sign-in. Please try again.");
	}
	await supabaseAdmin.from("auth_otps").update({ used_at: (/* @__PURE__ */ new Date()).toISOString() }).eq("id", row.id);
	return {
		token_hash: link.properties.hashed_token,
		email_otp: link.properties.email_otp,
		email
	};
}
async function handleVerifySignUpOtp(inputData) {
	const data = verifySignupSchema.parse(inputData);
	const email = normalizeEmail(data.email);
	const fullName = data.full_name.trim();
	const username = data.username.trim().toLowerCase();
	const { supabaseAdmin } = await import("./client.server-Blz_ACjp.mjs");
	if (await findUserIdByEmail(email)) throw new Error("ACCOUNT_EXISTS:Account already exists! Please click 'Log In' below.");
	const { data: usernameRows, error: usernameErr } = await supabaseAdmin.from("profiles").select("id").eq("username", username).limit(1);
	if (usernameErr) {
		console.error("username check error", usernameErr);
		throw new Error("Couldn't verify username availability. Please try again.");
	}
	if (usernameRows && usernameRows.length > 0) throw new Error("USERNAME_TAKEN:That username is already taken. Try another.");
	const { data: rows, error: fetchErr } = await supabaseAdmin.from("auth_otps").select("id, code_hash, expires_at, used_at, attempts").eq("email", email).is("used_at", null).order("created_at", { ascending: false }).limit(1);
	if (fetchErr) {
		console.error("auth_otps fetch error", fetchErr);
		throw new Error("Could not verify security code. Please try again.");
	}
	const row = rows?.[0];
	if (!row) throw new Error("Invalid or expired code. Request a new one.");
	if (new Date(row.expires_at).getTime() < Date.now()) throw new Error("Invalid or expired code. Request a new one.");
	if (row.attempts >= 5) throw new Error("Too many attempts. Please request a new code.");
	const expected = await sha256Hex(`${email}:${data.code}`);
	let mismatch = expected.length !== row.code_hash.length ? 1 : 0;
	for (let i = 0; i < expected.length && i < row.code_hash.length; i++) mismatch |= expected.charCodeAt(i) ^ row.code_hash.charCodeAt(i);
	if (mismatch !== 0) {
		await supabaseAdmin.from("auth_otps").update({ attempts: row.attempts + 1 }).eq("id", row.id);
		throw new Error("Invalid code. Please try again.");
	}
	const { data: createdUser, error: createErr } = await supabaseAdmin.auth.admin.createUser({
		email,
		email_confirm: true,
		user_metadata: {
			full_name: fullName,
			username
		}
	});
	if (createErr || !createdUser.user) {
		console.error("createUser error", createErr);
		throw new Error("Couldn't create account. Please try again.");
	}
	const userId = createdUser.user.id;
	await supabaseAdmin.from("profiles").upsert({
		id: userId,
		full_name: fullName,
		username,
		has_completed_profile: true,
		has_completed_onboarding: true
	});
	const { data: link, error: linkErr } = await supabaseAdmin.auth.admin.generateLink({
		type: "magiclink",
		email
	});
	if (linkErr || !link?.properties?.hashed_token) {
		console.error("generateLink error", linkErr);
		throw new Error("Account created, but couldn't log you in. Please Log In with your code.");
	}
	await supabaseAdmin.from("auth_otps").update({ used_at: (/* @__PURE__ */ new Date()).toISOString() }).eq("id", row.id);
	return {
		token_hash: link.properties.hashed_token,
		email_otp: link.properties.email_otp,
		email
	};
}
createServerFn({ method: "POST" }).validator((input) => emailSchema.parse(input)).handler(createSsrRpc("6573fa17d594216ecd66e568692b3abb7986d8c15394efed9495f11610aef7fa"));
createServerFn({ method: "POST" }).validator((input) => signupSchema.parse(input)).handler(createSsrRpc("608745bb459720619a94d10a6e3bb42f54aa016ac1fb9c227451b745add0e540"));
createServerFn({ method: "POST" }).validator((input) => verifySchema.parse(input)).handler(createSsrRpc("86c360a3410e5d9d7970f27d9fd909595fa0a33751ac31b1a62c92a0dfdb84be"));
createServerFn({ method: "POST" }).validator((input) => verifySignupSchema.parse(input)).handler(createSsrRpc("59079731bf03f9a8585d9cec8d6c6f695db0d66e5ee6aba0348419c557e3c85e"));
var serverEntryPromise;
async function getServerEntry() {
	if (!serverEntryPromise) serverEntryPromise = import("./server-E3DeXQTH.mjs").then((m) => m.default ?? m);
	return serverEntryPromise;
}
var corsHeaders = {
	"Access-Control-Allow-Origin": "*",
	"Access-Control-Allow-Methods": "POST, OPTIONS",
	"Access-Control-Allow-Headers": "Content-Type, Authorization"
};
async function handleApiOtp(request) {
	const url = new URL(request.url);
	if (request.method === "OPTIONS" && (url.pathname === "/api/otp/request" || url.pathname === "/api/otp/verify")) return new Response(null, { headers: corsHeaders });
	if (request.method === "POST" && url.pathname === "/api/otp/request") try {
		const body = await request.json();
		const mode = body.mode ?? "signin";
		const email = (body.email ?? "").trim().toLowerCase();
		if (mode === "signup") {
			const res = await handleRequestSignUpOtp({
				email,
				full_name: (body.full_name ?? "").trim(),
				username: (body.username ?? "").trim().toLowerCase()
			});
			return Response.json(res, { headers: corsHeaders });
		} else {
			const res = await handleRequestSignInOtp({ email });
			return Response.json(res, { headers: corsHeaders });
		}
	} catch (e) {
		const msg = e instanceof Error ? e.message : String(e);
		return Response.json({
			success: false,
			message: msg
		}, {
			status: 400,
			headers: corsHeaders
		});
	}
	if (request.method === "POST" && url.pathname === "/api/otp/verify") try {
		const body = await request.json();
		const mode = body.mode ?? "signin";
		const email = (body.email ?? "").trim().toLowerCase();
		const code = (body.code ?? "").trim();
		if (mode === "signup") {
			const res = await handleVerifySignUpOtp({
				email,
				code,
				full_name: (body.full_name ?? "").trim(),
				username: (body.username ?? "").trim().toLowerCase()
			});
			return Response.json(res, { headers: corsHeaders });
		} else {
			const res = await handleVerifySignInOtp({
				email,
				code
			});
			return Response.json(res, { headers: corsHeaders });
		}
	} catch (e) {
		const msg = e instanceof Error ? e.message : String(e);
		return Response.json({
			success: false,
			message: msg
		}, {
			status: 400,
			headers: corsHeaders
		});
	}
	return null;
}
async function normalizeCatastrophicSsrResponse(response) {
	if (response.status < 500) return response;
	if (!(response.headers.get("content-type") ?? "").includes("application/json")) return response;
	const body = await response.clone().text();
	if (!isH3SwallowedErrorBody(body)) return response;
	console.error(consumeLastCapturedError() ?? /* @__PURE__ */ new Error(`h3 swallowed SSR error: ${body}`));
	return new Response(renderErrorPage(), {
		status: 500,
		headers: { "content-type": "text/html; charset=utf-8" }
	});
}
function isH3SwallowedErrorBody(body) {
	try {
		const payload = JSON.parse(body);
		return payload.unhandled === true && payload.message === "HTTPError";
	} catch {
		return false;
	}
}
var server_default = { async fetch(request, env, ctx) {
	try {
		const apiResponse = await handleApiOtp(request);
		if (apiResponse) return apiResponse;
		return await normalizeCatastrophicSsrResponse(await (await getServerEntry()).fetch(request, env, ctx));
	} catch (error) {
		console.error(error);
		return new Response(renderErrorPage(), {
			status: 500,
			headers: { "content-type": "text/html; charset=utf-8" }
		});
	}
} };
//#endregion
export { server_default as default, createSsrRpc as t };
