// OneSignal Web Push v16 client helper.
// Loads the SDK on demand, initializes once, and exposes helpers to request
// permission and sync the subscription id to the user's profile.
import { supabase } from "@/integrations/supabase/client";

const APP_ID =
  (import.meta.env.VITE_ONESIGNAL_APP_ID as string | undefined) ?? "";

type OneSignalDeferred = Array<(os: OneSignalSdk) => void | Promise<void>>;
type OneSignalSdk = {
  init: (opts: Record<string, unknown>) => Promise<void>;
  User: {
    PushSubscription: {
      id: string | null | undefined;
      optedIn: boolean;
      optIn: () => Promise<void>;
      optOut: () => Promise<void>;
      addEventListener: (
        e: "change",
        cb: (change: { current: { id: string | null; optedIn: boolean } }) => void,
      ) => void;
    };
  };
  Notifications: {
    permission: boolean;
    permissionNative: NotificationPermission;
    requestPermission: () => Promise<boolean>;
  };
  Slidedown: { promptPush: () => Promise<void> };
};

declare global {
  interface Window {
    OneSignal?: OneSignalSdk;
    OneSignalDeferred?: OneSignalDeferred;
  }
}

let sdkPromise: Promise<OneSignalSdk> | null = null;
let listenerAttached = false;

export function isOneSignalConfigured(): boolean {
  return typeof APP_ID === "string" && APP_ID.length > 0;
}

function loadSdk(): Promise<OneSignalSdk> {
  if (typeof window === "undefined") return Promise.reject(new Error("client-only"));
  if (!isOneSignalConfigured()) return Promise.reject(new Error("OneSignal app id missing"));
  if (sdkPromise) return sdkPromise;

  sdkPromise = new Promise((resolve, reject) => {
    if (window.OneSignal) return resolve(window.OneSignal);
    window.OneSignalDeferred = window.OneSignalDeferred ?? [];
    const existing = document.querySelector<HTMLScriptElement>(
      'script[data-onesignal="v16"]',
    );
    if (!existing) {
      const s = document.createElement("script");
      s.src = "https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js";
      s.async = true;
      s.defer = true;
      s.dataset.onesignal = "v16";
      s.onerror = () => reject(new Error("Failed to load OneSignal SDK"));
      document.head.appendChild(s);
    }
    window.OneSignalDeferred.push(async (OneSignal) => {
      try {
        await OneSignal.init({
          appId: APP_ID,
          allowLocalhostAsSecureOrigin: true,
          serviceWorkerPath: "/OneSignalSDKWorker.js",
          notifyButton: { enable: false },
        });
        attachListener(OneSignal);
        resolve(OneSignal);
      } catch (err) {
        reject(err);
      }
    });
  });
  return sdkPromise;
}

function attachListener(os: OneSignalSdk) {
  if (listenerAttached) return;
  listenerAttached = true;
  os.User.PushSubscription.addEventListener("change", (change) => {
    const id = change.current?.id ?? null;
    savePushTokenToProfile(id).catch((e) => console.warn("[OneSignal] save token", e));
  });
}

async function savePushTokenToProfile(token: string | null) {
  const { data } = await supabase.auth.getUser();
  const uid = data.user?.id;
  if (!uid) return;
  await supabase.from("profiles").update({ push_token: token }).eq("id", uid);
}

export async function initOneSignal(): Promise<OneSignalSdk | null> {
  if (!isOneSignalConfigured()) return null;
  try {
    return await loadSdk();
  } catch (e) {
    console.warn("[OneSignal] init failed", e);
    return null;
  }
}

/**
 * Result of a push-permission request.
 * - `granted`  — permission granted and (on web) subscription opted in
 * - `denied`   — the OS/browser has blocked notifications; user must unblock
 *                in browser/system settings (we cannot re-prompt)
 * - `dismissed`— user dismissed the prompt without granting
 * - `unsupported` — no Notification API / OneSignal not configured / SSR
 * - `error`    — unexpected failure (details in `message`)
 */
export type PushPermissionResult =
  | { status: "granted"; token: string | null }
  | { status: "denied"; message: string }
  | { status: "dismissed"; message: string }
  | { status: "unsupported"; message: string }
  | { status: "error"; message: string };

const DENIED_MESSAGE =
  "Notification access is blocked in your browser settings. Click the lock icon (🔒) next to the URL in your browser address bar to allow Notifications.";

function isNativeCapacitor(): boolean {
  if (typeof window === "undefined") return false;
  const cap = (window as unknown as { Capacitor?: { isNativePlatform?: () => boolean } }).Capacitor;
  try {
    return !!cap?.isNativePlatform?.();
  } catch {
    return false;
  }
}

async function requestNativePushPermission(): Promise<PushPermissionResult> {
  try {
    type PermState = "granted" | "denied" | "prompt" | "prompt-with-rationale";
    type PN = {
      checkPermissions: () => Promise<{ receive: PermState }>;
      requestPermissions: () => Promise<{ receive: PermState }>;
      register: () => Promise<void>;
      addListener: (
        e: string,
        cb: (t: { value: string }) => void,
      ) => Promise<{ remove: () => void }>;
    };
    const modName = "@capacitor/push-notifications";
    const mod = (await import(/* @vite-ignore */ modName).catch(() => null)) as
      | { PushNotifications?: PN }
      | null;
    if (!mod?.PushNotifications) {
      return { status: "unsupported", message: "Native push plugin not installed" };
    }
    const { PushNotifications } = mod;
    const current = await PushNotifications.checkPermissions();
    if (current.receive === "denied") return { status: "denied", message: DENIED_MESSAGE };
    let state: PermState = current.receive;
    if (state !== "granted") {
      const asked = await PushNotifications.requestPermissions();
      state = asked.receive;
    }
    if (state !== "granted") {
      const s: PermState = state;
      if (s === "denied") return { status: "denied", message: DENIED_MESSAGE };
      return { status: "dismissed", message: "Notification prompt dismissed" };
    }
    // Register and capture token once.
    const tokenPromise = new Promise<string | null>((resolve) => {
      const timer = setTimeout(() => resolve(null), 6000);
      PushNotifications.addListener("registration", (t) => {
        clearTimeout(timer);
        resolve(t.value);
      }).catch(() => resolve(null));
    });
    await PushNotifications.register();
    const token = await tokenPromise;
    if (token) await savePushTokenToProfile(token);
    return { status: "granted", token };
  } catch (e) {
    return { status: "error", message: e instanceof Error ? e.message : "Native push failed" };
  }
}

export async function requestPushPermission(): Promise<PushPermissionResult> {
  // Native mobile (Capacitor) branch
  if (isNativeCapacitor()) {
    return requestNativePushPermission();
  }

  // Web branch — pre-check the browser Notification permission first so we
  // never trigger a prompt (or throw) when it is already blocked.
  if (typeof window === "undefined" || !("Notification" in window)) {
    return { status: "unsupported", message: "This browser doesn't support notifications." };
  }
  if (Notification.permission === "denied") {
    return { status: "denied", message: DENIED_MESSAGE };
  }

  if (!isOneSignalConfigured()) {
    return { status: "unsupported", message: "Push notifications aren't configured." };
  }

  try {
    const os = await initOneSignal();
    if (!os) return { status: "error", message: "Notification service failed to load." };

    // Permission granted already → skip prompt, just make sure we're opted in.
    const native: NotificationPermission = os.Notifications.permissionNative;
    if (native === "granted") {
      if (!os.User.PushSubscription.optedIn) {
        await os.User.PushSubscription.optIn();
      }
      const id = await waitForSubscriptionId(os);
      if (id) await savePushTokenToProfile(id);
      return { status: "granted", token: id };
    }
    if ((native as string) === "denied") {
      return { status: "denied", message: DENIED_MESSAGE };
    }

    // Default state → trigger the real prompt.
    const granted = await os.Notifications.requestPermission();
    if (!granted) {
      // After the prompt, permission is either "denied" (blocked) or still
      // "default" (user dismissed without choosing).
      if ((Notification.permission as string) === "denied") {
        return { status: "denied", message: DENIED_MESSAGE };
      }
      return { status: "dismissed", message: "Notification prompt dismissed" };
    }
    if (!os.User.PushSubscription.optedIn) {
      await os.User.PushSubscription.optIn();
    }
    const id = await waitForSubscriptionId(os);
    if (id) await savePushTokenToProfile(id);
    return { status: "granted", token: id };
  } catch (e) {
    console.warn("[Push] permission flow failed", e);
    return {
      status: "error",
      message: e instanceof Error ? e.message : "Couldn't enable notifications.",
    };
  }
}

export async function disablePushForCurrentUser(): Promise<void> {
  const os = await initOneSignal();
  if (!os) return;
  try {
    await os.User.PushSubscription.optOut();
  } catch (e) {
    console.warn("[OneSignal] optOut failed", e);
  }
  await savePushTokenToProfile(null);
}

export async function getPushStatus(): Promise<{
  supported: boolean;
  permission: NotificationPermission | "unsupported";
  optedIn: boolean;
  subscriptionId: string | null;
}> {
  if (typeof window === "undefined" || !("Notification" in window)) {
    return { supported: false, permission: "unsupported", optedIn: false, subscriptionId: null };
  }
  if (!isOneSignalConfigured()) {
    return { supported: false, permission: Notification.permission, optedIn: false, subscriptionId: null };
  }
  const os = await initOneSignal();
  if (!os) {
    return { supported: true, permission: Notification.permission, optedIn: false, subscriptionId: null };
  }
  return {
    supported: true,
    permission: os.Notifications.permissionNative,
    optedIn: !!os.User.PushSubscription.optedIn,
    subscriptionId: os.User.PushSubscription.id ?? null,
  };
}

async function waitForSubscriptionId(os: OneSignalSdk, timeoutMs = 4000): Promise<string | null> {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const id = os.User.PushSubscription.id;
    if (id) return id;
    await new Promise((r) => setTimeout(r, 200));
  }
  return os.User.PushSubscription.id ?? null;
}