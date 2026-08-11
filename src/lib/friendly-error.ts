// Convert raw Supabase/Postgres errors into human-readable messages.
export function friendlyError(err: unknown, fallback = "Something went wrong on our end. Please try again shortly."): string {
  const raw = err instanceof Error ? err.message : typeof err === "string" ? err : "";
  const msg = raw.toLowerCase();
  if (!raw) return fallback;
  if (msg.includes("permission denied") || msg.includes("not authorized") || msg.includes("rls") || msg.includes("row-level security") || msg.includes("row level security")) {
    return "You don't have permission to perform this action.";
  }
  if (msg.includes("jwt") || msg.includes("session") && msg.includes("expired")) {
    return "Your session expired. Please sign in again.";
  }
  if (msg.includes("already_requested") || (msg.includes("join_requests") && (msg.includes("duplicate") || msg.includes("unique")))) {
    return "You've already requested to join this plan!";
  }
  if (msg.includes("duplicate key") || msg.includes("already exists") || msg.includes("unique constraint")) {
    return "That already exists. Try a different value.";
  }
  if (msg.includes("network") || msg.includes("failed to fetch") || msg.includes("load failed")) {
    return "Network issue. Check your connection and try again.";
  }
  if (msg.includes("invalid login") || msg.includes("invalid credentials")) {
    return "Incorrect email or password.";
  }
  if (msg.includes("email not confirmed")) {
    return "Please verify your email before signing in.";
  }
  // Hide raw SQL/permission jargon
  if (msg.includes("function ") || msg.includes("relation ") || msg.includes("column ") || msg.startsWith("pgrst") || msg.includes("violates")) {
    return fallback;
  }
  // Safe short human message
  if (raw.length < 140) return raw;
  return fallback;
}