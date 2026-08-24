import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import {
  Outlet,
  Link,
  createRootRouteWithContext,
  useRouter,
  useRouterState,
  useNavigate,
  HeadContent,
  Scripts,
} from "@tanstack/react-router";
import { type ReactNode, useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";

import appCss from "../styles.css?url";
import { BottomNav } from "../components/bottom-nav";
import { Toaster } from "../components/ui/sonner";
import { GlobalProgressBar, PageLoader } from "../components/ui/loader";
import { useAuth } from "../hooks/use-auth";
import { getProfile, saveVerifiedProfileLocation } from "../lib/services";
import { initOneSignal } from "../lib/onesignal";
import { WelcomeSplash } from "../components/welcome-splash";

function NotFoundComponent() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-7xl font-bold text-foreground">404</h1>
        <h2 className="mt-4 text-xl font-semibold text-foreground">Page not found</h2>
        <p className="mt-2 text-sm text-muted-foreground">
          The page you're looking for doesn't exist or has been moved.
        </p>
        <div className="mt-6">
          <Link
            to="/"
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
          >
            Go home
          </Link>
        </div>
      </div>
    </div>
  );
}

function ErrorComponent({ error, reset }: { error: Error; reset: () => void }) {
  console.error(error);
  const router = useRouter();

  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          This page didn't load
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Something went wrong on our end. You can try refreshing or head back home.
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-2">
          <button
            onClick={() => {
              router.invalidate();
              reset();
            }}
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
          >
            Try again
          </button>
          <a
            href="/"
            className="inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium text-foreground transition-colors hover:bg-accent"
          >
            Go home
          </a>
        </div>
      </div>
    </div>
  );
}

export const Route = createRootRouteWithContext<{ queryClient: QueryClient }>()({
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { title: "tribeX — Find your crew, join the plan" },
      { name: "description", content: "tribeX is a hyper-local activity discovery app. Find box cricket, treks, jams, and pickup games happening near you tonight." },
      { name: "author", content: "tribeX" },
      { property: "og:title", content: "tribeX — Find your crew, join the plan" },
      { property: "og:description", content: "Discover activities happening near you and join a squad in seconds." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
    links: [
      {
        rel: "stylesheet",
        href: appCss,
      },
      { rel: "icon", href: "/favicon.png", type: "image/png" },
      { rel: "icon", href: "/favicon.ico" },
      { rel: "apple-touch-icon", href: "/favicon.png" },
      { rel: "preconnect", href: "https://ovknvssfrsuufuopbeqf.supabase.co" },
      { rel: "dns-prefetch", href: "https://ovknvssfrsuufuopbeqf.supabase.co" },
      { rel: "preconnect", href: "https://fonts.googleapis.com" },
      { rel: "preconnect", href: "https://fonts.gstatic.com", crossOrigin: "anonymous" },
      { rel: "stylesheet", href: "https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@700;800;900&display=swap" },
    ],
  }),
  shellComponent: RootShell,
  component: RootComponent,
  notFoundComponent: NotFoundComponent,
  errorComponent: ErrorComponent,
});

function RootShell({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <head>
        <HeadContent />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  );
}

function RootComponent() {
  const { queryClient } = Route.useRouteContext();

  return (
    <QueryClientProvider client={queryClient}>
      <AppShell />
    </QueryClientProvider>
  );
}

const ONBOARDING_ALLOWED = new Set<string>(["/onboarding", "/auth", "/terms-and-policies", "/complete-profile"]);
const PROFILE_ALLOWED = new Set<string>(["/complete-profile", "/auth", "/terms-and-policies"]);

function AppShell() {
  const { user, loading } = useAuth();
  const navigate = useNavigate();
  const pathname = useRouterState({ select: (s) => s.location.pathname });

  const [showSplash, setShowSplash] = useState(() => {
    if (typeof window !== "undefined") {
      return !window.sessionStorage.getItem("tribex:welcome-shown");
    }
    return true;
  });

  const handleSplashComplete = () => {
    setShowSplash(false);
    if (typeof window !== "undefined") {
      window.sessionStorage.setItem("tribex:welcome-shown", "true");
    }
  };

  const { data: profile } = useQuery({
    queryKey: ["onboarding-status", user?.id],
    queryFn: () => getProfile(user!.id),
    enabled: !!user,
    staleTime: 60_000,
  });

  const needsProfile =
    !!user &&
    !!profile &&
    !(profile as unknown as { has_completed_profile?: boolean }).has_completed_profile;
  const needsOnboarding = !!user && !!profile && !needsProfile && !profile.has_completed_onboarding;

  useEffect(() => {
    if (loading) return;
    if (needsProfile && !PROFILE_ALLOWED.has(pathname)) {
      navigate({ to: "/complete-profile", replace: true });
      return;
    }
    if (needsOnboarding && !ONBOARDING_ALLOWED.has(pathname)) {
      navigate({ to: "/onboarding", replace: true });
    }
  }, [needsProfile, needsOnboarding, pathname, navigate, loading]);

  // Warm up OneSignal once the user is signed in and past onboarding so the
  // subscription-change listener keeps push_token synced across sessions.
  useEffect(() => {
    if (!user || needsOnboarding || needsProfile) return;
    initOneSignal().catch(() => {});
  }, [user, needsOnboarding, needsProfile]);

  // Best-effort silent GPS refresh once per signed-in session. If the profile
  // has no verified location yet, we quietly attempt to save one so the user
  // isn't blocked at join-time. Failures (denied permission, no GPS) are
  // swallowed — the join flow will still surface a clear prompt.
  useEffect(() => {
    if (!user || needsOnboarding || needsProfile || !profile) return;
    if (profile.latitude != null && profile.longitude != null && profile.city) return;
    const key = `tribex:gps-tried:${user.id}`;
    if (typeof window === "undefined" || window.sessionStorage.getItem(key)) return;
    window.sessionStorage.setItem(key, "1");
    saveVerifiedProfileLocation(user.id).catch(() => {});
  }, [user, profile, needsOnboarding, needsProfile]);

  const hideChrome = pathname === "/onboarding" || pathname === "/complete-profile";

  return (
    <div className="mx-auto flex min-h-screen w-full max-w-md flex-col bg-background text-foreground">
      {showSplash && <WelcomeSplash profile={profile} onComplete={handleSplashComplete} />}
      <GlobalProgressBar />
      <main className={hideChrome ? "flex-1" : "flex-1 pb-24"}>
        {loading ? <PageLoader label="Getting things ready" /> : <Outlet />}
      </main>
      {!hideChrome && <BottomNav />}
      <Toaster position="top-center" />
    </div>
  );
}
