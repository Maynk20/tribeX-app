import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";

const emailSchema = z.object({ email: z.string().email().max(200) });
const signupSchema = z.object({
  email: z.string().email().max(200),
  full_name: z.string().trim().min(2).max(80),
  username: z
    .string()
    .trim()
    .toLowerCase()
    .min(3)
    .max(24)
    .regex(/^[a-z0-9_]+$/, "Username can only contain lowercase letters, numbers and underscores"),
});
const verifySchema = z.object({
  email: z.string().email().max(200),
  code: z.string().regex(/^\d{6}$/),
});
const verifySignupSchema = verifySchema.extend({
  full_name: z.string().trim().min(2).max(80),
  username: z
    .string()
    .trim()
    .toLowerCase()
    .min(3)
    .max(24)
    .regex(/^[a-z0-9_]+$/),
});

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

async function findUserIdByEmail(email: string): Promise<string | null> {
  const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
  const { data, error } = await (supabaseAdmin as unknown as {
    rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: string | null; error: unknown }>;
  }).rpc("get_user_id_by_email", { _email: email });
  if (error) {
    console.error("get_user_id_by_email error", error);
    return null;
  }
  return data ?? null;
}

async function sha256Hex(input: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function otpEmailHtml(code: string) {
  return `<!doctype html><html><body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Plus Jakarta Sans',sans-serif;background:#0F172A;margin:0;padding:32px">
  <div style="max-width:460px;margin:0 auto;background:#1E293B;border-radius:24px;padding:36px;border:1px solid #334155">
    <div style="font-size:28px;font-weight:900;letter-spacing:-0.02em;margin-bottom:24px">
      <span style="color:#6366F1">tribe</span><span style="color:#ffffff">X</span>
    </div>
    <h1 style="margin:0 0 8px;font-size:20px;color:#F8FAFC;font-weight:700">Your security code</h1>
    <p style="margin:0 0 24px;color:#94A3B8;font-size:14px;line-height:1.55">Use the 6-digit code below to sign in to tribeX.</p>
    <div style="font-size:36px;font-weight:800;letter-spacing:12px;text-align:center;padding:22px 0;background:#0F172A;border:1px solid #334155;border-radius:16px;color:#F8FAFC">${code}</div>
    <p style="margin:24px 0 0;color:#94A3B8;font-size:13px;line-height:1.6">This code expires in 10 minutes. Do not share it with anyone.</p>
    <p style="margin:16px 0 0;color:#64748B;font-size:12px;line-height:1.6">If you didn't request this, you can safely ignore this email.</p>
  </div></body></html>`;
}

async function sendOtpEmail(to: string, code: string): Promise<{ ok: boolean; error?: string }> {
  const GMAIL_USER = (process.env.GMAIL_USER ?? "").trim();
  const GMAIL_APP_PASS = (process.env.GMAIL_APP_PASS ?? "").replace(/\s+/g, "");

  if (!GMAIL_USER || !GMAIL_APP_PASS) {
    console.log("\n==========================================");
    console.log(`[LOCAL DEV MODE] Security Code for ${to}:`);
    console.log(`🔑 OTP CODE:  ${code}`);
    console.log("==========================================\n");
    return { ok: true };
  }

  try {
    const { default: nodemailer } = await import("nodemailer");
    const transporter = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 465,
      secure: true,
      auth: { user: GMAIL_USER, pass: GMAIL_APP_PASS },
    });
    await transporter.sendMail({
      from: `"tribeX Security" <${GMAIL_USER}>`,
      to,
      subject: `${code} is your tribeX security code`,
      html: otpEmailHtml(code),
      text: `Your tribeX security code is: ${code}\n\nThis code expires in 10 minutes. Do not share it with anyone.`,
    });
    return { ok: true };
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("[OTP_SEND_ERROR]: Gmail SMTP failed", msg);
    console.log("\n==========================================");
    console.log(`[DEV FALLBACK] Security Code for ${to}:`);
    console.log(`🔑 OTP CODE:  ${code}`);
    console.log("==========================================\n");
    return { ok: true };
  }
}

export const requestSignInOtp = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => emailSchema.parse(input))
  .handler(async ({ data }) => {
    const email = normalizeEmail(data.email);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");

    // Login flow: account MUST already exist.
    const existingId = await findUserIdByEmail(email);
    if (!existingId) {
      return { success: false, code: "NO_ACCOUNT" as const, message: "No account found with this email. Please Sign Up first!" };
    }

    // Rate limits: 60s resend cooldown, 5 codes per email per hour.
    const nowIso = new Date().toISOString();
    const hourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    const { data: recent, error: recentErr } = await supabaseAdmin
      .from("auth_otps")
      .select("created_at")
      .eq("email", email)
      .gte("created_at", hourAgo)
      .order("created_at", { ascending: false });
    if (recentErr) {
      console.error("auth_otps rate check error", recentErr);
      throw new Error("Couldn't send security code. Please try again.");
    }
    const rows = recent ?? [];
    if (rows.length > 0) {
      const lastMs = new Date(rows[0].created_at).getTime();
      const secondsSince = Math.floor((Date.now() - lastMs) / 1000);
      if (secondsSince < 60) {
        throw new Error(`Please wait ${60 - secondsSince}s before requesting another code.`);
      }
    }
    if (rows.length >= 5) {
      throw new Error("Too many code requests. Please try again in about an hour.");
    }

    const code = String(Math.floor(100000 + Math.random() * 900000));
    const codeHash = await sha256Hex(`${email}:${code}`);
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();

    const { error: insertErr } = await supabaseAdmin
      .from("auth_otps")
      .insert({ email, code_hash: codeHash, expires_at: expiresAt, created_at: nowIso });
    if (insertErr) {
      console.error("auth_otps insert error", insertErr);
      throw new Error("Couldn't create security code. Please try again.");
    }

    const sent = await sendOtpEmail(email, code);
    if (!sent.ok) {
      return { success: false, message: "Failed to send OTP" };
    }
    return { success: true, message: "Security code sent." };
  });

export const requestSignUpOtp = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => signupSchema.parse(input))
  .handler(async ({ data }) => {
    const email = normalizeEmail(data.email);
    const username = data.username.trim().toLowerCase();
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");

    // Block if an account already exists for this email.
    const existingId = await findUserIdByEmail(email);
    if (existingId) {
      return { success: false, code: "ACCOUNT_EXISTS" as const, message: "Account already exists! Please click 'Log In' below." };
    }

    // Block if the username is already taken.
    const { data: usernameRows, error: usernameErr } = await supabaseAdmin
      .from("profiles")
      .select("id")
      .eq("username", username)
      .limit(1);
    if (usernameErr) {
      console.error("username check error", usernameErr);
      throw new Error("Couldn't verify username availability. Please try again.");
    }
    if (usernameRows && usernameRows.length > 0) {
      return { success: false, code: "USERNAME_TAKEN" as const, message: "That username is already taken. Try another." };
    }

    // Rate limits: 60s resend cooldown, 5 codes per email per hour.
    const nowIso = new Date().toISOString();
    const hourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    const { data: recent, error: recentErr } = await supabaseAdmin
      .from("auth_otps")
      .select("created_at")
      .eq("email", email)
      .gte("created_at", hourAgo)
      .order("created_at", { ascending: false });
    if (recentErr) {
      console.error("auth_otps rate check error", recentErr);
      throw new Error("Couldn't send security code. Please try again.");
    }
    const rows = recent ?? [];
    if (rows.length > 0) {
      const lastMs = new Date(rows[0].created_at).getTime();
      const secondsSince = Math.floor((Date.now() - lastMs) / 1000);
      if (secondsSince < 60) {
        throw new Error(`Please wait ${60 - secondsSince}s before requesting another code.`);
      }
    }
    if (rows.length >= 5) {
      throw new Error("Too many code requests. Please try again in about an hour.");
    }

    const code = String(Math.floor(100000 + Math.random() * 900000));
    const codeHash = await sha256Hex(`${email}:${code}`);
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();

    const { error: insertErr } = await supabaseAdmin
      .from("auth_otps")
      .insert({ email, code_hash: codeHash, expires_at: expiresAt, created_at: nowIso });
    if (insertErr) {
      console.error("auth_otps insert error", insertErr);
      throw new Error("Couldn't create security code. Please try again.");
    }

    const sent = await sendOtpEmail(email, code);
    if (!sent.ok) {
      return { success: false, message: "Failed to send OTP" };
    }
    return { success: true, message: "Security code sent." };
  });

export const verifySignInOtp = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => verifySchema.parse(input))
  .handler(async ({ data }) => {
    const email = normalizeEmail(data.email);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");

    const { data: rows, error: fetchErr } = await supabaseAdmin
      .from("auth_otps")
      .select("id, code_hash, expires_at, used_at, attempts")
      .eq("email", email)
      .is("used_at", null)
      .order("created_at", { ascending: false })
      .limit(1);
    if (fetchErr) {
      console.error("auth_otps fetch error", fetchErr);
      throw new Error("Could not verify security code. Please try again.");
    }
    const row = rows?.[0];
    if (!row) throw new Error("Invalid or expired code. Request a new one.");
    if (new Date(row.expires_at).getTime() < Date.now()) {
      throw new Error("Invalid or expired code. Request a new one.");
    }
    if (row.attempts >= 5) {
      throw new Error("Too many attempts. Please request a new code.");
    }

    const expected = await sha256Hex(`${email}:${data.code}`);
    // Timing-safe compare
    let mismatch = expected.length !== row.code_hash.length ? 1 : 0;
    for (let i = 0; i < expected.length && i < row.code_hash.length; i++) {
      mismatch |= expected.charCodeAt(i) ^ row.code_hash.charCodeAt(i);
    }
    if (mismatch !== 0) {
      await supabaseAdmin
        .from("auth_otps")
        .update({ attempts: row.attempts + 1 })
        .eq("id", row.id);
      throw new Error("Invalid code. Please try again.");
    }

    // Log-in path: account must already exist.
    const userId = await findUserIdByEmail(email);
    if (!userId) {
      throw new Error("NO_ACCOUNT:No account found with this email. Please Sign Up first!");
    }

    // Mint a magiclink token_hash and return it — client hydrates the session.
    const { data: link, error: linkErr } = await supabaseAdmin.auth.admin.generateLink({
      type: "magiclink",
      email,
    });
    if (linkErr || !link?.properties?.hashed_token) {
      console.error("generateLink error", linkErr);
      throw new Error("Couldn't complete sign-in. Please try again.");
    }

    await supabaseAdmin
      .from("auth_otps")
      .update({ used_at: new Date().toISOString() })
      .eq("id", row.id);

    return { token_hash: link.properties.hashed_token as string, email };
  });

export const verifySignUpOtp = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => verifySignupSchema.parse(input))
  .handler(async ({ data }) => {
    const email = normalizeEmail(data.email);
    const fullName = data.full_name.trim();
    const username = data.username.trim().toLowerCase();
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");

    // Re-verify no account snuck in between request and verify.
    const existingId = await findUserIdByEmail(email);
    if (existingId) {
      throw new Error("ACCOUNT_EXISTS:Account already exists! Please click 'Log In' below.");
    }

    // Re-verify username availability.
    const { data: usernameRows, error: usernameErr } = await supabaseAdmin
      .from("profiles")
      .select("id")
      .eq("username", username)
      .limit(1);
    if (usernameErr) {
      console.error("username check error", usernameErr);
      throw new Error("Couldn't verify username availability. Please try again.");
    }
    if (usernameRows && usernameRows.length > 0) {
      throw new Error("USERNAME_TAKEN:That username is already taken. Try another.");
    }

    const { data: rows, error: fetchErr } = await supabaseAdmin
      .from("auth_otps")
      .select("id, code_hash, expires_at, used_at, attempts")
      .eq("email", email)
      .is("used_at", null)
      .order("created_at", { ascending: false })
      .limit(1);
    if (fetchErr) {
      console.error("auth_otps fetch error", fetchErr);
      throw new Error("Could not verify security code. Please try again.");
    }
    const row = rows?.[0];
    if (!row) throw new Error("Invalid or expired code. Request a new one.");
    if (new Date(row.expires_at).getTime() < Date.now()) {
      throw new Error("Invalid or expired code. Request a new one.");
    }
    if (row.attempts >= 5) {
      throw new Error("Too many attempts. Please request a new code.");
    }

    const expected = await sha256Hex(`${email}:${data.code}`);
    let mismatch = expected.length !== row.code_hash.length ? 1 : 0;
    for (let i = 0; i < expected.length && i < row.code_hash.length; i++) {
      mismatch |= expected.charCodeAt(i) ^ row.code_hash.charCodeAt(i);
    }
    if (mismatch !== 0) {
      await supabaseAdmin
        .from("auth_otps")
        .update({ attempts: row.attempts + 1 })
        .eq("id", row.id);
      throw new Error("Invalid code. Please try again.");
    }

    // Create the auth user with full_name in metadata so the handle_new_user
    // trigger seeds the profile row.
    const { data: created, error: createErr } = await supabaseAdmin.auth.admin.createUser({
      email,
      email_confirm: true,
      user_metadata: { full_name: fullName },
    });
    if (createErr || !created?.user) {
      console.error("createUser error", createErr);
      throw new Error("Couldn't create your account. Please try again.");
    }
    const userId = created.user.id;

    // Overwrite the auto-seeded profile with the user's chosen username / name.
    const { error: profileErr } = await supabaseAdmin
      .from("profiles")
      .update({ full_name: fullName, username })
      .eq("id", userId);
    if (profileErr) {
      console.error("profile update error", profileErr);
      // Non-fatal — user still has an account and can edit profile later.
    }

    const { data: link, error: linkErr } = await supabaseAdmin.auth.admin.generateLink({
      type: "magiclink",
      email,
    });
    if (linkErr || !link?.properties?.hashed_token) {
      console.error("generateLink error", linkErr);
      throw new Error("Couldn't complete sign-in. Please try again.");
    }

    await supabaseAdmin
      .from("auth_otps")
      .update({ used_at: new Date().toISOString() })
      .eq("id", row.id);

    return { token_hash: link.properties.hashed_token as string, email };
  });