import { useEffect, useState } from "react";
import type { Session, User } from "@supabase/supabase-js";
import { supabase } from "@/integrations/supabase/client";

function getInitialSession(): { session: Session | null; user: User | null } {
  if (typeof window === "undefined") return { session: null, user: null };
  try {
    const key = Object.keys(localStorage).find(
      (k) => (k.startsWith("sb-") && k.endsWith("-auth-token")) || k.includes("auth-token"),
    );
    if (key) {
      const parsed = JSON.parse(localStorage.getItem(key) || "");
      const sess = parsed?.session ?? parsed;
      if (sess?.user && (sess?.access_token || parsed?.access_token)) {
        return { session: sess as Session, user: sess.user as User };
      }
    }
  } catch {}
  return { session: null, user: null };
}

export function useAuth() {
  const [session, setSession] = useState<Session | null>(() => getInitialSession().session);
  const [user, setUser] = useState<User | null>(() => getInitialSession().user);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => {
      setSession(s);
      setUser(s?.user ?? null);
      setLoading(false);
    });
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setUser(data.session?.user ?? null);
      setLoading(false);
    });
    return () => sub.subscription.unsubscribe();
  }, []);

  return { session, user, loading };
}