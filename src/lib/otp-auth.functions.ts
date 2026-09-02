import { createServerFn } from "@tanstack/react-start";
import nodemailer from "nodemailer";
import { z } from "zod";

const emailSchema = z.object({
  email: z.string().email("Please enter a valid email address"),
});

const signupSchema = z.object({
  email: z.string().email("Please enter a valid email address"),
  full_name: z.string().min(2, "Full name must be at least 2 characters"),
  username: z
    .string()
    .min(3, "Username must be at least 3 characters")
    .max(24, "Username must be 24 characters or less")
    .regex(/^[a-z0-9_]+$/, "Username can only contain lowercase letters, numbers, and underscores"),
});

const verifySchema = z.object({
  email: z.string().email("Please enter a valid email address"),
  code: z.string().length(6, "Code must be 6 digits").regex(/^\d+$/, "Code must contain digits only"),
});

const verifySignupSchema = z.object({
  email: z.string().email("Please enter a valid email address"),
  code: z.string().length(6, "Code must be 6 digits").regex(/^\d+$/, "Code must contain digits only"),
  full_name: z.string().min(2, "Full name must be at least 2 characters"),
  username: z
    .string()
    .min(3, "Username must be at least 3 characters")
    .max(24, "Username must be 24 characters or less")
    .regex(/^[a-z0-9_]+$/, "Username can only contain lowercase letters, numbers, and underscores"),
});

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

async function sha256Hex(message: string): Promise<string> {
  const enc = new TextEncoder().encode(message);
  const hash = await crypto.subtle.digest("SHA-256", enc);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function findUserIdByEmail(email: string): Promise<string | null> {
  const { supabaseAdmin } = await import("@/integrations/supabase/client.server");

  const { data: profData } = await supabaseAdmin
    .from("profiles")
    .select("id")
    .eq("email", email)
    .maybeSingle();

  if (profData?.id) return profData.id;

  const { data: rpcData, error: rpcErr } = await supabaseAdmin.rpc("get_user_id_by_email", {
    _email: email,
  });

  if (!rpcErr && typeof rpcData === "string" && rpcData.length > 0) {
    return rpcData;
  }

  return null;
}

async function sendOtpEmail(to: string, code: string): Promise<{ ok: boolean; error?: string }> {
  const GMAIL_USER = (process.env.GMAIL_USER || "tribex.apk@gmail.com").trim();
  const GMAIL_APP_PASS = (process.env.GMAIL_APP_PASS || "xmva hdqc hoqq xkly").replace(/\s+/g, "");

  if (!GMAIL_USER || !GMAIL_APP_PASS) {
    console.log("\n==========================================");
    console.log(`[DEV FALLBACK] Security Code for ${to}:`);
    console.log(`🔑 OTP CODE:  ${code}`);
    console.log("==========================================\n");
    return { ok: true };
  }

  try {
    const transporter = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 465,
      secure: true,
      auth: {
        user: GMAIL_USER,
        pass: GMAIL_APP_PASS,
      },
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
      html: htmlBody,
    });

    console.log(`[SMTP] Successfully sent OTP code to ${to}`);
    return { ok: true };
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    console.error("[SMTP ERROR] Failed to send email:", errorMsg);
    console.log("\n==========================================");
    console.log(`[DEV FALLBACK] Security Code for ${to}:`);
    console.log(`🔑 OTP CODE:  ${code}`);
    console.log("==========================================\n");
    return { ok: true };
  }
}

export async function handleRequestSignInOtp(inputData: { email: string }) {
  const data = emailSchema.parse(inputData);
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
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();

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
}

export async function handleRequestSignUpOtp(inputData: { email: string; full_name: string; username: string }) {
  const data = signupSchema.parse(inputData);
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
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();

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
}

export async function handleVerifySignInOtp(inputData: { email: string; code: string }) {
  const data = verifySchema.parse(inputData);
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

  const userId = await findUserIdByEmail(email);
  if (!userId) {
    throw new Error("NO_ACCOUNT:No account found with this email. Please Sign Up first!");
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

  return {
    token_hash: link.properties.hashed_token as string,
    email_otp: link.properties.email_otp as string | undefined,
    email,
  };
}

export async function handleVerifySignUpOtp(inputData: { email: string; code: string; full_name: string; username: string }) {
  const data = verifySignupSchema.parse(inputData);
  const email = normalizeEmail(data.email);
  const fullName = data.full_name.trim();
  const username = data.username.trim().toLowerCase();
  const { supabaseAdmin } = await import("@/integrations/supabase/client.server");

  const existingId = await findUserIdByEmail(email);
  if (existingId) {
    throw new Error("ACCOUNT_EXISTS:Account already exists! Please click 'Log In' below.");
  }

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

  const { data: createdUser, error: createErr } = await supabaseAdmin.auth.admin.createUser({
    email,
    email_confirm: true,
    user_metadata: { full_name: fullName, username },
  });
  if (createErr || !createdUser.user) {
    console.error("createUser error", createErr);
    throw new Error("Couldn't create account. Please try again.");
  }
  const userId = createdUser.user.id;

  await supabaseAdmin
    .from("profiles")
    .upsert({
      id: userId,
      email,
      full_name: fullName,
      username,
      has_completed_profile: true,
      has_completed_onboarding: true,
    });

  const { data: link, error: linkErr } = await supabaseAdmin.auth.admin.generateLink({
    type: "magiclink",
    email,
  });
  if (linkErr || !link?.properties?.hashed_token) {
    console.error("generateLink error", linkErr);
    throw new Error("Account created, but couldn't log you in. Please Log In with your code.");
  }

  await supabaseAdmin
    .from("auth_otps")
    .update({ used_at: new Date().toISOString() })
    .eq("id", row.id);

  return {
    token_hash: link.properties.hashed_token as string,
    email_otp: link.properties.email_otp as string | undefined,
    email,
  };
}

// TanStack Start createServerFn exports for Web client
export const requestSignInOtp = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => emailSchema.parse(input))
  .handler(async ({ data }) => handleRequestSignInOtp(data));

export const requestSignUpOtp = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => signupSchema.parse(input))
  .handler(async ({ data }) => handleRequestSignUpOtp(data));

export const verifySignInOtp = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => verifySchema.parse(input))
  .handler(async ({ data }) => handleVerifySignInOtp(data));

export const verifySignUpOtp = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => verifySignupSchema.parse(input))
  .handler(async ({ data }) => handleVerifySignUpOtp(data));