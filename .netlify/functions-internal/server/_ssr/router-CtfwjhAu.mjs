import { o as __toESM } from "../_runtime.mjs";
import { c as createServerFn } from "./createServerFn-BpgqxZjr.mjs";
import { t as require_nodemailer } from "../_libs/nodemailer.mjs";
import { a as ZodIssueCode, i as stringType, n as numberType, r as objectType, t as booleanType } from "../_libs/zod.mjs";
import { t as requireSupabaseAuth } from "./auth-middleware-CpE-Gg_Y.mjs";
import { t as createSsrRpc } from "./ssr.mjs";
import { t as supabase } from "./client-ABWpb9Cr.mjs";
import { l as require_react_dom, u as require_react } from "../_libs/@floating-ui/react-dom+[...].mjs";
import { a as useRouterState, c as Outlet, d as Link, f as useNavigate, i as HeadContent, l as createFileRoute, m as isRedirect, p as useRouter, r as Scripts, s as createRouter, u as createRootRouteWithContext } from "../_libs/@tanstack/react-router+[...].mjs";
import { n as require_jsx_runtime } from "../_libs/radix-ui__react-context+react.mjs";
import { t as QueryClient } from "../_libs/tanstack__query-core.mjs";
import { a as QueryClientProvider, i as useQuery, n as useIsMutating, o as useQueryClient, r as useIsFetching, t as useMutation } from "../_libs/tanstack__react-query.mjs";
import { $ as Languages, A as Plus, At as Car, B as Mic, Bt as BadgeCheck, C as ShieldCheck, Ct as Clapperboard, D as Search, Dt as ChevronRight, E as Send, Et as ChevronsUpDown, F as Palette, Ft as BookOpen, G as LogOut, Gt as Activity, H as MapPinned, Ht as ArrowUpDown, I as Navigation, It as BookMarked, J as LoaderCircle, K as LogIn, L as Music, Lt as Bike, M as Phone, Mt as Calendar, N as Pencil, Nt as CalendarDays, O as ScrollText, Ot as ChevronDown, P as PenTool, Pt as Briefcase, Q as Laptop, R as Monitor, Rt as Bell, S as Shield, St as Clock, T as Share2, Tt as CircleCheck, U as MapPin, Ut as ArrowRight, V as MessageCircle, Vt as AtSign, W as Mail, Wt as ArrowLeft, X as LifeBuoy, Y as Link$1, Z as Library, _ as Tag, _t as Dices, a as Video, at as Hash, b as Smartphone, bt as Coffee, c as User, ct as Footprints, d as Type, dt as Film, et as Info, f as Tv, ft as FileText, g as TextAlignStart, gt as DollarSign, h as Trash2, ht as Download, i as VolumeX, it as HeartPulse, j as Plug, jt as Camera, k as Rocket, kt as Check, l as UserX, lt as Flame, m as TriangleAlert, mt as Dumbbell, n as X, nt as Image$1, o as UtensilsCrossed, ot as Globe, p as Trophy, pt as Eye, q as Lock, r as Wifi, rt as Hourglass, s as Users, st as Gamepad2, t as Zap, tt as IndianRupee, u as UserCog, ut as Flag, v as Star, vt as Crown, w as ShieldAlert, wt as CirclePlus, x as SlidersHorizontal, xt as CodeXml, y as Sparkles, yt as Compass, z as MonitorSmartphone, zt as BellOff } from "../_libs/lucide-react.mjs";
import { n as toast, t as Toaster } from "../_libs/sonner.mjs";
import { t as clsx } from "../_libs/clsx.mjs";
import { t as twMerge } from "../_libs/tailwind-merge.mjs";
import { a as DialogOverlay$1, i as DialogDescription$1, n as DialogClose, o as DialogPortal$1, r as DialogContent$1, s as DialogTitle$1, t as Dialog$1 } from "../_libs/@radix-ui/react-dialog+[...].mjs";
import { i as Trigger, n as Portal, r as Root2, t as Content2 } from "../_libs/@radix-ui/react-popover+[...].mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/router-CtfwjhAu.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
require_nodemailer();
var import_react_dom = /* @__PURE__ */ __toESM(require_react_dom());
function useServerFn(serverFn) {
	const router = useRouter();
	return import_react.useCallback(async (...args) => {
		try {
			const res = await serverFn(...args);
			if (isRedirect(res)) throw res;
			return res;
		} catch (err) {
			if (isRedirect(err)) {
				err.options._fromLocation = router.stores.location.get();
				return router.navigate(router.resolveRedirect(err).options);
			}
			throw err;
		}
	}, [router, serverFn]);
}
var styles_default = "/assets/styles-BvJds7_A.css";
var linkClass = "group relative flex flex-1 flex-col items-center gap-1 rounded-2xl px-2 py-2 text-[11px] font-medium text-muted-foreground transition-all duration-150 active:scale-95 data-[status=active]:text-primary";
function TabInner({ Icon, label }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Icon, {
			className: "h-5 w-5 transition-transform duration-150 group-data-[status=active]:scale-110",
			strokeWidth: 2.2
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
			className: "tracking-wide",
			children: label
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { className: "absolute -top-[9px] left-1/2 h-1 w-8 -translate-x-1/2 rounded-full bg-primary opacity-0 transition-opacity duration-200 group-data-[status=active]:opacity-100" })
	] });
}
function BottomNav() {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("nav", {
		className: "fixed bottom-0 left-1/2 z-40 w-full max-w-md -translate-x-1/2 border-t border-border/60 bg-background/85 backdrop-blur-xl",
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("ul", {
			className: "grid grid-cols-4 px-2 pb-[env(safe-area-inset-bottom)] pt-2",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", {
					className: "flex",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
						to: "/",
						activeOptions: { exact: true },
						preload: "intent",
						className: linkClass,
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TabInner, {
							Icon: Compass,
							label: "Explore"
						})
					})
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", {
					className: "flex",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
						to: "/create",
						activeOptions: { exact: true },
						preload: "intent",
						className: linkClass,
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TabInner, {
							Icon: CirclePlus,
							label: "Create"
						})
					})
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", {
					className: "flex",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
						to: "/messages",
						activeOptions: { exact: true },
						preload: "intent",
						className: linkClass,
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TabInner, {
							Icon: MessageCircle,
							label: "Messages"
						})
					})
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", {
					className: "flex",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
						to: "/profile",
						activeOptions: { exact: true },
						preload: "intent",
						className: linkClass,
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TabInner, {
							Icon: User,
							label: "Profile"
						})
					})
				})
			]
		})
	});
}
var Toaster$1 = ({ ...props }) => {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Toaster, {
		className: "toaster group",
		toastOptions: { classNames: {
			toast: "group toast group-[.toaster]:bg-background group-[.toaster]:text-foreground group-[.toaster]:border-border group-[.toaster]:shadow-lg",
			description: "group-[.toast]:text-muted-foreground",
			actionButton: "group-[.toast]:bg-primary group-[.toast]:text-primary-foreground",
			cancelButton: "group-[.toast]:bg-muted group-[.toast]:text-muted-foreground"
		} },
		...props
	});
};
function cn(...inputs) {
	return twMerge(clsx(inputs));
}
/**
* Unified loading primitives for tribeX. All async surfaces should render one
* of these so users see the same animation, timing, and colour treatment.
*/
function Spinner$1({ className, size = 16 }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, {
		"aria-hidden": "true",
		style: {
			width: size,
			height: size
		},
		className: cn("animate-spin text-primary", className)
	});
}
/** Full-viewport loader used for route transitions and Suspense fallbacks. */
function PageLoader$1({ label = "Loading" }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		role: "status",
		"aria-live": "polite",
		className: "flex min-h-[60vh] w-full flex-col items-center justify-center gap-3 px-6 text-center animate-fade-in",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
			className: "flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Spinner$1, { size: 22 })
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
			className: "text-sm font-medium text-muted-foreground",
			children: [label, "…"]
		})]
	});
}
/** Skeleton line/block. Composes into cards, rows, avatars. */
function SkeletonBlock({ className }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		"aria-hidden": "true",
		className: cn("animate-pulse rounded-2xl bg-card", className)
	});
}
/** Consistent card skeleton for feed / plan / chat previews. */
function CardSkeleton({ className }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		"aria-hidden": "true",
		className: cn("animate-pulse rounded-3xl border border-border/60 bg-card p-4", className),
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "flex items-center gap-3",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-11 w-11 rounded-full bg-primary/10" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex-1 space-y-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-3 w-1/2 rounded bg-primary/10" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-3 w-1/3 rounded bg-primary/10" })]
			})]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "mt-4 space-y-2",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-3 w-full rounded bg-primary/10" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-3 w-4/5 rounded bg-primary/10" })]
		})]
	});
}
function ListSkeleton({ count = 3, variant = "card", className }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: cn("flex flex-col gap-3", className),
		role: "status",
		"aria-live": "polite",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
			className: "sr-only",
			children: "Loading…"
		}), Array.from({ length: count }).map((_, i) => variant === "card" ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardSkeleton, {}, i) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SkeletonBlock, { className: "h-16" }, i))]
	});
}
/**
* Thin animated progress bar shown at the top of the app whenever a route is
* transitioning, a query is fetching, or a mutation is in-flight. Keeps the UI
* responsive during background work without blocking interaction.
*/
function GlobalProgressBar() {
	const isRouting = useRouterState({ select: (s) => s.isLoading || s.isTransitioning });
	const fetching = useIsFetching();
	const mutating = useIsMutating();
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		"aria-hidden": "true",
		className: cn("pointer-events-none fixed inset-x-0 top-0 z-[100000] h-0.5 overflow-hidden transition-opacity duration-200", isRouting || fetching > 0 || mutating > 0 ? "opacity-100" : "opacity-0"),
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-full w-1/3 animate-[loader-slide_1.2s_ease-in-out_infinite] bg-gradient-to-r from-transparent via-primary to-transparent" })
	});
}
function getInitialSession$1() {
	if (typeof window === "undefined") return {
		session: null,
		user: null
	};
	try {
		const key = Object.keys(localStorage).find((k) => k.startsWith("sb-") && k.endsWith("-auth-token") || k.includes("auth-token"));
		if (key) {
			const parsed = JSON.parse(localStorage.getItem(key) || "");
			const sess = parsed?.session ?? parsed;
			if (sess?.user && (sess?.access_token || parsed?.access_token)) return {
				session: sess,
				user: sess.user
			};
		}
	} catch {}
	return {
		session: null,
		user: null
	};
}
function useAuth$1() {
	const [session, setSession] = (0, import_react.useState)(() => getInitialSession$1().session);
	const [user, setUser] = (0, import_react.useState)(() => getInitialSession$1().user);
	const [loading, setLoading] = (0, import_react.useState)(false);
	(0, import_react.useEffect)(() => {
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
	return {
		session,
		user,
		loading
	};
}
async function getProfile$1(userId) {
	const { data, error } = await supabase.from("profiles").select("*").eq("id", userId).maybeSingle();
	if (error) throw error;
	return data;
}
async function updateProfile$1(userId, patch) {
	const { data, error } = await supabase.from("profiles").update(patch).eq("id", userId).select().single();
	if (error) throw error;
	return data;
}
async function saveVerifiedProfileLocation$1(userId) {
	const coords = await getCurrentCoords$1();
	let city = `Near ${coords.latitude.toFixed(2)}, ${coords.longitude.toFixed(2)}`;
	try {
		const url = `https://nominatim.openstreetmap.org/reverse?format=json&addressdetails=1&lat=${coords.latitude}&lon=${coords.longitude}&accept-language=en`;
		const ctrl = new AbortController();
		const timer = setTimeout(() => ctrl.abort(), 3e3);
		const res = await fetch(url, {
			headers: { Accept: "application/json" },
			signal: ctrl.signal
		}).finally(() => clearTimeout(timer));
		if (res.ok) {
			const data = await res.json();
			const a = data.address ?? {};
			const locality = a.suburb || a.neighbourhood || a.village || a.hamlet || a.town || a.city;
			const cityName = a.city || a.town || a.village || a.county || a.state;
			city = locality && cityName && locality !== cityName ? `${locality}, ${cityName}` : locality || cityName || data.display_name || city;
		}
	} catch {}
	return updateProfile$1(userId, {
		city,
		latitude: coords.latitude,
		longitude: coords.longitude
	});
}
function getCurrentCoords$1() {
	return new Promise((resolve, reject) => {
		if (typeof navigator === "undefined" || !navigator.geolocation) {
			reject(/* @__PURE__ */ new Error("Geolocation is not supported on this device"));
			return;
		}
		const opts1 = {
			enableHighAccuracy: false,
			timeout: 12e3,
			maximumAge: 600 * 1e3
		};
		const opts2 = {
			enableHighAccuracy: false,
			timeout: 2e4,
			maximumAge: Infinity
		};
		navigator.geolocation.getCurrentPosition((pos) => resolve(pos.coords), () => {
			navigator.geolocation.getCurrentPosition((pos) => resolve(pos.coords), (err) => {
				const code = err.code;
				if (code === 1) reject(/* @__PURE__ */ new Error("Location permission denied. Enable it in your browser settings."));
				else if (code === 2) reject(/* @__PURE__ */ new Error("Location unavailable. Check that GPS is on and try again."));
				else reject(/* @__PURE__ */ new Error("Getting your location is taking too long. Move near a window or try again."));
			}, opts2);
		}, opts1);
	});
}
var APP_ID$1 = "";
var sdkPromise$1 = null;
var listenerAttached$1 = false;
function isOneSignalConfigured$1() {
	return false;
}
function loadSdk$1() {
	if (typeof window === "undefined") return Promise.reject(/* @__PURE__ */ new Error("client-only"));
	if (!isOneSignalConfigured$1()) return Promise.reject(/* @__PURE__ */ new Error("OneSignal app id missing"));
	if (sdkPromise$1) return sdkPromise$1;
	sdkPromise$1 = new Promise((resolve, reject) => {
		if (window.OneSignal) return resolve(window.OneSignal);
		window.OneSignalDeferred = window.OneSignalDeferred ?? [];
		if (!document.querySelector("script[data-onesignal=\"v16\"]")) {
			const s = document.createElement("script");
			s.src = "https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js";
			s.async = true;
			s.defer = true;
			s.dataset.onesignal = "v16";
			s.onerror = () => reject(/* @__PURE__ */ new Error("Failed to load OneSignal SDK"));
			document.head.appendChild(s);
		}
		window.OneSignalDeferred.push(async (OneSignal) => {
			try {
				await OneSignal.init({
					appId: APP_ID$1,
					allowLocalhostAsSecureOrigin: true,
					serviceWorkerPath: "/OneSignalSDKWorker.js",
					notifyButton: { enable: false }
				});
				attachListener$1(OneSignal);
				resolve(OneSignal);
			} catch (err) {
				reject(err);
			}
		});
	});
	return sdkPromise$1;
}
function attachListener$1(os) {
	if (listenerAttached$1) return;
	listenerAttached$1 = true;
	os.User.PushSubscription.addEventListener("change", (change) => {
		savePushTokenToProfile$1(change.current?.id ?? null).catch((e) => console.warn("[OneSignal] save token", e));
	});
}
async function savePushTokenToProfile$1(token) {
	const { data } = await supabase.auth.getUser();
	const uid = data.user?.id;
	if (!uid) return;
	await supabase.from("profiles").update({ push_token: token }).eq("id", uid);
}
async function initOneSignal$1() {
	if (!isOneSignalConfigured$1()) return null;
	try {
		return await loadSdk$1();
	} catch (e) {
		console.warn("[OneSignal] init failed", e);
		return null;
	}
}
function WelcomeSplash({ profile, onComplete }) {
	const [isFadingOut, setIsFadingOut] = (0, import_react.useState)(false);
	(0, import_react.useEffect)(() => {
		const fadeTimer = setTimeout(() => {
			setIsFadingOut(true);
		}, 2200);
		const completeTimer = setTimeout(() => {
			onComplete();
		}, 2700);
		return () => {
			clearTimeout(fadeTimer);
			clearTimeout(completeTimer);
		};
	}, [onComplete]);
	const handleSkip = () => {
		setIsFadingOut(true);
		setTimeout(() => {
			onComplete();
		}, 400);
	};
	const displayName = profile?.full_name || profile?.username;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		onClick: handleSkip,
		className: cn("fixed inset-0 z-[999999] flex flex-col items-center justify-center bg-background text-foreground select-none transition-all duration-500 ease-out", isFadingOut ? "opacity-0 scale-105 pointer-events-none" : "opacity-100 scale-100"),
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[340px] h-[340px] rounded-full bg-primary/10 blur-[100px] pointer-events-none" }),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "relative mb-8 flex flex-col items-center",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "absolute inset-0 rounded-[28px] bg-primary/15 blur-2xl animate-pulse" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "relative animate-welcome-zoom",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "animate-welcome-float",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
							src: "/favicon.png",
							alt: "tribeX logo",
							className: "h-28 w-28 rounded-[28px] object-contain shadow-xl border border-border/40 bg-card"
						})
					})
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "text-center px-6 z-10 animate-welcome-text flex flex-col items-center",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						className: "text-[11px] font-bold uppercase tracking-[0.25em] text-muted-foreground/80 mb-2",
						children: "welcome to"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h1", {
						className: "text-4xl font-black tracking-tight text-foreground mb-4",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-primary",
							children: "tribe"
						}), "X"]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "h-6 flex items-center justify-center",
						children: displayName ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center gap-1.5 text-sm font-medium text-muted-foreground animate-[fade-in_0.4s_ease-out_both]",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkles, { className: "h-4 w-4 text-primary animate-pulse" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", { children: [
								"Welcome back, ",
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "text-primary font-semibold",
									children: displayName
								}),
								"!"
							] })]
						}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-sm font-medium text-muted-foreground",
							children: "Find your crew, join the plan"
						})
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "absolute bottom-10 left-0 right-0 text-center pointer-events-none animate-pulse",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
					className: "text-[10px] uppercase tracking-widest text-muted-foreground/60 font-semibold",
					children: "Tap anywhere to enter"
				})
			})
		]
	});
}
function NotFoundComponent() {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "flex min-h-screen items-center justify-center bg-background px-4",
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "max-w-md text-center",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
					className: "text-7xl font-bold text-foreground",
					children: "404"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "mt-4 text-xl font-semibold text-foreground",
					children: "Page not found"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-2 text-sm text-muted-foreground",
					children: "The page you're looking for doesn't exist or has been moved."
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "mt-6",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
						to: "/",
						className: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90",
						children: "Go home"
					})
				})
			]
		})
	});
}
function ErrorComponent({ error, reset }) {
	console.error(error);
	const router = useRouter();
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "flex min-h-screen items-center justify-center bg-background px-4",
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "max-w-md text-center",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
					className: "text-xl font-semibold tracking-tight text-foreground",
					children: "This page didn't load"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-2 text-sm text-muted-foreground",
					children: "Something went wrong on our end. You can try refreshing or head back home."
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "mt-6 flex flex-wrap justify-center gap-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						onClick: () => {
							router.invalidate();
							reset();
						},
						className: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90",
						children: "Try again"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
						href: "/",
						className: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium text-foreground transition-colors hover:bg-accent",
						children: "Go home"
					})]
				})
			]
		})
	});
}
var Route$10 = createRootRouteWithContext()({
	head: () => ({
		meta: [
			{ charSet: "utf-8" },
			{
				name: "viewport",
				content: "width=device-width, initial-scale=1"
			},
			{ title: "tribeX — Find your crew, join the plan" },
			{
				name: "description",
				content: "tribeX is a hyper-local activity discovery app. Find box cricket, treks, jams, and pickup games happening near you tonight."
			},
			{
				name: "author",
				content: "tribeX"
			},
			{
				property: "og:title",
				content: "tribeX — Find your crew, join the plan"
			},
			{
				property: "og:description",
				content: "Discover activities happening near you and join a squad in seconds."
			},
			{
				property: "og:type",
				content: "website"
			},
			{
				name: "twitter:card",
				content: "summary_large_image"
			}
		],
		links: [
			{
				rel: "stylesheet",
				href: styles_default
			},
			{
				rel: "icon",
				href: "/favicon.png",
				type: "image/png"
			},
			{
				rel: "icon",
				href: "/favicon.ico"
			},
			{
				rel: "apple-touch-icon",
				href: "/favicon.png"
			},
			{
				rel: "preconnect",
				href: "https://ovknvssfrsuufuopbeqf.supabase.co"
			},
			{
				rel: "dns-prefetch",
				href: "https://ovknvssfrsuufuopbeqf.supabase.co"
			},
			{
				rel: "preconnect",
				href: "https://fonts.googleapis.com"
			},
			{
				rel: "preconnect",
				href: "https://fonts.gstatic.com",
				crossOrigin: "anonymous"
			},
			{
				rel: "stylesheet",
				href: "https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@700;800;900&display=swap"
			}
		]
	}),
	shellComponent: RootShell,
	component: RootComponent,
	notFoundComponent: NotFoundComponent,
	errorComponent: ErrorComponent
});
function RootShell({ children }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("html", {
		lang: "en",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("head", { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(HeadContent, {}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("body", { children: [children, /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Scripts, {})] })]
	});
}
function RootComponent() {
	const { queryClient } = Route$10.useRouteContext();
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(QueryClientProvider, {
		client: queryClient,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AppShell, {})
	});
}
var ONBOARDING_ALLOWED = /* @__PURE__ */ new Set([
	"/onboarding",
	"/auth",
	"/terms-and-policies",
	"/complete-profile"
]);
var PROFILE_ALLOWED = /* @__PURE__ */ new Set([
	"/complete-profile",
	"/auth",
	"/terms-and-policies"
]);
function AppShell() {
	const { user, loading } = useAuth$1();
	const navigate = useNavigate();
	const pathname = useRouterState({ select: (s) => s.location.pathname });
	const [showSplash, setShowSplash] = (0, import_react.useState)(() => {
		if (typeof window !== "undefined") return !window.sessionStorage.getItem("tribex:welcome-shown");
		return true;
	});
	const handleSplashComplete = () => {
		setShowSplash(false);
		if (typeof window !== "undefined") window.sessionStorage.setItem("tribex:welcome-shown", "true");
	};
	const { data: profile } = useQuery({
		queryKey: ["onboarding-status", user?.id],
		queryFn: () => getProfile$1(user.id),
		enabled: !!user,
		staleTime: 6e4
	});
	const needsProfile = !!user && !!profile && !profile.has_completed_profile;
	const needsOnboarding = !!user && !!profile && !needsProfile && !profile.has_completed_onboarding;
	(0, import_react.useEffect)(() => {
		if (loading) return;
		if (needsProfile && !PROFILE_ALLOWED.has(pathname)) {
			navigate({
				to: "/complete-profile",
				replace: true
			});
			return;
		}
		if (needsOnboarding && !ONBOARDING_ALLOWED.has(pathname)) navigate({
			to: "/onboarding",
			replace: true
		});
	}, [
		needsProfile,
		needsOnboarding,
		pathname,
		navigate,
		loading
	]);
	(0, import_react.useEffect)(() => {
		if (!user || needsOnboarding || needsProfile) return;
		initOneSignal$1().catch(() => {});
	}, [
		user,
		needsOnboarding,
		needsProfile
	]);
	(0, import_react.useEffect)(() => {
		if (!user || needsOnboarding || needsProfile || !profile) return;
		if (profile.latitude != null && profile.longitude != null && profile.city) return;
		const key = `tribex:gps-tried:${user.id}`;
		if (typeof window === "undefined" || window.sessionStorage.getItem(key)) return;
		window.sessionStorage.setItem(key, "1");
		saveVerifiedProfileLocation$1(user.id).catch(() => {});
	}, [
		user,
		profile,
		needsOnboarding,
		needsProfile
	]);
	const hideChrome = pathname === "/onboarding" || pathname === "/complete-profile" || pathname === "/auth" || pathname.startsWith("/chat/") || pathname.startsWith("/profile/settings");
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "mx-auto flex min-h-screen w-full max-w-md flex-col bg-background text-foreground",
		children: [
			showSplash && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(WelcomeSplash, {
				profile,
				onComplete: handleSplashComplete
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(GlobalProgressBar, {}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("main", {
				className: hideChrome ? "flex-1" : "flex-1 pb-24",
				children: loading ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PageLoader$1, { label: "Getting things ready" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Outlet, {})
			}),
			!hideChrome && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BottomNav, {}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Toaster$1, { position: "top-center" })
		]
	});
}
async function fetchPublicProfiles(ids) {
	const unique = Array.from(new Set(ids.filter(Boolean)));
	if (unique.length === 0) return /* @__PURE__ */ new Map();
	const map = /* @__PURE__ */ new Map();
	try {
		const { data, error } = await supabase.from("profiles_public").select("id, full_name, username, avatar_url, rating, is_verified, reliability_score").in("id", unique);
		if (error) {
			console.warn("[fetchPublicProfiles] view read failed — falling back to nulls", error);
			return map;
		}
		for (const row of data ?? []) map.set(row.id, row);
	} catch (err) {
		console.warn("[fetchPublicProfiles] threw — falling back to nulls", err);
	}
	return map;
}
async function attachHosts(rows) {
	const hosts = await fetchPublicProfiles(rows.map((a) => a.host_id));
	return rows.map((a) => ({
		...a,
		host: hosts.get(a.host_id) ?? null
	}));
}
var CATEGORY_EMOJI = {
	Cricket: "🏏",
	Football: "⚽",
	Trek: "🥾",
	Music: "🎸",
	Food: "🍜",
	"Board games": "🎲",
	Run: "🏃",
	Cycling: "🚴",
	Sports: "🏅",
	Outdoors: "🌄",
	Social: "🎉"
};
function emojiFor(cat) {
	return CATEGORY_EMOJI[cat] ?? "✨";
}
function cleanPublicProfile(raw) {
	if (!raw) return null;
	const p = Array.isArray(raw) ? raw[0] : raw;
	if (!p || !p.id) return null;
	return {
		id: String(p.id),
		full_name: p.full_name ?? null,
		username: p.username ?? null,
		avatar_url: p.avatar_url ?? null,
		rating: Number(p.rating ?? 5),
		is_verified: Boolean(p.is_verified),
		reliability_score: p.reliability_score != null ? Number(p.reliability_score) : null
	};
}
async function listActivities() {
	try {
		const { data, error } = await supabase.from("activities").select("id, host_id, title, description, category, date_time, location, latitude, longitude, total_slots, slots_left, cost_per_head, image_url, women_only, verified_only, is_urgent, urgent_until, is_online, amenities, topic_tags, created_at, updated_at, deleted_at, host:profiles!activities_host_id_fkey(id, full_name, username, avatar_url, rating, is_verified, reliability_score)").is("deleted_at", null).order("date_time", { ascending: true }).limit(25);
		if (!error && data) return data.map((r) => ({
			...r,
			meeting_link: null,
			host: cleanPublicProfile(r.host)
		}));
	} catch (err) {
		console.warn("[listActivities] join query failed, falling back to flat fetch", err);
	}
	const { data, error } = await supabase.from("activities").select("id, host_id, title, description, category, date_time, location, latitude, longitude, total_slots, slots_left, cost_per_head, image_url, women_only, verified_only, is_urgent, urgent_until, is_online, amenities, topic_tags, created_at, updated_at, deleted_at").is("deleted_at", null).order("date_time", { ascending: true }).limit(60);
	if (error) {
		console.error("[listActivities] fallback fetch failed", error);
		return [];
	}
	return attachHosts(data ?? []);
}
async function fetchNearbyActivities(lat, lng, radiusKm = 15, limit = 50, offset = 0) {
	try {
		const { data, error } = await supabase.rpc("get_nearby_activities", {
			user_lat: lat,
			user_lng: lng,
			radius_km: radiusKm,
			limit_count: limit,
			offset_count: offset
		});
		if (!error && Array.isArray(data) && data.length > 0) return attachHosts(data);
	} catch (err) {
		console.warn("[fetchNearbyActivities] 5-arg RPC failed, trying 3-arg", err);
	}
	try {
		const { data, error } = await supabase.rpc("get_nearby_activities", {
			user_lat: lat,
			user_lng: lng,
			radius_km: radiusKm
		});
		if (!error && Array.isArray(data) && data.length > 0) return attachHosts(data.slice(offset, offset + limit));
	} catch (err) {
		console.warn("[fetchNearbyActivities] 3-arg RPC failed, falling back to listActivities", err);
	}
	return listActivities();
}
async function createActivity(input) {
	const { data: userData } = await supabase.auth.getUser();
	const uid = userData.user?.id;
	if (!uid) throw new Error("You must be signed in to post a plan");
	const { data, error } = await supabase.from("activities").insert({
		...input,
		host_id: uid,
		slots_left: input.total_slots
	}).select().single();
	if (error) throw error;
	return data;
}
async function getMeetingLink(activityId) {
	const { data, error } = await supabase.rpc("get_meeting_link", { _activity_id: activityId });
	if (error) throw error;
	return data ?? null;
}
async function updateActivity(id, patch) {
	const { data: current, error: curErr } = await supabase.from("activities").select("total_slots, slots_left").eq("id", id).single();
	if (curErr) throw curErr;
	const next = { ...patch };
	if (typeof patch.total_slots === "number" && patch.total_slots !== current.total_slots) {
		const accepted = Math.max(0, current.total_slots - current.slots_left);
		if (patch.total_slots < accepted) throw new Error(`Can't shrink below ${accepted} — that many members have already joined. Remove someone first.`);
		next.slots_left = Math.max(0, patch.total_slots - accepted);
	}
	const { data, error } = await supabase.from("activities").update(next).eq("id", id).select().single();
	if (error) throw error;
	return data;
}
async function deleteActivity(id) {
	const { error } = await supabase.from("activities").update({ deleted_at: (/* @__PURE__ */ new Date()).toISOString() }).eq("id", id);
	if (error) throw error;
	return true;
}
async function setActivityUrgent(id, urgent, minutes = 30) {
	const patch = urgent ? {
		is_urgent: true,
		urgent_until: new Date(Date.now() + minutes * 6e4).toISOString()
	} : {
		is_urgent: false,
		urgent_until: null
	};
	const { data, error } = await supabase.from("activities").update(patch).eq("id", id).select().single();
	if (error) throw error;
	return data;
}
function isUrgentActive(a) {
	if (!a.is_urgent || !a.urgent_until) return false;
	return new Date(a.urgent_until).getTime() > Date.now();
}
async function uploadActivityImage(userId, file) {
	const ext = (file.name.split(".").pop() || "jpg").toLowerCase();
	const path = `${userId}/plan-${Date.now()}.${ext}`;
	const { error: upErr } = await supabase.storage.from("activity-images").upload(path, file, {
		cacheControl: "3600",
		upsert: false,
		contentType: file.type
	});
	if (upErr) throw upErr;
	const { data: signed, error: signErr } = await supabase.storage.from("activity-images").createSignedUrl(path, 3600 * 24 * 365);
	if (signErr) throw signErr;
	return signed.signedUrl;
}
async function requestToJoin(activityId) {
	const { data: userData } = await supabase.auth.getUser();
	const uid = userData.user?.id;
	if (!uid) throw new Error("Sign in to request to join");
	const profile = await getProfile(uid);
	if (!profile?.city || profile.latitude == null || profile.longitude == null) throw new Error("Add your GPS profile location before requesting to join.");
	const { data: act } = await supabase.from("activities").select("host_id").eq("id", activityId).maybeSingle();
	if (act?.host_id === uid) throw new Error("You're the host of this plan.");
	if (act?.host_id) {
		if (await isUserBlocked(uid, act.host_id)) throw new Error("You cannot interact with this host.");
	}
	const { data: existing } = await supabase.from("join_requests").select("id, status").eq("activity_id", activityId).eq("user_id", uid).maybeSingle();
	if (existing) {
		if (existing.status === "accepted") throw new Error("You've already joined this plan!");
		throw new Error("You've already requested to join this plan!");
	}
	const { data, error } = await supabase.from("join_requests").insert({
		activity_id: activityId,
		user_id: uid
	}).select().single();
	if (error) {
		const code = error.code;
		console.error("[requestToJoin] supabase error", {
			code,
			error
		});
		if (code === "23505") throw new Error("You've already requested to join this plan!");
		if (code === "42501" || /row-level security/i.test(error.message ?? "")) throw new Error("Add your GPS profile location first, or this plan has safety restrictions you don't meet.");
		throw error;
	}
	return data;
}
async function listMyJoinRequests(userId) {
	const { data, error } = await supabase.from("join_requests").select("*").eq("user_id", userId).limit(25);
	if (error) throw error;
	return data ?? [];
}
async function listPendingRequestsForHost(hostId) {
	const { data: hosted, error: hErr } = await supabase.from("activities").select("id").eq("host_id", hostId).limit(25);
	if (hErr) throw hErr;
	const ids = (hosted ?? []).map((a) => a.id);
	if (ids.length === 0) return [];
	const { data, error } = await supabase.from("join_requests").select("*").in("activity_id", ids).eq("status", "pending").order("created_at", { ascending: false }).limit(25);
	if (error) throw error;
	const rows = data ?? [];
	const users = await fetchPublicProfiles(rows.map((r) => r.user_id));
	return rows.map((r) => ({
		...r,
		user: users.get(r.user_id) ?? null
	}));
}
function hasSafetyShield(a) {
	return !!(a.women_only || a.verified_only);
}
function seededJitter(seed) {
	let h = 0;
	for (let i = 0; i < seed.length; i++) h = h * 31 + seed.charCodeAt(i) | 0;
	const r1 = (h & 65535) / 65535 * 2 - 1;
	const r2 = (h >>> 16 & 65535) / 65535 * 2 - 1;
	return {
		dLat: r1 * .009,
		dLon: r2 * .009
	};
}
function maskActivityForViewer(a, viewerId, acceptedActivityIds) {
	const approved = !!viewerId && (a.host_id === viewerId || acceptedActivityIds.has(a.id));
	if (!hasSafetyShield(a) || approved) return {
		...a,
		is_masked: false
	};
	const { dLat, dLon } = seededJitter(a.id);
	const parts = a.location.split(",").map((s) => s.trim()).filter(Boolean);
	const coarse = parts.length > 1 ? `Near ${parts.slice(-2).join(", ")}` : `Near ${a.location}`;
	return {
		...a,
		location: coarse,
		latitude: a.latitude !== null ? a.latitude + dLat : null,
		longitude: a.longitude !== null ? a.longitude + dLon : null,
		is_masked: true
	};
}
async function listActivityJoinProfiles(activityId) {
	const { data, error } = await supabase.rpc("list_activity_join_profiles", { _activity_id: activityId });
	if (error) throw error;
	return data ?? [];
}
async function respondToJoinRequest(requestId, status) {
	if (status === "accepted") {
		const { data, error } = await supabase.rpc("accept_join_request", { _req_id: requestId });
		if (error) throw error;
		return data;
	}
	const { data, error } = await supabase.from("join_requests").update({ status }).eq("id", requestId).select().single();
	if (error) throw error;
	return data;
}
async function removeJoinRequest(requestId) {
	const { data, error } = await supabase.rpc("remove_join_request", { _req_id: requestId });
	if (error) throw error;
	return data;
}
async function leaveActivity(activityId) {
	const { data: userData } = await supabase.auth.getUser();
	const uid = userData.user?.id;
	if (!uid) throw new Error("Sign in to leave activity");
	const { error } = await supabase.from("join_requests").update({ status: "rejected" }).eq("activity_id", activityId).eq("user_id", uid);
	if (error) throw error;
}
async function listNotifications(userId) {
	const { data, error } = await supabase.from("notifications").select("*").eq("user_id", userId).order("created_at", { ascending: false }).limit(25);
	if (error) throw error;
	return data ?? [];
}
async function markAllNotificationsRead(userId) {
	const { error } = await supabase.from("notifications").update({ is_read: true }).eq("user_id", userId).eq("is_read", false);
	if (error) throw error;
}
async function markNotificationRead(id) {
	const { error } = await supabase.from("notifications").update({ is_read: true }).eq("id", id);
	if (error) throw error;
}
async function getProfile(userId) {
	const { data, error } = await supabase.from("profiles").select("*").eq("id", userId).maybeSingle();
	if (error) throw error;
	return data;
}
async function updateProfile(userId, patch) {
	const { data, error } = await supabase.from("profiles").update(patch).eq("id", userId).select().single();
	if (error) throw error;
	return data;
}
async function isUsernameAvailable(username, excludeId) {
	const clean = username.trim().toLowerCase();
	if (!clean) return false;
	const { data, error } = await supabase.from("profiles").select("id, username").ilike("username", clean).limit(1);
	if (error) throw error;
	const row = (data ?? [])[0];
	if (!row) return true;
	return excludeId ? row.id === excludeId : false;
}
async function uploadAvatar(userId, file) {
	if (!(/* @__PURE__ */ new Set([
		"image/jpeg",
		"image/png",
		"image/webp"
	])).has(file.type)) throw new Error("Please upload a JPG, PNG or WebP image");
	if (file.size > 5 * 1024 * 1024) throw new Error("Image must be under 5MB");
	const ext = (file.name.split(".").pop() || "jpg").toLowerCase();
	const path = `${userId}/avatar-${Date.now()}.${ext}`;
	const { error: upErr } = await supabase.storage.from("avatars").upload(path, file, {
		cacheControl: "3600",
		upsert: true,
		contentType: file.type
	});
	if (upErr) throw upErr;
	const { data: signed, error: signErr } = await supabase.storage.from("avatars").createSignedUrl(path, 3600 * 24 * 365);
	if (signErr) throw signErr;
	await updateProfile(userId, { avatar_url: signed.signedUrl });
	return signed.signedUrl;
}
async function removeAvatar(userId) {
	await updateProfile(userId, { avatar_url: null });
}
async function saveVerifiedProfileLocation(userId) {
	const coords = await getCurrentCoords();
	let city = `Near ${coords.latitude.toFixed(2)}, ${coords.longitude.toFixed(2)}`;
	try {
		const url = `https://nominatim.openstreetmap.org/reverse?format=json&addressdetails=1&lat=${coords.latitude}&lon=${coords.longitude}&accept-language=en`;
		const ctrl = new AbortController();
		const timer = setTimeout(() => ctrl.abort(), 3e3);
		const res = await fetch(url, {
			headers: { Accept: "application/json" },
			signal: ctrl.signal
		}).finally(() => clearTimeout(timer));
		if (res.ok) {
			const data = await res.json();
			const a = data.address ?? {};
			const locality = a.suburb || a.neighbourhood || a.village || a.hamlet || a.town || a.city;
			const cityName = a.city || a.town || a.village || a.county || a.state;
			city = locality && cityName && locality !== cityName ? `${locality}, ${cityName}` : locality || cityName || data.display_name || city;
		}
	} catch {}
	return updateProfile(userId, {
		city,
		latitude: coords.latitude,
		longitude: coords.longitude
	});
}
async function getUserStats(userId) {
	const { hosted, joined } = await getUserActivities(userId);
	return {
		hosted: hosted.length,
		joined: joined.length
	};
}
async function getUserActivities(userId) {
	const { data: userData } = await supabase.auth.getUser();
	const uid = userData.user?.id;
	if (!uid || uid !== userId) throw new Error("Sign in to view your plans");
	let hostedData = [];
	try {
		const { data: hosted, error: e1 } = await supabase.from("activities").select("*, host:profiles!activities_host_id_fkey(id, full_name, username, avatar_url, rating, is_verified, reliability_score)").eq("host_id", userId).is("deleted_at", null).order("date_time", { ascending: false }).limit(25);
		if (!e1 && hosted) hostedData = hosted.map((a) => ({
			...a,
			host: cleanPublicProfile(a.host)
		}));
		else throw e1 || /* @__PURE__ */ new Error("Failed hosted query");
	} catch {
		const { data: plainHosted } = await supabase.from("activities").select("*").eq("host_id", userId).is("deleted_at", null).order("date_time", { ascending: false }).limit(25);
		hostedData = await attachHosts(plainHosted ?? []);
	}
	let joinedResData = [];
	try {
		const { data: joined, error: e2 } = await supabase.from("join_requests").select("status, checked_in_at, activity:activities(*, host:profiles!activities_host_id_fkey(id, full_name, username, avatar_url, rating, is_verified, reliability_score))").eq("user_id", userId).eq("status", "accepted").limit(25);
		if (!e2 && joined) joinedResData = joined.map((r) => {
			const act = r.activity;
			return {
				status: r.status,
				checked_in_at: r.checked_in_at,
				activity: act ? {
					...act,
					host: cleanPublicProfile(act.host)
				} : null
			};
		});
		else throw e2 || /* @__PURE__ */ new Error("Failed joined query");
	} catch {
		try {
			const { data: plainJoined } = await supabase.from("join_requests").select("status, checked_in_at, activity:activities(*)").eq("user_id", userId).eq("status", "accepted").limit(25);
			if (plainJoined) {
				const attached = await attachHosts(plainJoined.map((r) => r.activity).filter(Boolean));
				const actMap = new Map(attached.map((a) => [a.id, a]));
				joinedResData = plainJoined.map((r) => {
					const act = r.activity;
					return {
						status: r.status,
						checked_in_at: r.checked_in_at,
						activity: act ? actMap.get(act.id) ?? null : null
					};
				});
			}
		} catch (err) {
			console.error("[getUserActivities] joined fallback failed", err);
		}
	}
	const archiveCutoff = Date.now() - EVENT_ARCHIVE_MS;
	return {
		hosted: hostedData.filter((a) => new Date(a.date_time).getTime() >= archiveCutoff),
		joined: joinedResData.filter((p) => p.activity && p.activity.deleted_at == null && new Date(p.activity.date_time).getTime() >= archiveCutoff).map((p) => ({
			...p.activity,
			checked_in_at: p.checked_in_at,
			join_status: p.status
		}))
	};
}
async function listUserChats(userId) {
	const { hosted, joined } = await getUserActivities(userId);
	const map = /* @__PURE__ */ new Map();
	[...hosted, ...joined].forEach((a) => map.set(a.id, a));
	return Array.from(map.values()).sort((a, b) => a.date_time < b.date_time ? 1 : -1).slice(0, 25);
}
async function listMessages(activityId) {
	const { data, error } = await supabase.from("messages").select("*").eq("activity_id", activityId).order("created_at", { ascending: false }).limit(50);
	if (error) throw error;
	const rows = (data ?? []).slice().reverse();
	const profilesMap = await fetchPublicProfiles(Array.from(new Set(rows.map((m) => m.sender_id))));
	return rows.map((m) => ({
		...m,
		sender: profilesMap.get(m.sender_id) ?? null
	}));
}
async function sendMessage(activityId, text) {
	const { data: userData } = await supabase.auth.getUser();
	const uid = userData.user?.id;
	if (!uid) throw new Error("Sign in to send messages");
	const { data, error } = await supabase.from("messages").insert({
		activity_id: activityId,
		sender_id: uid,
		text
	}).select().single();
	if (error) throw error;
	return data;
}
/** Members who can be part of a split: host + accepted requesters. */
async function listPlanMembers(activityId) {
	const { data: act, error: aErr } = await supabase.from("activities").select("host_id").eq("id", activityId).maybeSingle();
	if (aErr) throw aErr;
	const { data: reqs, error: rErr } = await supabase.from("join_requests").select("user_id").eq("activity_id", activityId).eq("status", "accepted");
	if (rErr) throw rErr;
	const ids = [act?.host_id, ...(reqs ?? []).map((r) => r.user_id)].filter(Boolean);
	const map = await fetchPublicProfiles(ids);
	const ordered = [];
	const seen = /* @__PURE__ */ new Set();
	for (const id of ids) {
		if (seen.has(id)) continue;
		seen.add(id);
		const p = map.get(id);
		if (p) ordered.push(p);
	}
	return ordered;
}
async function getExpense(expenseId) {
	const { data: e, error } = await supabase.from("expenses").select("*").eq("id", expenseId).maybeSingle();
	if (error) throw error;
	if (!e) return null;
	const { data: shareRows, error: sErr } = await supabase.from("expense_shares").select("*").eq("expense_id", expenseId);
	if (sErr) throw sErr;
	const shares = shareRows ?? [];
	const profileMap = await fetchPublicProfiles(shares.map((s) => s.user_id));
	return {
		...e,
		shares: shares.map((s) => ({
			...s,
			user: profileMap.get(s.user_id) ?? null
		}))
	};
}
async function createExpense(input) {
	const { data: userData } = await supabase.auth.getUser();
	const uid = userData.user?.id;
	if (!uid) throw new Error("Sign in to create an expense");
	if (input.memberIds.length === 0) throw new Error("Select at least one member");
	const totalPaise = Math.round(input.totalAmount * 100);
	if (!(totalPaise > 0)) throw new Error("Amount must be greater than zero");
	const total = totalPaise / 100;
	const amounts = /* @__PURE__ */ new Map();
	if (input.splitType === "equal") {
		const n = input.memberIds.length;
		const basePaise = Math.floor(totalPaise / n);
		let remainderPaise = totalPaise - basePaise * n;
		for (const id of input.memberIds) {
			const extra = remainderPaise > 0 ? 1 : 0;
			if (remainderPaise > 0) remainderPaise -= 1;
			amounts.set(id, (basePaise + extra) / 100);
		}
	} else {
		let sumPaise = 0;
		for (const id of input.memberIds) {
			const paise = Math.round((input.customAmounts?.[id] ?? 0) * 100);
			sumPaise += paise;
			amounts.set(id, paise / 100);
		}
		if (sumPaise !== totalPaise) throw new Error("Custom shares must add up to the total");
	}
	const { data: exp, error: eErr } = await supabase.from("expenses").insert({
		activity_id: input.activityId,
		created_by: uid,
		description: input.description.trim(),
		total_amount: total,
		split_type: input.splitType,
		upi_id: input.upiId?.trim() || null
	}).select().single();
	if (eErr) throw eErr;
	const shareRows = input.memberIds.map((user_id) => ({
		expense_id: exp.id,
		user_id,
		amount: amounts.get(user_id) ?? 0
	}));
	const { error: sErr } = await supabase.from("expense_shares").insert(shareRows);
	if (sErr) throw sErr;
	await supabase.from("messages").insert({
		activity_id: input.activityId,
		sender_id: uid,
		text: `[[expense:${exp.id}]] ${input.description.trim()} · ₹${total.toFixed(2)}`
	});
	return await getExpense(exp.id);
}
async function markShareStatus(shareId, status) {
	const { error } = await supabase.from("expense_shares").update({
		status,
		paid_at: status === "paid" ? (/* @__PURE__ */ new Date()).toISOString() : null
	}).eq("id", shareId);
	if (error) throw error;
}
function getCurrentCoords() {
	return new Promise((resolve, reject) => {
		if (typeof navigator === "undefined" || !navigator.geolocation) {
			reject(/* @__PURE__ */ new Error("Geolocation is not supported on this device"));
			return;
		}
		const opts1 = {
			enableHighAccuracy: false,
			timeout: 12e3,
			maximumAge: 600 * 1e3
		};
		const opts2 = {
			enableHighAccuracy: false,
			timeout: 2e4,
			maximumAge: Infinity
		};
		navigator.geolocation.getCurrentPosition((pos) => resolve(pos.coords), () => {
			navigator.geolocation.getCurrentPosition((pos) => resolve(pos.coords), (err) => {
				const code = err.code;
				if (code === 1) reject(/* @__PURE__ */ new Error("Location permission denied. Enable it in your browser settings."));
				else if (code === 2) reject(/* @__PURE__ */ new Error("Location unavailable. Check that GPS is on and try again."));
				else reject(/* @__PURE__ */ new Error("Getting your location is taking too long. Move near a window or try again."));
			}, opts2);
		}, opts1);
	});
}
async function checkInActivity(activityId) {
	const coords = await getCurrentCoords();
	const { data, error } = await supabase.rpc("check_in_activity", {
		_activity_id: activityId,
		_lat: coords.latitude,
		_lon: coords.longitude
	});
	if (error) throw error;
	const row = (data ?? [])[0];
	if (!row) throw new Error("Check-in did not return a result");
	return row;
}
async function markNoShow(requestId) {
	const { data, error } = await supabase.rpc("mark_no_show", { _req_id: requestId });
	if (error) throw error;
	return data;
}
async function listAttendees(activityId) {
	const { data, error } = await supabase.from("join_requests").select("*").eq("activity_id", activityId).eq("status", "accepted").order("created_at", { ascending: true });
	if (error) throw error;
	const rows = data ?? [];
	const users = await fetchPublicProfiles(rows.map((r) => r.user_id));
	return rows.map((r) => ({
		...r,
		user: users.get(r.user_id) ?? null
	}));
}
var MEMORY_MIME = /* @__PURE__ */ new Set([
	"image/jpeg",
	"image/png",
	"image/webp"
]);
var MEMORY_MAX_BYTES = 5 * 1024 * 1024;
async function uploadEventMemory(userId, activityId, file, caption) {
	if (!MEMORY_MIME.has(file.type)) throw new Error("Please upload a JPG, PNG or WebP image");
	if (file.size > MEMORY_MAX_BYTES) throw new Error("Image is too large (max 5 MB)");
	const ext = (file.name.split(".").pop() || "jpg").toLowerCase();
	const path = `${userId}/memory-${activityId}-${Date.now()}.${ext}`;
	const { error: upErr } = await supabase.storage.from("event-memories").upload(path, file, {
		cacheControl: "3600",
		upsert: false,
		contentType: file.type
	});
	if (upErr) throw upErr;
	const { data: signed, error: signErr } = await supabase.storage.from("event-memories").createSignedUrl(path, 3600 * 24 * 365);
	if (signErr) throw signErr;
	const { data, error } = await supabase.from("event_memories").insert({
		activity_id: activityId,
		user_id: userId,
		image_url: signed.signedUrl,
		caption: caption?.trim() || null
	}).select().single();
	if (error) throw error;
	return data;
}
async function listEventMemories(activityId) {
	const { data, error } = await supabase.from("event_memories").select("*").eq("activity_id", activityId).order("created_at", { ascending: false }).limit(25);
	if (error) throw error;
	return data ?? [];
}
var RATING_BADGES = [
	{
		key: "punctual",
		label: "Punctual",
		emoji: "⏱️"
	},
	{
		key: "friendly",
		label: "Friendly & Respectful",
		emoji: "😊"
	},
	{
		key: "team_player",
		label: "Great Team Player",
		emoji: "🤝"
	},
	{
		key: "reliable",
		label: "Highly Reliable",
		emoji: "⭐"
	}
];
var EVENT_DURATION_MS = 10800 * 1e3;
function isEventEnded(a) {
	return new Date(a.date_time).getTime() + EVENT_DURATION_MS < Date.now();
}
var EVENT_ARCHIVE_MS = 1920 * 60 * 1e3;
async function listMyRatingsForPlan(planId, reviewerId) {
	const { data, error } = await supabase.from("ratings").select("*").eq("plan_id", planId).eq("reviewer_id", reviewerId);
	if (error) throw error;
	return data ?? [];
}
async function upsertRating(input) {
	const { data: userData } = await supabase.auth.getUser();
	const uid = userData.user?.id;
	if (!uid) throw new Error("Sign in to rate");
	if (uid === input.reviewee_id) throw new Error("You can't rate yourself");
	if (!Number.isInteger(input.rating) || input.rating < 1 || input.rating > 5) throw new Error("Pick a star rating between 1 and 5");
	const { data, error } = await supabase.from("ratings").upsert({
		plan_id: input.plan_id,
		reviewer_id: uid,
		reviewee_id: input.reviewee_id,
		rating: input.rating,
		badges: input.badges.slice(0, 8),
		comment: (input.comment ?? "").trim().slice(0, 500) || null
	}, { onConflict: "plan_id,reviewer_id,reviewee_id" }).select().single();
	if (error) throw error;
	return data;
}
async function listRateableParticipants(planId, hostId, viewerId) {
	const attendees = await listAttendees(planId);
	const ids = /* @__PURE__ */ new Set();
	ids.add(hostId);
	attendees.forEach((a) => ids.add(a.user_id));
	ids.delete(viewerId);
	const map = await fetchPublicProfiles(Array.from(ids));
	return Array.from(map.values());
}
async function blockUser(targetId) {
	const { data: userData } = await supabase.auth.getUser();
	const uid = userData.user?.id;
	if (!uid) throw new Error("Sign in to block users");
	if (uid === targetId) throw new Error("You cannot block yourself");
	try {
		const { error } = await supabase.rpc("block_user", { _target_id: targetId });
		if (!error) return;
	} catch {}
	const { error } = await supabase.from("blocks").insert({
		blocker_id: uid,
		blocked_id: targetId
	});
	if (error && error.code !== "23505") throw error;
	try {
		const { data: userActs } = await supabase.from("activities").select("id").eq("host_id", uid);
		const actIds = (userActs ?? []).map((a) => a.id);
		if (actIds.length > 0) await supabase.from("join_requests").update({ status: "rejected" }).in("activity_id", actIds).eq("user_id", targetId).eq("status", "pending");
	} catch {}
}
async function unblockUser(targetId) {
	const { data: userData } = await supabase.auth.getUser();
	const uid = userData.user?.id;
	if (!uid) throw new Error("Sign in to unblock users");
	try {
		const { error } = await supabase.rpc("unblock_user", { _target_id: targetId });
		if (!error) return;
	} catch {}
	const { error } = await supabase.from("blocks").delete().eq("blocker_id", uid).eq("blocked_id", targetId);
	if (error) throw error;
}
async function getBlockedIds(userId) {
	if (!userId) return /* @__PURE__ */ new Set();
	const { data, error } = await supabase.from("blocks").select("blocker_id, blocked_id").or(`blocker_id.eq.${userId},blocked_id.eq.${userId}`);
	if (error) throw error;
	const set = /* @__PURE__ */ new Set();
	for (const r of data ?? []) {
		if (r.blocker_id === userId) set.add(r.blocked_id);
		if (r.blocked_id === userId) set.add(r.blocker_id);
	}
	return set;
}
async function listBlockedUsers(userId) {
	if (!userId) return [];
	try {
		const { data, error } = await supabase.rpc("list_blocked_users");
		if (!error && data) return data;
	} catch {}
	const { data: rows, error } = await supabase.from("blocks").select("blocked_id").eq("blocker_id", userId);
	if (error) throw error;
	const blockedIds = (rows ?? []).map((r) => r.blocked_id);
	if (blockedIds.length === 0) return [];
	const map = await fetchPublicProfiles(blockedIds);
	return Array.from(map.values());
}
async function isUserBlocked(userA, userB) {
	if (!userA || !userB) return false;
	const { data, error } = await supabase.from("blocks").select("id").or(`and(blocker_id.eq.${userA},blocked_id.eq.${userB}),and(blocker_id.eq.${userB},blocked_id.eq.${userA})`).limit(1);
	if (error) return false;
	return (data ?? []).length > 0;
}
async function submitReport(input) {
	const { data: userData } = await supabase.auth.getUser();
	const uid = userData.user?.id;
	if (!uid) throw new Error("Sign in to submit a report");
	try {
		const { error } = await supabase.from("reports").insert({
			reporter_id: uid,
			target_type: input.targetType,
			target_id: input.targetId,
			reason: input.reason,
			notes: input.notes?.trim() || null,
			created_at: (/* @__PURE__ */ new Date()).toISOString(),
			status: "open"
		});
		if (error) {
			console.warn("[submitReport] insert failed", error);
			return false;
		}
		return true;
	} catch (err) {
		console.error("[submitReport] threw", err);
		return false;
	}
}
var CATEGORIES = [
	{
		key: "Cricket",
		label: "Cricket",
		icon: Trophy,
		emoji: "🏏",
		group: "Sports & Outdoor",
		defaultMode: "in_person"
	},
	{
		key: "Football",
		label: "Football",
		icon: Activity,
		emoji: "⚽",
		group: "Sports & Outdoor",
		defaultMode: "in_person"
	},
	{
		key: "Badminton",
		label: "Badminton",
		icon: Dumbbell,
		emoji: "🏸",
		group: "Sports & Outdoor",
		defaultMode: "in_person"
	},
	{
		key: "Running",
		label: "Running",
		icon: Flame,
		emoji: "🏃",
		group: "Sports & Outdoor",
		defaultMode: "in_person"
	},
	{
		key: "Cycling",
		label: "Cycling",
		icon: Bike,
		emoji: "🚴",
		group: "Sports & Outdoor",
		defaultMode: "in_person"
	},
	{
		key: "Trekking",
		label: "Trekking",
		icon: Compass,
		emoji: "🏔️",
		group: "Sports & Outdoor",
		defaultMode: "in_person"
	},
	{
		key: "Hiking",
		label: "Hiking",
		icon: Footprints,
		emoji: "🥾",
		group: "Sports & Outdoor",
		defaultMode: "in_person"
	},
	{
		key: "Road Trips",
		label: "Road Trips",
		icon: Car,
		emoji: "🚗",
		group: "Sports & Outdoor",
		defaultMode: "in_person"
	},
	{
		key: "Study Partner",
		label: "Study Partner",
		icon: BookOpen,
		emoji: "📚",
		group: "Education & Skills",
		defaultMode: "either"
	},
	{
		key: "Coding Partner",
		label: "Coding Partner",
		icon: CodeXml,
		emoji: "💻",
		group: "Education & Skills",
		defaultMode: "either"
	},
	{
		key: "Book Club",
		label: "Book Club",
		icon: Library,
		emoji: "📖",
		group: "Education & Skills",
		defaultMode: "either"
	},
	{
		key: "Reading Session",
		label: "Reading Session",
		icon: BookMarked,
		emoji: "🔖",
		group: "Education & Skills",
		defaultMode: "either"
	},
	{
		key: "Writing Club",
		label: "Writing Club",
		icon: PenTool,
		emoji: "✍️",
		group: "Education & Skills",
		defaultMode: "either"
	},
	{
		key: "Language Exchange",
		label: "Language Exchange",
		icon: Languages,
		emoji: "🗣️",
		group: "Education & Skills",
		defaultMode: "either"
	},
	{
		key: "Public Speaking",
		label: "Public Speaking",
		icon: Mic,
		emoji: "🎤",
		group: "Education & Skills",
		defaultMode: "either"
	},
	{
		key: "Interview Prep",
		label: "Interview Prep",
		icon: Briefcase,
		emoji: "💼",
		group: "Education & Skills",
		defaultMode: "either"
	},
	{
		key: "Startup Networking",
		label: "Startup Networking",
		icon: Rocket,
		emoji: "🚀",
		group: "Tech & Creative",
		defaultMode: "either"
	},
	{
		key: "Coworking Session",
		label: "Coworking",
		icon: Laptop,
		emoji: "💼",
		group: "Tech & Creative",
		defaultMode: "either"
	},
	{
		key: "Content Creation",
		label: "Content Creation",
		icon: Video,
		emoji: "🎥",
		group: "Tech & Creative",
		defaultMode: "either"
	},
	{
		key: "UI/UX Design",
		label: "UI/UX Design",
		icon: Palette,
		emoji: "🎨",
		group: "Tech & Creative",
		defaultMode: "either"
	},
	{
		key: "Video Editing",
		label: "Video Editing",
		icon: Clapperboard,
		emoji: "🎬",
		group: "Tech & Creative",
		defaultMode: "either"
	},
	{
		key: "Chess",
		label: "Chess",
		icon: Crown,
		emoji: "♟️",
		group: "Games & Entertainment",
		defaultMode: "either"
	},
	{
		key: "Board Games",
		label: "Board Games",
		icon: Dices,
		emoji: "🎲",
		group: "Games & Entertainment",
		defaultMode: "in_person"
	},
	{
		key: "Esports & Gaming",
		label: "Esports & Gaming",
		icon: Gamepad2,
		emoji: "🎮",
		group: "Games & Entertainment",
		defaultMode: "either"
	},
	{
		key: "Music Jam",
		label: "Music Jam",
		icon: Music,
		emoji: "🎵",
		group: "Games & Entertainment",
		defaultMode: "either"
	},
	{
		key: "Cooking Session",
		label: "Cooking Session",
		icon: UtensilsCrossed,
		emoji: "🍳",
		group: "Games & Entertainment",
		defaultMode: "in_person"
	},
	{
		key: "Movie Night",
		label: "Movie Night",
		icon: Film,
		emoji: "🎬",
		group: "Games & Entertainment",
		defaultMode: "either"
	},
	{
		key: "Anime Watch Party",
		label: "Anime Watch Party",
		icon: Tv,
		emoji: "📺",
		group: "Games & Entertainment",
		defaultMode: "either"
	},
	{
		key: "Meditation",
		label: "Meditation",
		icon: Sparkles,
		emoji: "🧘",
		group: "Wellness",
		defaultMode: "either"
	},
	{
		key: "Indoor Yoga",
		label: "Indoor Yoga",
		icon: HeartPulse,
		emoji: "🧘‍♀️",
		group: "Wellness",
		defaultMode: "either"
	}
];
var CATEGORY_MAP = Object.fromEntries(CATEGORIES.map((c) => [c.key, c]));
function emojiForCategory(key) {
	return CATEGORY_MAP[key]?.emoji ?? "✨";
}
var CATEGORY_GROUPS = [
	"Sports & Outdoor",
	"Education & Skills",
	"Tech & Creative",
	"Games & Entertainment",
	"Wellness"
];
var AMENITIES = [
	{
		key: "wifi",
		label: "WiFi Available",
		icon: Wifi,
		badge: "📶 WiFi"
	},
	{
		key: "power",
		label: "Power Outlets",
		icon: Plug,
		badge: "🔌 Power"
	},
	{
		key: "quiet",
		label: "Quiet Zone",
		icon: VolumeX,
		badge: "🤫 Silent Focus"
	},
	{
		key: "cafe",
		label: "Cafe / Snacks",
		icon: Coffee,
		badge: "☕ Cafe"
	}
];
var AMENITY_MAP = Object.fromEntries(AMENITIES.map((a) => [a.key, a]));
var inputSchema$1 = objectType({ activityId: stringType().uuid() });
var notifyUrgentSpot = createServerFn({ method: "POST" }).middleware([requireSupabaseAuth]).validator((input) => inputSchema$1.parse(input)).handler(createSsrRpc("1c3f60340e6cffa28db7486b10fb3af65e2895164fcc6f0c6290e737ffe6498b"));
function getInitialSession() {
	if (typeof window === "undefined") return {
		session: null,
		user: null
	};
	try {
		const key = Object.keys(localStorage).find((k) => k.startsWith("sb-") && k.endsWith("-auth-token") || k.includes("auth-token"));
		if (key) {
			const parsed = JSON.parse(localStorage.getItem(key) || "");
			const sess = parsed?.session ?? parsed;
			if (sess?.user && (sess?.access_token || parsed?.access_token)) return {
				session: sess,
				user: sess.user
			};
		}
	} catch {}
	return {
		session: null,
		user: null
	};
}
function useAuth() {
	const [session, setSession] = (0, import_react.useState)(() => getInitialSession().session);
	const [user, setUser] = (0, import_react.useState)(() => getInitialSession().user);
	const [loading, setLoading] = (0, import_react.useState)(false);
	(0, import_react.useEffect)(() => {
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
	return {
		session,
		user,
		loading
	};
}
var DEFAULT_CITY = "Bengaluru";
var KEY = "lobby:location";
var PLACE_KEY = "lobby:place";
var DEFAULT = DEFAULT_CITY;
function useLocation() {
	const [location, setLocationState] = (0, import_react.useState)(DEFAULT);
	const [place, setPlaceState] = (0, import_react.useState)(null);
	const [requesting, setRequesting] = (0, import_react.useState)(false);
	(0, import_react.useEffect)(() => {
		if (typeof window === "undefined") return;
		const saved = window.localStorage.getItem(KEY);
		if (saved) setLocationState(saved);
		const savedPlace = window.localStorage.getItem(PLACE_KEY);
		if (savedPlace) try {
			setPlaceState(JSON.parse(savedPlace));
		} catch {}
	}, []);
	const setLocation = (0, import_react.useCallback)((next) => {
		const value = next.trim() || DEFAULT;
		setLocationState(value);
		try {
			window.localStorage.setItem(KEY, value);
		} catch {}
	}, []);
	const setPlace = (0, import_react.useCallback)((next) => {
		setPlaceState(next);
		const label = next.short || next.city || next.display_name.split(",")[0];
		setLocationState(label);
		try {
			window.localStorage.setItem(KEY, label);
			window.localStorage.setItem(PLACE_KEY, JSON.stringify(next));
		} catch {}
	}, []);
	return {
		location,
		place,
		setLocation,
		setPlace,
		requestBrowserLocation: (0, import_react.useCallback)(async () => {
			if (typeof navigator === "undefined" || !navigator.geolocation) throw new Error("Location isn't available on this device");
			setRequesting(true);
			try {
				const coords = await new Promise((resolve, reject) => {
					navigator.geolocation.getCurrentPosition((p) => resolve(p.coords), (err) => reject(new Error(err.message || "Location permission denied")), {
						enableHighAccuracy: false,
						timeout: 8e3,
						maximumAge: 6e4
					});
				});
				try {
					const url = `https://nominatim.openstreetmap.org/reverse?format=json&addressdetails=1&lat=${coords.latitude}&lon=${coords.longitude}&accept-language=en`;
					const res = await fetch(url, { headers: { Accept: "application/json" } });
					if (res.ok) {
						const data = await res.json();
						const a = data.address ?? {};
						const city = a.city || a.town || a.village || a.hamlet || a.suburb || a.county || a.state || "";
						const short = a.suburb || a.neighbourhood || a.village || a.hamlet || a.town || a.city || city;
						const label = short && city && short !== city ? `${short}, ${city}` : short || city || "Your location";
						setPlace({
							display_name: data.display_name,
							short: label,
							lat: coords.latitude,
							lon: coords.longitude,
							city: (city || "").toString(),
							state: a.state,
							postcode: a.postcode
						});
						return label;
					}
				} catch {}
				const fallback = `Near ${coords.latitude.toFixed(2)}, ${coords.longitude.toFixed(2)}`;
				setLocation(fallback);
				return fallback;
			} finally {
				setRequesting(false);
			}
		}, [setLocation, setPlace]),
		requesting,
		clearLocation: (0, import_react.useCallback)(() => {
			setLocationState(DEFAULT);
			setPlaceState(null);
			try {
				window.localStorage.removeItem(KEY);
				window.localStorage.removeItem(PLACE_KEY);
			} catch {}
		}, [])
	};
}
/**
* Spatial calculation helpers for hyper-local 15 km discovery.
* Matches Flutter LocationService.haversineKm precision and behaviour.
*/
var DEFAULT_LAT = 12.9716;
var DEFAULT_LON = 77.5946;
/**
* Calculates circular great-circle distance between two GPS coordinates in kilometers
* using the Haversine spherical formula.
*/
function haversineKm(lat1, lon1, lat2, lon2) {
	const p = Math.PI / 180;
	const c = Math.cos;
	const a = .5 - c((lat2 - lat1) * p) / 2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
	return 12742 * Math.asin(Math.sqrt(Math.max(0, Math.min(1, a))));
}
function friendlyError(err, fallback = "Something went wrong on our end. Please try again shortly.") {
	const raw = err instanceof Error ? err.message : typeof err === "string" ? err : "";
	const msg = raw.toLowerCase();
	if (!raw) return fallback;
	if (msg.includes("permission denied") || msg.includes("not authorized") || msg.includes("rls") || msg.includes("row-level security") || msg.includes("row level security")) return "You don't have permission to perform this action.";
	if (msg.includes("jwt") || msg.includes("session") && msg.includes("expired")) return "Your session expired. Please sign in again.";
	if (msg.includes("already_requested") || msg.includes("join_requests") && (msg.includes("duplicate") || msg.includes("unique"))) return "You've already requested to join this plan!";
	if (msg.includes("duplicate key") || msg.includes("already exists") || msg.includes("unique constraint")) return "That already exists. Try a different value.";
	if (msg.includes("network") || msg.includes("failed to fetch") || msg.includes("load failed")) return "Network issue. Check your connection and try again.";
	if (msg.includes("invalid login") || msg.includes("invalid credentials")) return "Incorrect email or password.";
	if (msg.includes("email not confirmed")) return "Please verify your email before signing in.";
	if (msg.includes("function ") || msg.includes("relation ") || msg.includes("column ") || msg.startsWith("pgrst") || msg.includes("violates")) return fallback;
	if (raw.length < 140) return raw;
	return fallback;
}
var Popover = Root2;
var PopoverTrigger = Trigger;
var PopoverContent = import_react.forwardRef(({ className, align = "center", sideOffset = 4, ...props }, ref) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Portal, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Content2, {
	ref,
	align,
	sideOffset,
	className: cn("z-50 w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 origin-(--radix-popover-content-transform-origin)", className),
	...props
}) }));
PopoverContent.displayName = Content2.displayName;
function toPlace(r) {
	return {
		display_name: r.full,
		short: r.title,
		lat: r.lat,
		lon: r.lon,
		city: r.city,
		state: r.state,
		postcode: r.postcode
	};
}
function activeProvider() {
	return "".trim(), "photon";
}
function photonToResult(f, idx) {
	const p = f.properties;
	const [lon, lat] = f.geometry.coordinates;
	const locality = p.suburb || p.locality || p.district || p.village || p.hamlet || p.town || "";
	const city = p.city || p.town || p.village || p.hamlet || p.county || p.state || "";
	const title = p.name || p.street || locality || city || "Unnamed place";
	const subtitleParts = [
		locality && locality !== title ? locality : "",
		city && city !== locality ? city : "",
		p.state && p.state !== city ? p.state : ""
	].filter(Boolean);
	const subtitle = subtitleParts.join(", ") || p.country || "";
	const full = [
		title,
		...subtitleParts,
		p.country
	].filter(Boolean).join(", ");
	return {
		id: `${p.osm_type || "n"}-${p.osm_id ?? idx}-${lat}-${lon}`,
		title,
		subtitle,
		full,
		lat,
		lon,
		city,
		state: p.state,
		postcode: p.postcode,
		kind: p.osm_value || p.type
	};
}
async function searchPhoton(q, signal) {
	const url = `https://photon.komoot.io/api/?${new URLSearchParams({
		q,
		lang: "en",
		limit: "12",
		lat: "22.35",
		lon: "78.66",
		location_bias_scale: "0.4"
	}).toString()}`;
	const res = await fetch(url, {
		signal,
		headers: { Accept: "application/json" }
	});
	if (!res.ok) throw new Error("Photon search failed");
	const data = await res.json();
	const inIndia = data.features.filter((f) => (f.properties.countrycode || "").toUpperCase() === "IN");
	const rest = data.features.filter((f) => (f.properties.countrycode || "").toUpperCase() !== "IN");
	return [...inIndia, ...rest].map(photonToResult);
}
async function searchPincode(pin, signal) {
	const params = new URLSearchParams({
		format: "json",
		addressdetails: "1",
		countrycodes: "in",
		limit: "8",
		"accept-language": "en",
		postalcode: pin
	});
	const res = await fetch(`https://nominatim.openstreetmap.org/search?${params.toString()}`, {
		signal,
		headers: { Accept: "application/json" }
	});
	if (!res.ok) return [];
	return (await res.json()).map((r, i) => {
		const a = r.address ?? {};
		const locality = a.suburb || a.village || a.hamlet || a.town || "";
		const city = a.city || a.town || a.village || a.hamlet || a.county || a.state || "";
		const title = locality || city || pin;
		const subtitleParts = [
			locality && locality !== title ? locality : "",
			city && city !== locality ? city : "",
			a.state,
			pin
		].filter(Boolean);
		return {
			id: `pin-${pin}-${i}`,
			title: `${title} (${pin})`,
			subtitle: subtitleParts.join(", "),
			full: r.display_name,
			lat: parseFloat(r.lat),
			lon: parseFloat(r.lon),
			city,
			state: a.state,
			postcode: pin,
			kind: "postcode"
		};
	});
}
async function searchPlaces(q, signal) {
	const term = q.trim();
	if (term.length < 2) return [];
	const sig = signal ?? new AbortController().signal;
	if (/^\d{6}$/.test(term)) {
		const [pins, photon] = await Promise.all([searchPincode(term, sig).catch(() => []), searchPhoton(term, sig).catch(() => [])]);
		return [...pins, ...photon];
	}
	return searchPhoton(term, sig);
}
function PlaceSearch({ value, onSelect, className, variant = "chip", placeholder = "Search place or pincode" }) {
	const [open, setOpen] = (0, import_react.useState)(false);
	const [q, setQ] = (0, import_react.useState)("");
	const [results, setResults] = (0, import_react.useState)([]);
	const [loading, setLoading] = (0, import_react.useState)(false);
	const [error, setError] = (0, import_react.useState)(null);
	const inputRef = (0, import_react.useRef)(null);
	const provider = (0, import_react.useMemo)(() => activeProvider(), []);
	(0, import_react.useEffect)(() => {
		const term = q.trim();
		if (!open) return;
		if (term.length < 2) {
			setResults([]);
			setError(null);
			return;
		}
		const ctrl = new AbortController();
		setLoading(true);
		setError(null);
		const t = setTimeout(async () => {
			try {
				const data = await searchPlaces(term, ctrl.signal);
				setResults(data);
			} catch (e) {
				if (e.name !== "AbortError") setError("Couldn't reach the place search service");
			} finally {
				setLoading(false);
			}
		}, 300);
		return () => {
			clearTimeout(t);
			ctrl.abort();
		};
	}, [q, open]);
	(0, import_react.useEffect)(() => {
		if (open) setTimeout(() => inputRef.current?.focus(), 30);
		else {
			setQ("");
			setResults([]);
		}
	}, [open]);
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Popover, {
		open,
		onOpenChange: setOpen,
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(PopoverTrigger, {
			asChild: true,
			children: variant === "chip" ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
				type: "button",
				className: cn("inline-flex max-w-[220px] items-center gap-1 text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground transition hover:text-primary", className),
				"aria-label": "Change location",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, { className: "h-3 w-3 shrink-0" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						className: "truncate normal-case tracking-normal",
						children: value || placeholder
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronsUpDown, { className: "h-3 w-3 shrink-0 opacity-60" })
				]
			}) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
				type: "button",
				className: cn("flex w-full items-center justify-between gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3 text-left text-sm transition focus:border-primary", !value && "text-muted-foreground", className),
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
					className: "flex items-center gap-2 truncate",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, { className: "h-4 w-4 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						className: "truncate",
						children: value || placeholder
					})]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronsUpDown, { className: "h-4 w-4 shrink-0 text-muted-foreground" })]
			})
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(PopoverContent, {
			align: "start",
			className: "w-[320px] p-0",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center gap-2 border-b border-border/60 px-3 py-2",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Search, { className: "h-3.5 w-3.5 shrink-0 text-muted-foreground" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
						ref: inputRef,
						value: q,
						onChange: (e) => setQ(e.target.value),
						placeholder: "Try Madhapar, Bhuj or 370020",
						className: "h-8 w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
					}),
					q && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						onClick: () => setQ(""),
						"aria-label": "Clear",
						className: "text-muted-foreground hover:text-foreground",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-3.5 w-3.5" })
					})
				]
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "max-h-72 overflow-y-auto",
				children: [
					loading && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center gap-2 px-3 py-4 text-xs text-muted-foreground",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-3.5 w-3.5 animate-spin" }), " Searching India…"]
					}),
					!loading && error && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "px-3 py-4 text-xs text-destructive",
						children: error
					}),
					!loading && !error && q.trim().length >= 2 && results.length === 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "px-3 py-4 text-xs text-muted-foreground",
						children: "No matching places."
					}),
					!loading && q.trim().length < 2 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "px-3 py-4 text-xs text-muted-foreground",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "Type a temple, park, landmark, village, or 6-digit pincode." }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
							className: "mt-1 text-[10px] uppercase tracking-wider opacity-60",
							children: ["Powered by ", provider === "google" ? "Google Places" : "Photon · OpenStreetMap"]
						})]
					}),
					!loading && results.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
						className: "py-1",
						children: results.map((r) => {
							const p = toPlace(r);
							return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
								type: "button",
								onClick: () => {
									onSelect(p);
									setOpen(false);
								},
								className: "flex w-full items-start gap-2 px-3 py-2 text-left text-sm transition hover:bg-accent",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, { className: "mt-0.5 h-3.5 w-3.5 shrink-0 text-primary" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
									className: "min-w-0 flex-1",
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
											className: "flex items-center gap-1.5",
											children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
												className: "truncate font-medium",
												children: r.title
											}), r.kind && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
												className: "shrink-0 rounded-full bg-primary/10 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wider text-primary",
												children: r.kind
											})]
										}),
										r.subtitle && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
											className: "block truncate text-[11px] text-muted-foreground",
											children: r.subtitle
										}),
										/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
											className: "mt-0.5 block truncate text-[10px] text-muted-foreground/70",
											children: [
												p.lat.toFixed(4),
												", ",
												p.lon.toFixed(4)
											]
										})
									]
								})]
							}) }, r.id);
						})
					})
				]
			})]
		})]
	});
}
function SafetyDisclaimerModal({ open, onCancel, onAgree }) {
	const [secondsLeft, setSecondsLeft] = (0, import_react.useState)(6);
	(0, import_react.useEffect)(() => {
		if (!open) return;
		setSecondsLeft(6);
		const timer = setInterval(() => {
			setSecondsLeft((s) => s <= 1 ? 0 : s - 1);
		}, 1e3);
		return () => clearInterval(timer);
	}, [open]);
	if (!open) return null;
	const ready = secondsLeft === 0;
	if (typeof document === "undefined") return null;
	return (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "fixed inset-0 z-[99998] bg-black/80 backdrop-blur-md",
		onClick: onCancel
	}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		role: "alertdialog",
		"aria-modal": "true",
		"aria-labelledby": "safety-title",
		className: "fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-[99999] w-[92vw] max-w-sm rounded-2xl p-6 bg-card border shadow-2xl max-h-[85vh] overflow-y-auto",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-destructive/15 text-destructive",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShieldAlert, { className: "h-6 w-6" })
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
				id: "safety-title",
				className: "text-lg font-bold",
				children: "Safety Warning"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
				className: "mt-2 text-sm leading-relaxed text-muted-foreground",
				children: [
					"You are joining this activity at your own personal risk. By proceeding, you confirm that you are",
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						className: "font-semibold text-foreground",
						children: " 18+ years old"
					}),
					" and assume full personal responsibility for your safety and conduct."
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "mt-4 rounded-2xl border border-border/60 bg-secondary/60 p-3 text-xs text-muted-foreground",
				children: "Please read the warning carefully. The button will unlock in a few seconds."
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mt-5 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					type: "button",
					onClick: onCancel,
					className: "rounded-full border border-border/60 px-4 py-2 text-sm font-semibold transition hover:bg-accent active:scale-95",
					children: "Cancel"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					type: "button",
					onClick: onAgree,
					disabled: !ready,
					className: "rounded-full bg-destructive px-5 py-2 text-sm font-semibold text-destructive-foreground transition hover:scale-[1.02] active:scale-95 disabled:cursor-not-allowed disabled:opacity-60 disabled:hover:scale-100",
					children: ready ? "I Understand & Proceed" : `Proceeding in ${secondsLeft}s…`
				})]
			})
		]
	})] }), document.body);
}
function timeAgo(iso) {
	const s = Math.floor((Date.now() - new Date(iso).getTime()) / 1e3);
	if (s < 60) return `${s}s`;
	const m = Math.floor(s / 60);
	if (m < 60) return `${m}m`;
	const h = Math.floor(m / 60);
	if (h < 24) return `${h}h`;
	return `${Math.floor(h / 24)}d`;
}
function NotificationsBell({ userId, onOpenActivity, onOpenChat }) {
	const qc = useQueryClient();
	const [open, setOpen] = (0, import_react.useState)(false);
	const wrapRef = (0, import_react.useRef)(null);
	const { data: notifications = [] } = useQuery({
		queryKey: ["notifications", userId],
		queryFn: () => listNotifications(userId)
	});
	const unread = notifications.filter((n) => !n.is_read).length;
	(0, import_react.useEffect)(() => {
		if (!open) return;
		function onDown(e) {
			const el = wrapRef.current;
			if (el && !el.contains(e.target)) setOpen(false);
		}
		function onKey(e) {
			if (e.key === "Escape") setOpen(false);
		}
		document.addEventListener("mousedown", onDown);
		document.addEventListener("touchstart", onDown, { passive: true });
		document.addEventListener("keydown", onKey);
		return () => {
			document.removeEventListener("mousedown", onDown);
			document.removeEventListener("touchstart", onDown);
			document.removeEventListener("keydown", onKey);
		};
	}, [open]);
	(0, import_react.useEffect)(() => {
		const channel = supabase.channel(`notifications:${userId}`).on("postgres_changes", {
			event: "INSERT",
			schema: "public",
			table: "notifications",
			filter: `user_id=eq.${userId}`
		}, (payload) => {
			const n = payload.new;
			qc.setQueryData(["notifications", userId], (prev) => [n, ...prev ?? []]);
			qc.invalidateQueries({ queryKey: ["pending-requests-host", userId] });
			qc.invalidateQueries({ queryKey: ["my-join-requests", userId] });
			const aid = n.activity_id;
			let action;
			if (aid) {
				if (n.type === "join_request" && onOpenActivity) action = {
					label: "View",
					onClick: () => onOpenActivity(aid)
				};
				else if ((n.type === "request_accepted" || n.type === "event_match") && onOpenChat) action = {
					label: n.type === "request_accepted" ? "Open chat" : "View plan",
					onClick: () => onOpenChat(aid)
				};
			}
			toast(n.title, {
				description: n.body ?? void 0,
				action
			});
		}).subscribe();
		return () => {
			supabase.removeChannel(channel);
		};
	}, [
		userId,
		qc,
		onOpenActivity,
		onOpenChat
	]);
	async function handleMarkAll() {
		await markAllNotificationsRead(userId);
		qc.setQueryData(["notifications", userId], (prev) => (prev ?? []).map((n) => ({
			...n,
			is_read: true
		})));
	}
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "relative",
		ref: wrapRef,
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
			onClick: () => setOpen((v) => !v),
			className: "relative flex h-11 w-11 shrink-0 items-center justify-center rounded-full border border-border/60 bg-card transition hover:border-primary/60 active:scale-95",
			"aria-label": "Notifications",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Bell, { className: "h-5 w-5" }), unread > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
				className: "absolute -right-0.5 -top-0.5 flex h-5 min-w-5 items-center justify-center rounded-full bg-primary px-1 text-[10px] font-bold text-primary-foreground ring-2 ring-background",
				children: unread > 9 ? "9+" : unread
			})]
		}), open && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "fixed inset-0 z-40",
			onClick: () => setOpen(false)
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "fixed left-2 right-2 top-16 z-50 mx-auto overflow-hidden rounded-2xl border border-border/60 bg-card shadow-xl sm:absolute sm:left-auto sm:right-0 sm:top-14 sm:mx-0 sm:w-[340px]",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between border-b border-border/60 px-4 py-2.5",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "text-sm font-semibold",
					children: "Notifications"
				}), unread > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					onClick: handleMarkAll,
					className: "flex items-center gap-1 text-xs font-medium text-primary transition hover:underline",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "h-3 w-3" }), " Mark all read"]
				})]
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
				className: "max-h-[80vh] overflow-y-auto",
				children: notifications.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", {
					className: "px-4 py-8 text-center text-xs text-muted-foreground",
					children: "You're all caught up."
				}) : notifications.map((n) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", {
					className: `border-b border-border/40 px-4 py-3 last:border-0 ${!n.is_read ? "bg-primary/5" : ""}`,
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
						className: "block w-full text-left",
						onClick: () => {
							if (!n.is_read) markNotificationRead(n.id).then(() => {
								qc.setQueryData(["notifications", userId], (prev) => (prev ?? []).map((x) => x.id === n.id ? {
									...x,
									is_read: true
								} : x));
							});
							if (n.activity_id) if (n.type === "join_request" && onOpenActivity) {
								onOpenActivity(n.activity_id);
								setOpen(false);
							} else if ((n.type === "request_accepted" || n.type === "event_match") && onOpenChat) {
								onOpenChat(n.activity_id);
								setOpen(false);
							} else setOpen(false);
						},
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center justify-between gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-xs font-semibold",
								children: n.title
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "shrink-0 text-[10px] text-muted-foreground",
								children: timeAgo(n.created_at)
							})]
						}), n.body && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "mt-0.5 text-xs text-muted-foreground",
							children: n.body
						})]
					})
				}, n.id))
			})]
		})] })]
	});
}
var SPORTS = /* @__PURE__ */ new Set([
	"Cricket",
	"Football",
	"Run",
	"Cycling",
	"Sports",
	"Box Cricket"
]);
var TRAVEL = /* @__PURE__ */ new Set([
	"Trek",
	"Outdoors",
	"Travel",
	"Music",
	"Food",
	"Social"
]);
var WORK = /* @__PURE__ */ new Set([
	"Education",
	"Work",
	"Study",
	"Coworking",
	"Learning"
]);
function getReliabilityTitle(user, activities) {
	const hosted = Array.isArray(activities) ? [] : activities?.hosted ?? [];
	const joined = Array.isArray(activities) ? activities : activities?.joined ?? [];
	const all = [...hosted, ...joined];
	if (hosted.length > 0 && hosted.length / Math.max(all.length, 1) > .5) return "100% Reliable Host";
	const tally = {
		sports: 0,
		travel: 0,
		work: 0
	};
	for (const a of all) {
		const c = a?.category ?? "";
		if (SPORTS.has(c)) tally.sports += 1;
		else if (TRAVEL.has(c)) tally.travel += 1;
		else if (WORK.has(c)) tally.work += 1;
	}
	const top = Object.entries(tally).sort((a, b) => b[1] - a[1])[0];
	if (top && top[1] > 0) {
		if (top[0] === "sports") return "100% Reliable Player";
		if (top[0] === "travel") return "100% Reliable Explorer";
		if (top[0] === "work") return "100% Reliable Partner";
	}
	return "100% Reliable Squadmate";
}
function formatReliabilityLabel(score, title) {
	return title.replace(/^100%/, `${Math.round(score)}%`);
}
function ManageRequestsModal({ activityId, activityTitle, open, onClose }) {
	const qc = useQueryClient();
	const { data: people = [], isLoading } = useQuery({
		queryKey: ["activity-join-profiles", activityId],
		queryFn: () => listActivityJoinProfiles(activityId),
		enabled: open && !!activityId
	});
	const respond = useMutation({
		mutationFn: ({ id, status }) => respondToJoinRequest(id, status),
		onSuccess: (_d, vars) => {
			toast.success(vars.status === "accepted" ? "Request accepted" : "Request declined");
			invalidateHostPlan(qc, activityId);
		},
		onError: (e) => toast.error(friendlyError(e))
	});
	const remove = useMutation({
		mutationFn: (id) => removeJoinRequest(id),
		onSuccess: () => {
			toast.success("User removed from plan");
			invalidateHostPlan(qc, activityId);
		},
		onError: (e) => toast.error(friendlyError(e, "Couldn't remove this user"))
	});
	const [personToRemove, setPersonToRemove] = (0, import_react.useState)(null);
	if (!open || !activityId) return null;
	if (typeof document === "undefined") return null;
	const pendingCount = people.filter((p) => p.status === "pending").length;
	const acceptedCount = people.filter((p) => p.status === "accepted").length;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [(0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
		onClick: onClose,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			onClick: (e) => e.stopPropagation(),
			className: "fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[92vw] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-5 shadow-2xl",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-start justify-between gap-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
						className: "text-base font-semibold tracking-tight",
						children: "Manage joiners"
					}),
					activityTitle && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "mt-0.5 text-xs text-muted-foreground",
						children: activityTitle
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
						className: "mt-1 text-[11px] text-muted-foreground",
						children: [
							pendingCount,
							" pending · ",
							acceptedCount,
							" joined"
						]
					})
				] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					onClick: onClose,
					className: "flex h-8 w-8 items-center justify-center rounded-full border border-border/60 transition hover:bg-accent",
					"aria-label": "Close",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4" })
				})]
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "mt-4 max-h-[64vh] overflow-y-auto",
				children: isLoading ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "flex flex-col gap-2",
					children: [
						0,
						1,
						2
					].map((i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-28 animate-pulse rounded-2xl bg-secondary" }, i))
				}) : people.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "py-8 text-center text-sm text-muted-foreground",
					children: "No join requests or attendees yet."
				}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
					className: "flex flex-col gap-2",
					children: people.map((person) => {
						return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AttendeeRow, {
							person,
							busy: respond.isPending && respond.variables?.id === person.join_request_id || remove.isPending && remove.variables === person.join_request_id,
							onAccept: () => respond.mutate({
								id: person.join_request_id,
								status: "accepted"
							}),
							onDecline: () => respond.mutate({
								id: person.join_request_id,
								status: "rejected"
							}),
							onRemove: () => setPersonToRemove(person)
						}, person.join_request_id);
					})
				})
			})]
		})
	}), document.body), personToRemove && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "fixed inset-0 z-[999999] bg-black/80 p-4 backdrop-blur-sm",
		onClick: () => !remove.isPending && setPersonToRemove(null),
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			onClick: (e) => e.stopPropagation(),
			className: "fixed left-1/2 top-1/2 z-[1000000] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col items-center gap-3 text-center",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "flex h-12 w-12 items-center justify-center rounded-full bg-destructive/15 text-destructive",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShieldAlert, { className: "h-6 w-6" })
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h3", {
						className: "text-lg font-bold text-foreground",
						children: [
							"Remove ",
							personToRemove.full_name || personToRemove.username || "attendee",
							"?"
						]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-sm text-muted-foreground leading-relaxed",
						children: "They will be removed from this plan and will lose access to the group chat."
					})
				]
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mt-6 flex flex-col gap-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					disabled: remove.isPending,
					onClick: () => {
						remove.mutate(personToRemove.join_request_id, { onSettled: () => setPersonToRemove(null) });
					},
					className: "w-full rounded-full bg-destructive py-2.5 text-sm font-semibold text-destructive-foreground transition hover:opacity-90 active:scale-95 disabled:opacity-50",
					children: remove.isPending ? "Removing…" : "Yes, Remove"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					disabled: remove.isPending,
					onClick: () => setPersonToRemove(null),
					className: "w-full rounded-full border border-border/60 py-2.5 text-sm font-semibold transition hover:bg-accent",
					children: "Cancel"
				})]
			})]
		})
	}), document.body)] });
}
function AttendeeRow({ person, busy, onAccept, onDecline, onRemove }) {
	const name = person.full_name || person.username || "Squad mate";
	const label = formatReliabilityLabel(Math.round(Number(person.reliability_score ?? 100)), getReliabilityTitle({ id: person.user_id }, null));
	const mapsHref = person.latitude != null && person.longitude != null ? `https://www.google.com/maps/search/?api=1&query=${person.latitude},${person.longitude}` : null;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
		className: "rounded-2xl border border-border/60 bg-background/60 p-3",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "flex items-start gap-3",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "h-11 w-11 shrink-0 overflow-hidden rounded-full bg-primary/15 text-primary",
					children: person.avatar_url ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
						src: person.avatar_url,
						alt: "",
						className: "h-full w-full object-cover"
					}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						className: "flex h-full w-full items-center justify-center text-sm font-semibold",
						children: name[0]?.toUpperCase()
					})
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "min-w-0 flex-1",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex min-w-0 items-center gap-1.5",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "truncate text-sm font-semibold",
								children: name
							}), person.is_verified && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BadgeCheck, { className: "h-3.5 w-3.5 shrink-0 text-primary" })]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mt-1 flex flex-wrap gap-1.5",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "inline-flex items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-semibold text-primary",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-3 w-3 fill-current" }),
									" ",
									Number(person.rating ?? 5).toFixed(1),
									" · ",
									person.total_reviews,
									" reviews"
								]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "rounded-full bg-green-500/15 px-2 py-0.5 text-[10px] font-semibold text-green-600 dark:text-green-400",
								children: ["⭐ ", label]
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
							className: "mt-1 flex items-center gap-1 text-[11px] text-muted-foreground",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, { className: "h-3 w-3 shrink-0" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "truncate",
								children: person.city || "GPS profile location missing"
							})]
						})
					]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
					className: `shrink-0 rounded-full px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider ${person.status === "accepted" ? "bg-green-500/15 text-green-600 dark:text-green-400" : "bg-amber-500/15 text-amber-600 dark:text-amber-400"}`,
					children: person.status === "accepted" ? "Joined" : "Pending"
				})
			]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "mt-3 flex items-center justify-end gap-1.5",
			children: [mapsHref && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
				href: mapsHref,
				target: "_blank",
				rel: "noopener noreferrer",
				className: "flex h-9 w-9 items-center justify-center rounded-full border border-border/60 text-muted-foreground transition hover:border-primary/60 hover:text-primary",
				"aria-label": "Open profile location",
				title: "Open profile location",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Navigation, { className: "h-4 w-4" })
			}), person.status === "pending" ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
				onClick: onDecline,
				disabled: busy,
				className: "flex h-9 w-9 items-center justify-center rounded-full border border-border/60 text-muted-foreground transition hover:border-destructive/60 hover:text-destructive disabled:opacity-50",
				"aria-label": "Decline",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(UserX, { className: "h-4 w-4" })
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
				onClick: onAccept,
				disabled: busy,
				className: "flex h-9 items-center gap-1 rounded-full bg-primary px-3 text-xs font-semibold text-primary-foreground transition hover:scale-105 active:scale-95 disabled:opacity-50",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "h-3.5 w-3.5" }), " Accept"]
			})] }) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
				onClick: onRemove,
				disabled: busy,
				className: "flex h-9 items-center gap-1 rounded-full border border-destructive/40 px-3 text-xs font-semibold text-destructive transition hover:bg-destructive/10 active:scale-95 disabled:opacity-50",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trash2, { className: "h-3.5 w-3.5" }), " Remove"]
			})]
		})]
	});
}
function invalidateHostPlan(qc, activityId) {
	qc.invalidateQueries({ queryKey: ["activity-join-profiles", activityId] });
	qc.invalidateQueries({ queryKey: ["pending-requests", activityId] });
	qc.invalidateQueries({ queryKey: ["pending-requests-host"] });
	qc.invalidateQueries({ queryKey: ["attendees", activityId] });
	qc.invalidateQueries({ queryKey: ["activities"] });
	qc.invalidateQueries({ queryKey: ["user-activities"] });
}
var schema$1 = objectType({
	title: stringType().trim().min(4).max(80),
	description: stringType().trim().min(10).max(500),
	category: stringType().min(1),
	date: stringType().min(1),
	time: stringType().min(1),
	location: stringType().trim().max(120).optional().default(""),
	is_online: booleanType(),
	meeting_link: stringType().trim().max(500).optional().default(""),
	slots: numberType().int().gt(0).max(50),
	cost: numberType().min(0).max(1e5),
	topic_tags: stringType().trim().max(120).optional().default("")
}).superRefine((val, ctx) => {
	if (val.is_online) {
		if (!/^https?:\/\/\S+$/i.test(val.meeting_link ?? "")) ctx.addIssue({
			code: ZodIssueCode.custom,
			path: ["meeting_link"],
			message: "Add a valid meeting URL"
		});
	} else if ((val.location ?? "").trim().length < 3) ctx.addIssue({
		code: ZodIssueCode.custom,
		path: ["location"],
		message: "Add a venue or area"
	});
});
function toLocalDateTime(iso) {
	const d = new Date(iso);
	const pad = (n) => String(n).padStart(2, "0");
	return {
		date: `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`,
		time: `${pad(d.getHours())}:${pad(d.getMinutes())}`
	};
}
function EditPlanModal({ activity, open, onClose }) {
	const { user } = useAuth();
	const qc = useQueryClient();
	const fileRef = (0, import_react.useRef)(null);
	const [form, setForm] = (0, import_react.useState)({
		title: "",
		description: "",
		category: "",
		date: "",
		time: "",
		location: "",
		slots: "8",
		cost: "0",
		is_online: false,
		meeting_link: "",
		topic_tags: ""
	});
	const [amenities, setAmenities] = (0, import_react.useState)([]);
	const [groupFilter, setGroupFilter] = (0, import_react.useState)("Sports & Outdoor");
	const [existingImage, setExistingImage] = (0, import_react.useState)(null);
	const [imageFile, setImageFile] = (0, import_react.useState)(null);
	const [imagePreview, setImagePreview] = (0, import_react.useState)(null);
	const [imageCleared, setImageCleared] = (0, import_react.useState)(false);
	const [uploading, setUploading] = (0, import_react.useState)(false);
	(0, import_react.useEffect)(() => {
		if (!activity) return;
		let cancelled = false;
		const { date, time } = toLocalDateTime(activity.date_time);
		setForm({
			title: activity.title,
			description: activity.description,
			category: activity.category,
			date,
			time,
			location: activity.location,
			slots: String(activity.total_slots),
			cost: String(activity.cost_per_head),
			is_online: !!activity.is_online,
			meeting_link: activity.meeting_link ?? "",
			topic_tags: (activity.topic_tags ?? []).join(", ")
		});
		setAmenities(activity.amenities ?? []);
		const g = CATEGORIES.find((c) => c.key === activity.category)?.group;
		if (g) setGroupFilter(g);
		setExistingImage(activity.image_url ?? null);
		setImageFile(null);
		setImagePreview(null);
		setImageCleared(false);
		if (activity.is_online && !activity.meeting_link) getMeetingLink(activity.id).then((meetingLink) => {
			if (!cancelled && meetingLink) setForm((current) => ({
				...current,
				meeting_link: meetingLink
			}));
		}).catch((error) => {
			if (!cancelled) console.error("[edit-plan] meeting link fetch failed", error);
		});
		return () => {
			cancelled = true;
		};
	}, [activity]);
	const mutation = useMutation({
		mutationFn: async () => {
			if (!activity) throw new Error("No plan selected");
			const parsed = schema$1.safeParse({
				...form,
				slots: Number(form.slots),
				cost: Number(form.cost)
			});
			if (!parsed.success) throw new Error(parsed.error.issues[0]?.message ?? "Invalid input");
			const p = parsed.data;
			const cleanTags = p.topic_tags ? p.topic_tags.split(",").map((t) => t.trim()).filter(Boolean).slice(0, 8) : [];
			let image_url = void 0;
			if (imageCleared && !imageFile) image_url = null;
			if (imageFile && user) {
				setUploading(true);
				try {
					image_url = await uploadActivityImage(user.id, imageFile);
				} finally {
					setUploading(false);
				}
			}
			return updateActivity(activity.id, {
				title: p.title,
				description: p.description,
				category: p.category,
				date_time: (/* @__PURE__ */ new Date(`${p.date}T${p.time}`)).toISOString(),
				location: p.is_online ? p.location.trim() || "Online" : p.location,
				total_slots: p.slots,
				cost_per_head: p.cost,
				is_online: p.is_online,
				meeting_link: p.is_online ? p.meeting_link.trim() : null,
				amenities: p.is_online ? [] : amenities,
				topic_tags: cleanTags,
				...image_url !== void 0 ? { image_url } : {}
			});
		},
		onSuccess: async () => {
			await Promise.all([
				qc.invalidateQueries({ queryKey: ["activities"] }),
				qc.invalidateQueries({ queryKey: ["user-activities", user?.id] }),
				qc.invalidateQueries({ queryKey: ["user-stats", user?.id] }),
				qc.invalidateQueries({ queryKey: ["chats", user?.id] }),
				qc.invalidateQueries({ queryKey: ["profile", user?.id] })
			]);
			toast.success("Plan updated");
			onClose();
		},
		onError: (e) => {
			console.error("[edit-plan] update failed", e);
			toast.error(friendlyError(e, "Couldn't update plan. Please try again."));
		}
	});
	function onPickImage(e) {
		const file = e.target.files?.[0];
		e.target.value = "";
		if (!file) return;
		if (!file.type.startsWith("image/")) {
			toast.error("Pick an image file");
			return;
		}
		if (file.size > 5 * 1024 * 1024) {
			toast.error("Image must be under 5MB");
			return;
		}
		if (imagePreview) URL.revokeObjectURL(imagePreview);
		setImageFile(file);
		setImagePreview(URL.createObjectURL(file));
		setImageCleared(false);
	}
	function clearImage() {
		if (imagePreview) URL.revokeObjectURL(imagePreview);
		setImageFile(null);
		setImagePreview(null);
		setImageCleared(true);
	}
	if (!open || !activity) return null;
	const showImage = imagePreview || !imageCleared && existingImage;
	if (typeof document === "undefined") return null;
	return (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
		onClick: onClose,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
			onSubmit: (e) => {
				e.preventDefault();
				mutation.mutate();
			},
			onClick: (e) => e.stopPropagation(),
			className: "fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mb-4 flex items-center justify-between",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "text-lg font-bold",
					children: "Edit plan"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					type: "button",
					onClick: onClose,
					className: "rounded-full p-1 hover:bg-accent",
					"aria-label": "Close",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4" })
				})]
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col gap-3 text-sm",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
						ref: fileRef,
						type: "file",
						accept: "image/*",
						className: "hidden",
						onChange: onPickImage
					}),
					showImage ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "relative overflow-hidden rounded-2xl border border-border/60",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
								src: imagePreview ?? existingImage ?? "",
								alt: "",
								className: "h-40 w-full object-cover"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: clearImage,
								className: "absolute right-2 top-2 flex h-8 w-8 items-center justify-center rounded-full bg-background/90 shadow",
								"aria-label": "Remove photo",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trash2, { className: "h-3.5 w-3.5" })
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: () => fileRef.current?.click(),
								className: "absolute bottom-2 right-2 rounded-full bg-background/90 px-3 py-1 text-xs font-semibold shadow",
								children: "Replace"
							})
						]
					}) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
						type: "button",
						onClick: () => fileRef.current?.click(),
						className: "flex h-28 w-full items-center justify-center gap-2 rounded-2xl border border-dashed border-border bg-background text-xs text-muted-foreground transition hover:border-primary/60 hover:text-primary",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Image$1, { className: "h-4 w-4" }), " Add cover photo"]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
						className: "flex flex-col gap-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
							children: "Title"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
							value: form.title,
							maxLength: 80,
							onChange: (e) => setForm({
								...form,
								title: e.target.value
							}),
							className: "rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
						className: "flex flex-col gap-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
							children: "Description"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", {
							value: form.description,
							maxLength: 500,
							rows: 3,
							onChange: (e) => setForm({
								...form,
								description: e.target.value
							}),
							className: "resize-none rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex flex-col gap-1",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
								children: "Category"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "flex gap-1.5 overflow-x-auto pb-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden",
								children: CATEGORY_GROUPS.map((g) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
									type: "button",
									onClick: () => setGroupFilter(g),
									className: `shrink-0 rounded-full border px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wider transition ${groupFilter === g ? "border-primary/60 bg-primary/10 text-primary" : "border-border/60 bg-background text-muted-foreground"}`,
									children: g
								}, g))
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "flex flex-wrap gap-2",
								children: CATEGORIES.filter((c) => c.group === groupFilter).map((c) => {
									const Icon = c.icon;
									return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
										type: "button",
										onClick: () => setForm({
											...form,
											category: c.key
										}),
										className: `flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition ${form.category === c.key ? "border-primary bg-primary text-primary-foreground" : "border-border/60 bg-background text-muted-foreground"}`,
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Icon, { className: "h-3.5 w-3.5" }), c.label]
									}, c.key);
								})
							})
						]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "grid grid-cols-2 gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
							className: "flex flex-col gap-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
								children: "Date"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
								type: "date",
								value: form.date,
								onChange: (e) => setForm({
									...form,
									date: e.target.value
								}),
								className: "rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary [color-scheme:light] dark:[color-scheme:dark]"
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
							className: "flex flex-col gap-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
								children: "Time"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
								type: "time",
								value: form.time,
								onChange: (e) => setForm({
									...form,
									time: e.target.value
								}),
								className: "rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary [color-scheme:light] dark:[color-scheme:dark]"
							})]
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "grid grid-cols-2 gap-2",
						children: [{
							on: false,
							emoji: "📍",
							label: "In-Person"
						}, {
							on: true,
							emoji: "💻",
							label: "Online"
						}].map((opt) => {
							return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
								type: "button",
								onClick: () => setForm({
									...form,
									is_online: opt.on
								}),
								className: `flex items-center justify-center gap-1.5 rounded-2xl border px-2 py-2 text-xs font-semibold transition ${form.is_online === opt.on ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-background text-muted-foreground"}`,
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: opt.emoji }),
									" ",
									opt.label
								]
							}, opt.label);
						})
					}),
					form.is_online ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
						className: "flex flex-col gap-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
							className: "flex items-center gap-1 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link$1, { className: "h-3 w-3" }), " Meeting link"]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
							type: "url",
							value: form.meeting_link,
							maxLength: 500,
							onChange: (e) => setForm({
								...form,
								meeting_link: e.target.value
							}),
							placeholder: "https://meet.google.com/…",
							className: "rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
						})]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
						className: "flex items-center gap-1.5 text-[11px] text-muted-foreground",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Lock, { className: "h-3 w-3 text-primary" }), " Only accepted attendees see this link."]
					})] }) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
						className: "flex flex-col gap-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
							children: "Venue / Location"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
							value: form.location,
							maxLength: 120,
							onChange: (e) => setForm({
								...form,
								location: e.target.value
							}),
							className: "rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
						})]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex flex-col gap-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
							children: "Venue amenities"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "flex flex-wrap gap-2",
							children: AMENITIES.map((a) => {
								const active = amenities.includes(a.key);
								const Icon = a.icon;
								return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
									type: "button",
									onClick: () => setAmenities((prev) => prev.includes(a.key) ? prev.filter((k) => k !== a.key) : [...prev, a.key]),
									className: `flex items-center gap-1.5 rounded-full border px-3 py-1 text-[11px] font-medium transition ${active ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-background text-muted-foreground"}`,
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Icon, { className: "h-3 w-3" }),
										" ",
										a.label
									]
								}, a.key);
							})
						})]
					})] }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
						className: "flex flex-col gap-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
							children: "Topic tags (optional)"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
							value: form.topic_tags,
							maxLength: 120,
							onChange: (e) => setForm({
								...form,
								topic_tags: e.target.value
							}),
							placeholder: "React, TypeScript",
							className: "rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "grid grid-cols-2 gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
							className: "flex flex-col gap-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
								children: "Total slots"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
								type: "number",
								min: 1,
								max: 50,
								value: form.slots,
								onChange: (e) => setForm({
									...form,
									slots: e.target.value
								}),
								className: "rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
							className: "flex flex-col gap-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
								children: "Cost / head (₹)"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
								type: "number",
								min: 0,
								value: form.cost,
								onChange: (e) => setForm({
									...form,
									cost: e.target.value
								}),
								className: "rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
							})]
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						type: "submit",
						disabled: mutation.isPending || uploading,
						className: "mt-2 flex w-full items-center justify-center gap-2 rounded-2xl bg-primary py-3 text-sm font-semibold text-primary-foreground transition active:scale-[0.99] disabled:opacity-60",
						children: uploading ? "Uploading…" : mutation.isPending ? "Saving…" : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "h-4 w-4" }), " Save changes"] })
					})
				]
			})]
		})
	}), document.body);
}
var REPORT_REASONS = [
	{
		value: "harassment",
		label: "Harassment or Bullying"
	},
	{
		value: "unsafe_behavior",
		label: "Unsafe or Dangerous Behavior"
	},
	{
		value: "fake_profile",
		label: "Fake Profile or Impersonation"
	},
	{
		value: "inappropriate_content",
		label: "Inappropriate Content"
	},
	{
		value: "spam",
		label: "Spam or Commercial Promotion"
	},
	{
		value: "other",
		label: "Other Concern"
	}
];
function ReportModal({ open, onClose, targetType, targetId, targetTitle }) {
	const { user } = useAuth();
	const [selectedReason, setSelectedReason] = (0, import_react.useState)("harassment");
	const [notes, setNotes] = (0, import_react.useState)("");
	const [isSubmitting, setIsSubmitting] = (0, import_react.useState)(false);
	if (!open || typeof document === "undefined") return null;
	async function handleSubmit(e) {
		e.preventDefault();
		if (!user) {
			toast.error("Please sign in to report content.");
			return;
		}
		setIsSubmitting(true);
		try {
			if (await submitReport({
				targetType,
				targetId,
				reason: selectedReason,
				notes
			})) {
				toast.success("Thanks, we've received your report. Our team will review it.");
				setNotes("");
				onClose();
			} else toast.error("Couldn't send report right now. Please try again.");
		} catch {
			toast.error("Couldn't send report right now. Please try again.");
		} finally {
			setIsSubmitting(false);
		}
	}
	return (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "fixed inset-0 z-[99998] bg-black/80 backdrop-blur-md transition-opacity",
		onClick: () => !isSubmitting && onClose()
	}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		onClick: (e) => e.stopPropagation(),
		className: "fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-[99999] w-[92vw] max-w-md rounded-3xl p-6 bg-card border border-border/80 shadow-2xl max-h-[90vh] overflow-y-auto animate-in fade-in zoom-in-95 duration-200",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "flex items-center justify-between border-b border-border/60 pb-3",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center gap-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "flex h-9 w-9 items-center justify-center rounded-xl bg-destructive/15 text-destructive",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShieldAlert, { className: "h-5 w-5" })
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "text-base font-bold",
					children: "Report Content"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-xs text-muted-foreground truncate max-w-[240px]",
					children: targetTitle
				})] })]
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
				onClick: onClose,
				disabled: isSubmitting,
				className: "rounded-full p-1.5 text-muted-foreground hover:bg-accent transition",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4" })
			})]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
			onSubmit: handleSubmit,
			className: "mt-4 flex flex-col gap-4",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("label", {
					className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
					children: "Select Reason"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "mt-2 space-y-1.5",
					children: REPORT_REASONS.map((r) => {
						const isSelected = selectedReason === r.value;
						return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
							type: "button",
							onClick: () => setSelectedReason(r.value),
							className: `flex w-full items-center justify-between rounded-xl border px-3.5 py-2.5 text-left text-xs font-medium transition ${isSelected ? "border-primary bg-primary/10 text-foreground" : "border-border/60 bg-background/50 hover:bg-accent text-muted-foreground"}`,
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: r.label }), isSelected && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "flex h-4 w-4 items-center justify-center rounded-full bg-primary text-primary-foreground",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "h-2.5 w-2.5" })
							})]
						}, r.value);
					})
				})] }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("label", {
					className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
					children: "Additional Details (Optional)"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", {
					value: notes,
					onChange: (e) => setNotes(e.target.value),
					placeholder: "Provide any relevant details to help our safety team investigate...",
					rows: 3,
					maxLength: 500,
					className: "mt-1.5 w-full resize-none rounded-xl border border-border/60 bg-background px-3 py-2 text-xs outline-none focus:border-primary placeholder:text-muted-foreground"
				})] }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center justify-end gap-2 pt-2 border-t border-border/60",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						type: "button",
						onClick: onClose,
						disabled: isSubmitting,
						className: "rounded-full border border-border/60 px-4 py-2 text-xs font-semibold hover:bg-accent transition disabled:opacity-50",
						children: "Cancel"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
						type: "submit",
						disabled: isSubmitting,
						className: "flex items-center gap-1.5 rounded-full bg-destructive px-5 py-2 text-xs font-semibold text-destructive-foreground hover:scale-105 active:scale-95 transition disabled:opacity-50",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Flag, { className: "h-3 w-3" }), isSubmitting ? "Submitting…" : "Submit Report"]
					})]
				})
			]
		})]
	})] }), document.body);
}
var Route$9 = createFileRoute("/")({ component: Explore });
var SORTS = [
	{
		key: "date",
		label: "Date"
	},
	{
		key: "distance",
		label: "Distance"
	},
	{
		key: "popularity",
		label: "Popularity"
	}
];
function formatWhen(iso) {
	const d = new Date(iso);
	const now = /* @__PURE__ */ new Date();
	const sameDay = d.toDateString() === now.toDateString();
	const tomorrow = new Date(now);
	tomorrow.setDate(now.getDate() + 1);
	const isTom = d.toDateString() === tomorrow.toDateString();
	const time = d.toLocaleTimeString([], {
		hour: "numeric",
		minute: "2-digit"
	});
	if (sameDay) return `Today · ${time}`;
	if (isTom) return `Tomorrow · ${time}`;
	return `${d.toLocaleDateString([], {
		weekday: "short",
		month: "short",
		day: "numeric"
	})} · ${time}`;
}
function Explore() {
	const [active, setActive] = (0, import_react.useState)("All");
	const [activeGroup, setActiveGroup] = (0, import_react.useState)("All");
	const [modeFilter, setModeFilter] = (0, import_react.useState)("all");
	const [query, setQuery] = (0, import_react.useState)("");
	const [sort, setSort] = (0, import_react.useState)("date");
	const [sortOpen, setSortOpen] = (0, import_react.useState)(false);
	const [freeOnly, setFreeOnly] = (0, import_react.useState)(false);
	const [spotsOnly, setSpotsOnly] = (0, import_react.useState)(false);
	const [todayOnly, setTodayOnly] = (0, import_react.useState)(false);
	const [weekendOnly, setWeekendOnly] = (0, import_react.useState)(false);
	const [verifiedHostsOnly, setVerifiedHostsOnly] = (0, import_react.useState)(false);
	const sortPanelRef = (0, import_react.useRef)(null);
	const [scope, setScope] = (0, import_react.useState)("discover");
	const [lightbox, setLightbox] = (0, import_react.useState)(null);
	const { user, loading: authLoading } = useAuth();
	const navigate = useNavigate();
	const qc = useQueryClient();
	const { location, place, setPlace, requestBrowserLocation, requesting } = useLocation();
	const [applyRadiusFilter, setApplyRadiusFilter] = (0, import_react.useState)(true);
	const [pendingJoinId, setPendingJoinId] = (0, import_react.useState)(null);
	const [manageActivityId, setManageActivityId] = (0, import_react.useState)(null);
	const [urgentBusyId, setUrgentBusyId] = (0, import_react.useState)(null);
	const [editingPlan, setEditingPlan] = (0, import_react.useState)(null);
	const [deletingPlan, setDeletingPlan] = (0, import_react.useState)(null);
	const [reportingPlan, setReportingPlan] = (0, import_react.useState)(null);
	const { data: viewerProfile } = useQuery({
		queryKey: ["profile", user?.id],
		queryFn: () => getProfile(user.id),
		enabled: !!user,
		staleTime: 300 * 1e3
	});
	const viewerCoords = (0, import_react.useMemo)(() => {
		const lat = place?.lat ?? viewerProfile?.latitude;
		const lon = place?.lon ?? viewerProfile?.longitude;
		return lat != null && lon != null ? {
			lat,
			lon
		} : null;
	}, [place, viewerProfile]);
	const { data: activities = [], isLoading, error, refetch } = useQuery({
		queryKey: [
			"activities",
			viewerCoords?.lat,
			viewerCoords?.lon
		],
		queryFn: () => viewerCoords ? fetchNearbyActivities(viewerCoords.lat, viewerCoords.lon, 15, 60, 0) : listActivities(),
		staleTime: 120 * 1e3,
		gcTime: 600 * 1e3
	});
	const { data: mineJoined, error: mineError } = useQuery({
		queryKey: ["user-activities", user?.id],
		queryFn: () => getUserActivities(user.id),
		enabled: !!user,
		staleTime: 120 * 1e3,
		gcTime: 600 * 1e3
	});
	(0, import_react.useEffect)(() => {
		if (mineError) console.error("[explore] user-activities failed", mineError);
	}, [mineError]);
	const mineIds = (0, import_react.useMemo)(() => new Set((mineJoined?.hosted ?? []).map((a) => a.id)), [mineJoined]);
	const joinedIds = (0, import_react.useMemo)(() => new Set((mineJoined?.joined ?? []).map((a) => a.id)), [mineJoined]);
	const { data: myRequests = [] } = useQuery({
		queryKey: ["my-join-requests", user?.id],
		queryFn: () => listMyJoinRequests(user.id),
		enabled: !!user,
		staleTime: 120 * 1e3,
		gcTime: 600 * 1e3
	});
	const viewerIsFemale = (() => {
		const g = (viewerProfile?.gender ?? "").toLowerCase().trim();
		return [
			"female",
			"woman",
			"f",
			"w"
		].includes(g);
	})();
	const viewerIsVerified = !!viewerProfile?.is_verified;
	const hasProfileGpsLocation = !user || !!viewerProfile?.city && viewerProfile.latitude != null && viewerProfile.longitude != null;
	const requestedIds = (0, import_react.useMemo)(() => new Set(myRequests.filter((r) => r.status === "pending").map((r) => r.activity_id)), [myRequests]);
	const acceptedRequestIds = (0, import_react.useMemo)(() => new Set(myRequests.filter((r) => r.status === "accepted").map((r) => r.activity_id)), [myRequests]);
	const { data: hostPending = [] } = useQuery({
		queryKey: ["pending-requests-host", user?.id],
		queryFn: () => listPendingRequestsForHost(user.id),
		enabled: !!user,
		staleTime: 120 * 1e3,
		gcTime: 600 * 1e3
	});
	const pendingByActivity = (0, import_react.useMemo)(() => {
		const m = /* @__PURE__ */ new Map();
		hostPending.forEach((r) => m.set(r.activity_id, (m.get(r.activity_id) ?? 0) + 1));
		return m;
	}, [hostPending]);
	const { data: blockedIds = /* @__PURE__ */ new Set() } = useQuery({
		queryKey: ["blocked-ids", user?.id],
		queryFn: () => getBlockedIds(user.id),
		enabled: !!user,
		staleTime: 300 * 1e3
	});
	useMutation({
		mutationFn: (hostId) => blockUser(hostId),
		onSuccess: () => {
			toast.success("Host blocked — their plans will no longer appear in your feed.");
			qc.invalidateQueries({ queryKey: ["blocked-ids", user?.id] });
			qc.invalidateQueries({ queryKey: ["blocked-users", user?.id] });
			qc.invalidateQueries({ queryKey: ["activities"] });
			qc.invalidateQueries({ queryKey: ["my-join-requests", user?.id] });
		},
		onError: (e) => toast.error(friendlyError(e))
	});
	(0, import_react.useEffect)(() => {
		const actChannel = supabase.channel("public:activities").on("postgres_changes", {
			event: "*",
			schema: "public",
			table: "activities"
		}, () => {
			qc.invalidateQueries({ queryKey: ["activities"] });
			if (user?.id) qc.invalidateQueries({ queryKey: ["user-activities", user.id] });
		}).subscribe();
		let blockChannel = null;
		if (user?.id) blockChannel = supabase.channel(`blocks:${user.id}`).on("postgres_changes", {
			event: "*",
			schema: "public",
			table: "blocks"
		}, () => {
			qc.invalidateQueries({ queryKey: ["blocked-ids", user.id] });
			qc.invalidateQueries({ queryKey: ["activities"] });
			qc.invalidateQueries({ queryKey: ["my-join-requests", user.id] });
		}).subscribe();
		return () => {
			supabase.removeChannel(actChannel);
			if (blockChannel) supabase.removeChannel(blockChannel);
		};
	}, [qc, user?.id]);
	const join = useMutation({
		mutationFn: (id) => requestToJoin(id),
		onSuccess: () => {
			toast.success("Request sent to host");
			qc.invalidateQueries({ queryKey: ["activities"] });
			qc.invalidateQueries({ queryKey: ["my-join-requests", user?.id] });
			qc.invalidateQueries({ queryKey: ["user-activities", user?.id] });
		},
		onError: (e) => toast.error(friendlyError(e))
	});
	const deleteMut = useMutation({
		mutationFn: (id) => deleteActivity(id),
		onSuccess: async () => {
			toast.success("Plan deleted");
			setDeletingPlan(null);
			await Promise.all([
				qc.refetchQueries({ queryKey: ["activities"] }),
				qc.refetchQueries({ queryKey: ["user-activities", user?.id] }),
				qc.invalidateQueries({ queryKey: ["user-stats", user?.id] }),
				qc.invalidateQueries({ queryKey: ["profile", user?.id] })
			]);
		},
		onError: (e) => {
			console.error("[delete-plan] failed", e);
			toast.error(friendlyError(e, "Couldn't delete plan. Please try again."));
		}
	});
	async function handleToggleUrgent(a) {
		const active = isUrgentActive(a);
		setUrgentBusyId(a.id);
		try {
			await setActivityUrgent(a.id, !active, 30);
			if (!active) {
				toast.success("⚡ Urgent alert sent to nearby players");
				try {
					const res = await notifyUrgentSpot({ data: { activityId: a.id } });
					if (res?.success && (res.sent ?? 0) > 0) toast.success(`Notified ${res.sent} nearby ${res.sent === 1 ? "player" : "players"}`);
				} catch (err) {
					console.error("[urgent] push dispatch failed", err);
				}
			} else toast.success("Urgent mode cleared");
			qc.invalidateQueries({ queryKey: ["activities"] });
		} catch (e) {
			toast.error(friendlyError(e));
		} finally {
			setUrgentBusyId(null);
		}
	}
	(0, import_react.useEffect)(() => {
		if (typeof window === "undefined" || !user) return;
		const params = new URLSearchParams(window.location.search);
		const aid = params.get("activity");
		const join = params.get("join");
		if (aid && join === "1") {
			setPendingJoinId(aid);
			const url = new URL(window.location.href);
			url.searchParams.delete("activity");
			url.searchParams.delete("join");
			window.history.replaceState({}, "", url.pathname + (url.search || ""));
		}
	}, [user]);
	(0, import_react.useEffect)(() => {
		if (!sortOpen) return;
		function onDown(e) {
			const el = sortPanelRef.current;
			if (el && !el.contains(e.target)) setSortOpen(false);
		}
		function onKey(e) {
			if (e.key === "Escape") setSortOpen(false);
		}
		document.addEventListener("mousedown", onDown);
		document.addEventListener("touchstart", onDown, { passive: true });
		document.addEventListener("keydown", onKey);
		return () => {
			document.removeEventListener("mousedown", onDown);
			document.removeEventListener("touchstart", onDown);
			document.removeEventListener("keydown", onKey);
		};
	}, [sortOpen]);
	const activeFilterCount = (freeOnly ? 1 : 0) + (spotsOnly ? 1 : 0) + (todayOnly ? 1 : 0) + (weekendOnly ? 1 : 0) + (verifiedHostsOnly ? 1 : 0);
	const filtered = (0, import_react.useMemo)(() => {
		const q = query.trim().toLowerCase();
		const nowMs = Date.now();
		const viewerLat = place?.lat ?? viewerProfile?.latitude ?? 12.9716;
		const viewerLon = place?.lon ?? viewerProfile?.longitude ?? 77.5946;
		const sorted = [...(scope === "hosting" && user ? mineJoined?.hosted ?? [] : scope === "joined" && user ? mineJoined?.joined ?? [] : activities).map((a) => {
			let distanceKm = null;
			const targetLat = !a.is_online ? a.latitude : a.latitude ?? a.host?.latitude ?? null;
			const targetLon = !a.is_online ? a.longitude : a.longitude ?? a.host?.longitude ?? null;
			if (targetLat != null && targetLon != null && viewerLat != null && viewerLon != null) distanceKm = haversineKm(viewerLat, viewerLon, targetLat, targetLon);
			return {
				...a,
				distanceKm
			};
		}).filter((a) => {
			if (user) {
				if (blockedIds.has(a.host_id)) return false;
				const hostedByMe = a.host_id === user.id || mineIds.has(a.id);
				if (scope === "hosting" && !hostedByMe) return false;
				if (scope === "joined" && !joinedIds.has(a.id)) return false;
			}
			if (active !== "All" && a.category !== active) return false;
			if (activeGroup !== "All") {
				if (CATEGORIES.find((c) => c.key === a.category)?.group !== activeGroup) return false;
			}
			if (modeFilter === "in_person" && a.is_online) return false;
			if (modeFilter === "online" && !a.is_online) return false;
			if (freeOnly && (a.cost_per_head ?? 0) > 0) return false;
			if (spotsOnly && (a.slots_left ?? 0) <= 0) return false;
			if (todayOnly) {
				const d = new Date(a.date_time);
				const now = /* @__PURE__ */ new Date();
				if (d.toDateString() !== now.toDateString()) return false;
			}
			if (weekendOnly) {
				const day = new Date(a.date_time).getDay();
				if (day !== 0 && day !== 6) return false;
			}
			if (verifiedHostsOnly && !a.host?.is_verified) return false;
			if (scope === "discover" && applyRadiusFilter) {
				if (!a.is_online) {
					if (a.distanceKm == null || a.distanceKm > 15.001) return false;
				} else if (a.distanceKm != null && a.distanceKm > 15.001) return false;
			}
			if (!q) return true;
			return a.title.toLowerCase().includes(q) || a.location.toLowerCase().includes(q) || a.category.toLowerCase().includes(q) || (a.topic_tags ?? []).some((t) => t.toLowerCase().includes(q));
		})];
		if (sort === "date") sorted.sort((a, b) => {
			const aUpcoming = new Date(a.date_time).getTime() >= nowMs;
			const bUpcoming = new Date(b.date_time).getTime() >= nowMs;
			if (aUpcoming && !bUpcoming) return -1;
			if (!aUpcoming && bUpcoming) return 1;
			return a.date_time < b.date_time ? -1 : 1;
		});
		else if (sort === "popularity") sorted.sort((a, b) => {
			return (a.total_slots > 0 ? a.slots_left / a.total_slots : 1) - (b.total_slots > 0 ? b.slots_left / b.total_slots : 1);
		});
		else if (sort === "distance") sorted.sort((a, b) => {
			const da = a.distanceKm ?? 999999;
			const db = b.distanceKm ?? 999999;
			if (da !== db) return da - db;
			return a.date_time < b.date_time ? -1 : 1;
		});
		return sorted.map((a) => maskActivityForViewer(a, user?.id ?? null, acceptedRequestIds));
	}, [
		activities,
		mineJoined,
		active,
		activeGroup,
		modeFilter,
		query,
		sort,
		place,
		viewerProfile,
		applyRadiusFilter,
		scope,
		mineIds,
		joinedIds,
		user,
		acceptedRequestIds,
		freeOnly,
		spotsOnly,
		todayOnly,
		weekendOnly,
		verifiedHostsOnly,
		blockedIds
	]);
	async function handleUseGPS() {
		try {
			await requestBrowserLocation();
			toast.success("Location updated");
		} catch (e) {
			toast.error(e instanceof Error ? e.message : "Couldn't get your location");
		}
	}
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex flex-col gap-5 px-5 pt-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", {
				className: "flex items-start justify-between gap-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "min-w-0 flex-1",
					children: [user ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center gap-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(PlaceSearch, {
							value: location,
							onSelect: (p) => {
								setPlace(p);
								toast.success(`Showing plans near ${p.short}`);
							}
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: handleUseGPS,
							disabled: requesting,
							className: "text-muted-foreground/70 transition hover:text-primary disabled:opacity-50",
							"aria-label": "Use current location",
							title: "Use my location",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Navigation, { className: `h-3 w-3 ${requesting ? "animate-pulse" : ""}` })
						})]
					}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground",
						children: "Discover plans nearby"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h1", {
						className: "mt-1 font-brand text-3xl font-black tracking-tight text-primary",
						children: ["tribe", /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-black dark:text-white",
							children: "X"
						})]
					})]
				}), authLoading ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-11 w-11 shrink-0 animate-pulse rounded-full bg-card" }) : user ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex shrink-0 items-center gap-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(NotificationsBell, {
						userId: user.id,
						onOpenActivity: (id) => setManageActivityId(id),
						onOpenChat: (id) => navigate({
							to: "/chat/$activityId",
							params: { activityId: id }
						})
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						onClick: () => navigate({ to: "/profile" }),
						className: "h-11 w-11 shrink-0 overflow-hidden rounded-full bg-primary text-primary-foreground font-semibold transition hover:scale-105 active:scale-95",
						"aria-label": "Open profile",
						children: viewerProfile?.avatar_url ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
							src: viewerProfile.avatar_url,
							alt: "",
							className: "h-full w-full object-cover"
						}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "flex h-full w-full items-center justify-center",
							children: (viewerProfile?.full_name || user.user_metadata?.full_name || user.email || "U")[0]?.toUpperCase()
						})
					})]
				}) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					onClick: () => navigate({ to: "/auth" }),
					className: "flex shrink-0 items-center gap-1.5 rounded-full bg-primary px-4 py-2 text-xs font-semibold text-primary-foreground transition hover:scale-105 active:scale-95",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(LogIn, { className: "h-3.5 w-3.5" }), " Sign in"]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center gap-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
					className: "flex flex-1 items-center gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3 transition focus-within:border-primary",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Search, { className: "h-4 w-4 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
						value: query,
						onChange: (e) => setQuery(e.target.value),
						placeholder: "Search plans, sports, spots…",
						className: "w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
					})]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "relative",
					ref: sortPanelRef,
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
						onClick: () => setSortOpen((v) => !v),
						"aria-label": "Sort & filter",
						className: "relative flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl border border-border/60 bg-card transition hover:border-primary active:scale-95",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SlidersHorizontal, { className: "h-4 w-4" }), activeFilterCount > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "absolute -right-1 -top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-primary px-1 text-[9px] font-bold text-primary-foreground ring-2 ring-background",
							children: activeFilterCount
						})]
					}), sortOpen && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "absolute right-0 top-14 z-30 w-72 overflow-hidden rounded-2xl border border-border/60 bg-card shadow-xl",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex items-center justify-between border-b border-border/60 px-4 py-2.5",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-[10px] font-bold uppercase tracking-wider text-muted-foreground",
									children: "Sort & Filter"
								}), (activeFilterCount > 0 || sort !== "date") && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
									onClick: () => {
										setSort("date");
										setFreeOnly(false);
										setSpotsOnly(false);
										setTodayOnly(false);
										setWeekendOnly(false);
										setVerifiedHostsOnly(false);
									},
									className: "text-[10px] font-semibold uppercase tracking-wider text-primary hover:underline",
									children: "Reset"
								})]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "px-4 pt-3",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
									className: "mb-2 flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowUpDown, { className: "h-3 w-3" }), " Sort by"]
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "grid grid-cols-3 gap-1.5",
									children: SORTS.map((s) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
										onClick: () => setSort(s.key),
										className: `rounded-lg border px-2 py-1.5 text-[11px] font-semibold transition ${sort === s.key ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-background text-muted-foreground hover:border-primary/60"}`,
										children: s.label
									}, s.key))
								})]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "px-4 pb-4 pt-3",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "mb-2 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground",
										children: "Quick filters"
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
										className: "flex flex-col gap-1.5",
										children: [
											{
												k: "free",
												label: "Free entry",
												icon: IndianRupee,
												on: freeOnly,
												set: setFreeOnly
											},
											{
												k: "spots",
												label: "Has open spots",
												icon: Users,
												on: spotsOnly,
												set: setSpotsOnly
											},
											{
												k: "today",
												label: "Today only",
												icon: Clock,
												on: todayOnly,
												set: setTodayOnly
											},
											{
												k: "weekend",
												label: "This weekend",
												icon: CalendarDays,
												on: weekendOnly,
												set: setWeekendOnly
											},
											{
												k: "verified",
												label: "Verified hosts only",
												icon: BadgeCheck,
												on: verifiedHostsOnly,
												set: setVerifiedHostsOnly
											}
										].map(({ k, label, icon: Icon, on, set }) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
											onClick: () => set((v) => !v),
											className: `flex items-center justify-between rounded-lg border px-3 py-2 text-xs font-medium transition ${on ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-background text-foreground hover:border-primary/50"}`,
											children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
												className: "flex items-center gap-2",
												children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Icon, { className: "h-3.5 w-3.5" }), label]
											}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
												className: `flex h-4 w-4 items-center justify-center rounded-full border ${on ? "border-primary bg-primary text-primary-foreground" : "border-border"}`,
												children: on && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, {
													className: "h-2.5 w-2.5",
													strokeWidth: 3
												})
											})]
										}, k))
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
										onClick: () => setSortOpen(false),
										className: "mt-3 flex w-full items-center justify-center gap-1.5 rounded-lg bg-primary py-2 text-xs font-semibold text-primary-foreground transition hover:bg-primary/90",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkles, { className: "h-3.5 w-3.5" }), " Apply"]
									})
								]
							})
						]
					})]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex items-center justify-between",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "-mx-5 flex gap-2 overflow-x-auto px-5 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						onClick: () => {
							setActiveGroup("All");
							setActive("All");
						},
						className: `shrink-0 rounded-full border px-4 py-1.5 text-xs font-semibold transition-all active:scale-95 ${activeGroup === "All" && active === "All" ? "border-primary bg-primary text-primary-foreground shadow-sm" : "border-border/60 bg-card text-muted-foreground hover:border-primary/60"}`,
						children: "All"
					}), CATEGORY_GROUPS.map((g) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						onClick: () => {
							setActiveGroup(g);
							setActive("All");
						},
						className: `shrink-0 rounded-full border px-4 py-1.5 text-xs font-semibold uppercase tracking-wider transition-all active:scale-95 ${activeGroup === g ? "border-primary bg-primary text-primary-foreground shadow-sm" : "border-border/60 bg-card text-muted-foreground hover:border-primary/60"}`,
						children: g
					}, g))]
				})
			}),
			activeGroup !== "All" && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "-mx-5 flex gap-2 overflow-x-auto px-5 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					onClick: () => setActive("All"),
					className: `shrink-0 rounded-full border px-3 py-1 text-[11px] font-medium transition ${active === "All" ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-card text-muted-foreground"}`,
					children: "All in group"
				}), CATEGORIES.filter((c) => c.group === activeGroup).map((c) => {
					const Icon = c.icon;
					return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
						onClick: () => setActive(c.key),
						className: `flex shrink-0 items-center gap-1.5 rounded-full border px-3 py-1 text-[11px] font-medium transition ${active === c.key ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-card text-muted-foreground hover:border-primary/50"}`,
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Icon, { className: "h-3.5 w-3.5" }), c.label]
					}, c.key);
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex rounded-full border border-border/60 bg-card p-1 text-xs",
				children: [
					{
						k: "all",
						label: "All",
						icon: null
					},
					{
						k: "in_person",
						label: "In-Person",
						icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, { className: "h-3 w-3" })
					},
					{
						k: "online",
						label: "Virtual",
						icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Monitor, { className: "h-3 w-3" })
					}
				].map((m) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					onClick: () => setModeFilter(m.k),
					className: `flex flex-1 items-center justify-center gap-1 rounded-full px-3 py-1.5 font-semibold transition ${modeFilter === m.k ? "bg-foreground text-background" : "text-muted-foreground"}`,
					children: [m.icon, m.label]
				}, m.k))
			}),
			user && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex rounded-full border border-border/60 bg-card p-1 text-xs",
				children: [
					{
						k: "discover",
						label: "Discover"
					},
					{
						k: "joined",
						label: "Joined"
					},
					{
						k: "hosting",
						label: "Hosting"
					}
				].map((s) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					onClick: () => setScope(s.k),
					className: `flex-1 rounded-full px-3 py-1.5 font-medium transition ${scope === s.k ? "bg-foreground text-background" : "text-muted-foreground"}`,
					children: s.label
				}, s.k))
			}),
			scope === "discover" && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between rounded-2xl border border-primary/25 bg-primary/5 px-3.5 py-2.5 text-xs transition-all",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center gap-2 min-w-0",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { className: "flex h-2 w-2 shrink-0 rounded-full bg-emerald-500 animate-pulse" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "font-semibold text-primary truncate",
							children: applyRadiusFilter ? "Plans within 15 km" : "All nearby plans"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
							className: "text-muted-foreground truncate",
							children: ["· ", location || "Bengaluru"]
						})
					]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					onClick: () => setApplyRadiusFilter((v) => !v),
					className: "shrink-0 text-[11px] font-semibold text-primary hover:underline ml-2",
					children: applyRadiusFilter ? "Show all" : "Strict 15 km"
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "text-lg font-semibold tracking-tight",
					children: !user || scope === "discover" ? applyRadiusFilter ? "Plans within 15 km" : "Happening nearby" : scope === "joined" ? "Plans you've joined" : "Plans you're hosting"
				}), filtered.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
					className: "text-xs text-muted-foreground",
					children: [
						filtered.length,
						" ",
						filtered.length === 1 ? "plan" : "plans"
					]
				})]
			}),
			isLoading ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ListSkeleton, {
				count: 3,
				variant: "card"
			}) : error ? !user ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col items-start gap-3 rounded-2xl border border-border/60 bg-card p-4 text-sm",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "font-semibold",
						children: "Sign in to see plans near you"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs text-muted-foreground",
						children: "Join the tribe to discover activities, chat with hosts, and RSVP in seconds."
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						onClick: () => navigate({ to: "/auth" }),
						className: "rounded-full bg-primary px-4 py-1.5 text-xs font-semibold text-primary-foreground transition hover:scale-105 active:scale-95",
						children: "Sign in to continue"
					})
				]
			}) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col items-start gap-3 rounded-2xl border border-border/60 bg-card p-4 text-sm",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "font-semibold",
						children: "We couldn't load plans right now"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs text-muted-foreground",
						children: "Check your connection and try again."
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						onClick: () => refetch(),
						className: "rounded-full bg-primary px-4 py-1.5 text-xs font-semibold text-primary-foreground transition hover:scale-105 active:scale-95",
						children: "Retry"
					})
				]
			}) : filtered.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col items-center gap-2 rounded-3xl border border-dashed border-border bg-card/40 py-10 text-center",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-sm text-muted-foreground",
					children: scope === "hosting" ? "You haven't hosted any plans yet." : scope === "joined" ? "You haven't joined any plans yet." : "No plans match your filters right now."
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-[11px] text-muted-foreground/70",
					children: "Tap the + button above or the Create tab to post one."
				})]
			}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
				className: "grid grid-cols-1 gap-3 sm:grid-cols-2 md:gap-4 lg:grid-cols-3",
				children: filtered.map((a) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ActivityCard, {
					activity: a,
					onImage: (url) => setLightbox(url),
					isHost: a.host_id === user?.id || mineIds.has(a.id),
					hasRequested: requestedIds.has(a.id),
					viewerIsFemale,
					viewerIsVerified,
					hasProfileGpsLocation,
					distanceKm: a.distanceKm,
					myStatus: a.host_id === user?.id || mineIds.has(a.id) ? "hosting" : acceptedRequestIds.has(a.id) || joinedIds.has(a.id) ? "confirmed" : requestedIds.has(a.id) ? "pending" : null,
					pendingCount: pendingByActivity.get(a.id) ?? 0,
					onManage: () => setManageActivityId(a.id),
					onEdit: () => {
						const full = activities.find((x) => x.id === a.id);
						if (full) setEditingPlan(full);
					},
					onDelete: () => {
						const full = activities.find((x) => x.id === a.id);
						if (full) setDeletingPlan(full);
					},
					onReport: () => {
						const full = activities.find((x) => x.id === a.id);
						if (full) setReportingPlan(full);
					},
					onToggleUrgent: () => handleToggleUrgent(a),
					urgentBusy: urgentBusyId === a.id,
					onJoin: () => {
						if (!user) {
							navigate({ to: "/auth" });
							return;
						}
						if (!hasProfileGpsLocation) {
							toast.error("Add your GPS profile location first", { description: "Open Profile → Edit details → Use current location." });
							return;
						}
						setPendingJoinId(a.id);
					},
					onMessage: () => {
						if (!user) {
							navigate({ to: "/auth" });
							return;
						}
						navigate({
							to: "/chat/$activityId",
							params: { activityId: a.id }
						});
					},
					joining: join.isPending
				}, a.id))
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SafetyDisclaimerModal, {
				open: pendingJoinId !== null,
				onCancel: () => setPendingJoinId(null),
				onAgree: () => {
					const id = pendingJoinId;
					setPendingJoinId(null);
					if (id) join.mutate(id);
				}
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ManageRequestsModal, {
				activityId: manageActivityId,
				activityTitle: activities.find((a) => a.id === manageActivityId)?.title,
				open: manageActivityId !== null,
				onClose: () => setManageActivityId(null)
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(EditPlanModal, {
				open: !!editingPlan,
				activity: editingPlan,
				onClose: () => setEditingPlan(null)
			}),
			reportingPlan && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ReportModal, {
				open: !!reportingPlan,
				onClose: () => setReportingPlan(null),
				targetType: "activity",
				targetId: reportingPlan.id,
				targetTitle: reportingPlan.title
			}),
			deletingPlan && typeof document !== "undefined" && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "fixed inset-0 z-[99998] bg-black/80 backdrop-blur-md",
				onClick: () => !deleteMut.isPending && setDeletingPlan(null)
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				onClick: (e) => e.stopPropagation(),
				className: "fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-[99999] w-[92vw] max-w-sm rounded-2xl p-6 bg-card border shadow-2xl max-h-[85vh] overflow-y-auto",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
						className: "text-lg font-bold",
						children: "Delete this plan?"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
						className: "mt-1 text-sm text-muted-foreground",
						children: [
							"\"",
							deletingPlan.title,
							"\" will be removed for everyone. This can't be undone."
						]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mt-5 flex items-center justify-end gap-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: () => setDeletingPlan(null),
							disabled: deleteMut.isPending,
							className: "rounded-full border border-border/60 px-4 py-2 text-xs font-semibold transition hover:bg-accent disabled:opacity-60",
							children: "Cancel"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
							onClick: () => deleteMut.mutate(deletingPlan.id),
							disabled: deleteMut.isPending,
							className: "flex items-center gap-1.5 rounded-full bg-destructive px-4 py-2 text-xs font-semibold text-destructive-foreground transition hover:scale-[1.02] active:scale-95 disabled:opacity-60",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trash2, { className: "h-3.5 w-3.5" }), deleteMut.isPending ? "Deleting…" : "Delete"]
						})]
					})
				]
			})] }), document.body),
			lightbox && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "fixed inset-0 z-[80] flex items-center justify-center bg-black/90 p-4 backdrop-blur-sm",
				onClick: () => setLightbox(null),
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					"aria-label": "Close preview",
					className: "absolute right-4 top-4 flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white transition hover:bg-white/20",
					onClick: () => setLightbox(null),
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-5 w-5" })
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
					src: lightbox,
					alt: "",
					className: "max-h-full max-w-full rounded-2xl object-contain"
				})]
			})
		]
	});
}
function ActivityCard({ activity: a, onJoin, onMessage, joining, onImage, isHost, hasRequested, viewerIsFemale, viewerIsVerified, hasProfileGpsLocation, distanceKm, myStatus, pendingCount, onManage, onToggleUrgent, urgentBusy, onEdit, onDelete, onReport }) {
	const accent = "bg-primary/15 text-primary";
	const urgent = a.slots_left <= 3;
	const hostName = a.host?.full_name || a.host?.username || "Host";
	const urgentActive = isUrgentActive(a);
	const shielded = hasSafetyShield(a);
	const shieldLabel = a.women_only && a.verified_only ? "Women & verified only" : a.women_only ? "Women only" : a.verified_only ? "Verified only" : null;
	const blockedByWomenOnly = !!a.women_only && !viewerIsFemale;
	const blockedByVerified = !!a.verified_only && !viewerIsVerified;
	const safetyBlock = blockedByWomenOnly ? "Women Only Plan" : blockedByVerified ? "Verification Required" : !hasProfileGpsLocation ? "Add GPS Location" : null;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
		className: "group relative flex h-full flex-col overflow-hidden rounded-3xl border border-border/60 bg-card p-4 transition-all hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-md active:scale-[0.99]",
		children: [
			isHost && pendingCount > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
				onClick: onManage,
				className: "absolute right-3 top-3 z-10 flex items-center gap-1 rounded-full bg-primary px-2.5 py-1 text-[10px] font-bold text-primary-foreground shadow-md ring-2 ring-background transition hover:scale-105 active:scale-95",
				"aria-label": `${pendingCount} pending requests`,
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Bell, { className: "h-3 w-3" }),
					pendingCount,
					" pending"
				]
			}),
			urgentActive && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "absolute left-3 top-3 z-10 flex items-center gap-1 rounded-full bg-red-500 px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider text-white shadow-lg ring-2 ring-background animate-pulse",
				"aria-label": "Urgent: spot needed",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Zap, { className: "h-3 w-3 fill-current" }), "Urgent · Spot needed"]
			}),
			a.image_url && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
				type: "button",
				onClick: (e) => {
					e.stopPropagation();
					onImage(a.image_url);
				},
				className: "-mx-4 -mt-4 mb-3 block h-36 w-[calc(100%+2rem)] overflow-hidden bg-secondary",
				"aria-label": "View photo",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
					src: a.image_url,
					alt: a.title,
					loading: "lazy",
					className: "h-full w-full object-cover transition duration-300 group-hover:scale-105"
				})
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-start gap-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: `flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl text-2xl leading-none transition group-hover:scale-105 ${accent}`,
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						"aria-hidden": true,
						children: emojiForCategory(a.category)
					})
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "min-w-0 flex-1",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex flex-wrap items-center gap-1.5",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: `shrink-0 rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider ${accent}`,
									children: a.category
								}),
								a.is_online && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
									className: "flex shrink-0 items-center gap-1 rounded-full bg-emerald-500/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-emerald-600 dark:text-emerald-400",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Globe, { className: "h-2.5 w-2.5" }), " Virtual"]
								}),
								myStatus === "confirmed" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "shrink-0 rounded-full bg-green-500/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-green-600 dark:text-green-400",
									children: "Confirmed"
								}),
								myStatus === "pending" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "shrink-0 rounded-full bg-amber-500/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-amber-600 dark:text-amber-400",
									children: "Awaiting approval"
								}),
								myStatus === "hosting" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "shrink-0 rounded-full bg-primary/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-primary",
									children: "Hosting"
								}),
								shielded && shieldLabel && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
									className: "flex shrink-0 items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-semibold text-primary",
									title: a.is_masked ? "Exact venue hidden until host approves" : shieldLabel,
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Shield, { className: "h-2.5 w-2.5" }),
										" ",
										shieldLabel
									]
								})
							]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
							className: "mt-1.5 line-clamp-2 text-base font-semibold tracking-tight",
							children: a.title
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mt-0.5 flex items-center gap-1.5 truncate text-xs text-muted-foreground",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, { className: "h-3 w-3 shrink-0" }),
								!a.is_online && distanceKm != null && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "shrink-0 rounded bg-primary/15 px-1.5 py-0.5 text-[10px] font-semibold text-primary",
									children: distanceKm < 1 ? `${Math.round(distanceKm * 1e3)} m away` : `${distanceKm.toFixed(1)} km away`
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
									className: "truncate",
									children: [a.is_masked ? "~ " : "", a.location]
								})
							]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
							className: "mt-0.5 flex items-center gap-1 text-xs text-muted-foreground",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Clock, { className: "h-3 w-3" }),
								" ",
								formatWhen(a.date_time)
							]
						}),
						((a.amenities ?? []).length > 0 || (a.topic_tags ?? []).length > 0) && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mt-2 flex flex-wrap items-center gap-1.5",
							children: [(a.amenities ?? []).slice(0, 4).map((k) => {
								const meta = AMENITY_MAP[k];
								if (!meta) return null;
								return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "rounded-full bg-secondary px-2 py-0.5 text-[10px] font-medium text-foreground/80",
									children: meta.badge
								}, k);
							}), (a.topic_tags ?? []).slice(0, 3).map((t) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "flex items-center gap-0.5 rounded-full border border-border/60 bg-background px-2 py-0.5 text-[10px] font-medium text-muted-foreground",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Hash, { className: "h-2.5 w-2.5" }), t]
							}, t))]
						})
					]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mt-auto flex flex-col gap-3 border-t border-border/60 pt-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center gap-x-2 gap-y-1 text-xs overflow-hidden",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
							className: "flex shrink-0 items-center gap-1 text-muted-foreground",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Users, { className: "h-3.5 w-3.5" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: urgent ? "font-semibold text-primary" : "",
								children: [
									a.slots_left,
									"/",
									a.total_slots
								]
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
							className: "flex shrink-0 items-center gap-1 text-muted-foreground",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-3.5 w-3.5 fill-current text-primary" }), Number(a.host?.rating ?? 5).toFixed(1)]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
							className: "flex min-w-0 flex-1 items-center gap-1 text-muted-foreground",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									"aria-hidden": true,
									className: "shrink-0",
									children: "·"
								}),
								a.host?.avatar_url ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
									src: a.host.avatar_url,
									alt: "",
									loading: "lazy",
									className: "h-4 w-4 shrink-0 rounded-full object-cover"
								}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-primary/20 text-[9px] font-bold text-primary",
									children: hostName[0]?.toUpperCase() ?? "H"
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "truncate",
									children: hostName
								}),
								a.host?.is_verified && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BadgeCheck, {
									className: "h-3 w-3 shrink-0 text-primary",
									"aria-label": "Verified host"
								})
							]
						})
					]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex w-full flex-wrap items-center gap-1.5",
					children: [isHost && a.slots_left > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						onClick: onToggleUrgent,
						disabled: urgentBusy,
						title: urgentActive ? "Cancel urgent alert" : "Send urgent spot alert to nearby players",
						className: `flex h-9 w-9 shrink-0 items-center justify-center rounded-full transition active:scale-95 disabled:opacity-50 ${urgentActive ? "bg-red-500 text-white shadow-sm animate-pulse hover:bg-red-600" : "border border-amber-500/60 bg-amber-500/10 text-amber-600 hover:bg-amber-500/20 dark:text-amber-400"}`,
						"aria-label": urgentActive ? "Urgent on" : "Urgent fill",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Zap, { className: "h-3.5 w-3.5" })
					}), isHost ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: onManage,
							className: "min-w-0 flex-1 truncate whitespace-nowrap rounded-full border border-primary/40 bg-primary/10 px-3 py-2 text-xs font-semibold text-primary transition hover:scale-[1.02] active:scale-95",
							children: "Manage"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: onMessage,
							className: "flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-primary/60 hover:text-primary active:scale-95",
							"aria-label": "Group chat",
							title: "Group chat",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(MessageCircle, { className: "h-3.5 w-3.5" })
						}),
						new Date(a.date_time).getTime() > Date.now() && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: onEdit,
							className: "flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-primary/60 hover:text-primary active:scale-95",
							"aria-label": "Edit plan",
							title: "Edit plan",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Pencil, { className: "h-3.5 w-3.5" })
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: onDelete,
							className: "flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-destructive/60 hover:text-destructive active:scale-95",
							"aria-label": "Delete plan",
							title: "Delete plan",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trash2, { className: "h-3.5 w-3.5" })
						})
					] }) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: onMessage,
							className: "flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-primary/60 hover:text-primary active:scale-95",
							"aria-label": "Message host",
							title: "Chat",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(MessageCircle, { className: "h-3.5 w-3.5" })
						}),
						onReport && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: onReport,
							className: "flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-destructive/60 hover:text-destructive active:scale-95",
							"aria-label": "Report plan",
							title: "Report plan",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Flag, { className: "h-3.5 w-3.5" })
						}),
						myStatus === "pending" || hasRequested ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
							disabled: true,
							className: "flex min-w-0 flex-1 items-center justify-center gap-1 truncate rounded-full border border-border/60 bg-secondary px-3 py-2 text-xs font-semibold text-muted-foreground disabled:cursor-not-allowed",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Hourglass, { className: "h-3 w-3" }), " Request Pending"]
						}) : myStatus === "confirmed" ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
							onClick: onMessage,
							className: "flex min-w-0 flex-1 items-center justify-center gap-1 truncate rounded-full bg-emerald-500/15 px-4 py-2 text-xs font-semibold text-emerald-600 dark:text-emerald-400 transition hover:bg-emerald-500/25 active:scale-95",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "h-3.5 w-3.5" }), " Joined"]
						}) : safetyBlock ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
							disabled: true,
							title: safetyBlock,
							className: "flex min-w-0 flex-1 items-center justify-center gap-1 truncate rounded-full border border-border/60 bg-secondary px-3 py-2 text-xs font-semibold text-muted-foreground disabled:cursor-not-allowed",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Shield, { className: "h-3 w-3" }),
								" ",
								safetyBlock
							]
						}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: onJoin,
							disabled: joining || a.slots_left <= 0,
							className: "min-w-0 flex-1 truncate rounded-full bg-primary px-4 py-2 text-xs font-semibold text-primary-foreground transition-transform hover:scale-[1.02] active:scale-95 disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:scale-100",
							children: a.slots_left <= 0 ? "Full" : joining ? "…" : "Request to Join"
						})
					] })]
				})]
			})
		]
	});
}
function GoogleIcon({ className = "h-4 w-4" }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("svg", {
		xmlns: "http://www.w3.org/2000/svg",
		viewBox: "0 0 48 48",
		className,
		"aria-hidden": "true",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", {
				fill: "#FFC107",
				d: "M43.6 20.5H42V20H24v8h11.3c-1.6 4.7-6.1 8-11.3 8-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.3-.4-3.5z"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", {
				fill: "#FF3D00",
				d: "M6.3 14.7l6.6 4.8C14.6 16 18.9 13 24 13c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 16.3 4 9.6 8.3 6.3 14.7z"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", {
				fill: "#4CAF50",
				d: "M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.3 35 26.8 36 24 36c-5.2 0-9.6-3.3-11.3-8l-6.5 5C9.5 39.6 16.2 44 24 44z"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", {
				fill: "#1976D2",
				d: "M43.6 20.5H42V20H24v8h11.3c-.8 2.3-2.3 4.2-4.1 5.6l6.2 5.2C41.9 35.7 44 30.3 44 24c0-1.3-.1-2.3-.4-3.5z"
			})
		]
	});
}
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
var requestSignInOtp = createServerFn({ method: "POST" }).validator((input) => emailSchema.parse(input)).handler(createSsrRpc("6573fa17d594216ecd66e568692b3abb7986d8c15394efed9495f11610aef7fa"));
var requestSignUpOtp = createServerFn({ method: "POST" }).validator((input) => signupSchema.parse(input)).handler(createSsrRpc("608745bb459720619a94d10a6e3bb42f54aa016ac1fb9c227451b745add0e540"));
var verifySignInOtp = createServerFn({ method: "POST" }).validator((input) => verifySchema.parse(input)).handler(createSsrRpc("86c360a3410e5d9d7970f27d9fd909595fa0a33751ac31b1a62c92a0dfdb84be"));
var verifySignUpOtp = createServerFn({ method: "POST" }).validator((input) => verifySignupSchema.parse(input)).handler(createSsrRpc("59079731bf03f9a8585d9cec8d6c6f695db0d66e5ee6aba0348419c557e3c85e"));
var EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
function OtpAuthForm({ onSuccess, defaultMode = "signup" }) {
	const [mode, setMode] = (0, import_react.useState)(defaultMode);
	const [step, setStep] = (0, import_react.useState)("email");
	const [email, setEmail] = (0, import_react.useState)("");
	const [fullName, setFullName] = (0, import_react.useState)("");
	const [username, setUsername] = (0, import_react.useState)("");
	const [code, setCode] = (0, import_react.useState)("");
	const [busy, setBusy] = (0, import_react.useState)(false);
	const [cooldown, setCooldown] = (0, import_react.useState)(0);
	const [notice, setNotice] = (0, import_react.useState)(null);
	const requestSignIn = useServerFn(requestSignInOtp);
	const requestSignUp = useServerFn(requestSignUpOtp);
	const verifySignIn = useServerFn(verifySignInOtp);
	const verifySignUp = useServerFn(verifySignUpOtp);
	(0, import_react.useEffect)(() => {
		if (cooldown <= 0) return;
		const t = setInterval(() => setCooldown((s) => s <= 1 ? 0 : s - 1), 1e3);
		return () => clearInterval(t);
	}, [cooldown]);
	const resetTransient = (0, import_react.useCallback)(() => {
		setStep("email");
		setCode("");
		setBusy(false);
		setCooldown(0);
		setNotice(null);
	}, []);
	function switchMode(next) {
		setMode(next);
		resetTransient();
	}
	function onEmailChange(next) {
		setEmail(next);
		if (step !== "email") setStep("email");
		if (code) setCode("");
		if (cooldown > 0) setCooldown(0);
		if (notice) setNotice(null);
		if (busy) setBusy(false);
	}
	const trimmedEmail = email.trim().toLowerCase();
	const emailValid = EMAIL_RE.test(trimmedEmail);
	const signupValid = mode !== "signup" || fullName.trim().length >= 2 && /^[a-z0-9_]{3,24}$/.test(username.trim().toLowerCase());
	const canSubmitEmail = emailValid && signupValid && !busy;
	function parseTaggedError(err, fallback) {
		const raw = err instanceof Error ? err.message : String(err ?? "");
		if (raw.startsWith("ACCOUNT_EXISTS:")) {
			toast.error("Account already exists! Please Log In.");
			setMode("login");
			setStep("email");
			setCode("");
			setNotice({
				kind: "account_exists",
				message: "Account already exists — please log in."
			});
			return;
		}
		if (raw.startsWith("NO_ACCOUNT:")) {
			toast.error("No account found with this email. Please Sign Up first!");
			setMode("signup");
			setStep("email");
			setCode("");
			setNotice({
				kind: "no_account",
				message: "No account found — create one to continue."
			});
			return;
		}
		if (raw.startsWith("USERNAME_TAKEN:")) {
			const msg = raw.slice(15);
			setNotice({
				kind: "info",
				message: msg
			});
			toast.error(msg);
			return;
		}
		toast.error(friendlyError(err, fallback));
	}
	async function sendCode(isResend = false) {
		if (busy) return;
		const trimmed = trimmedEmail;
		if (!EMAIL_RE.test(trimmed)) {
			toast.error("Enter a valid email address");
			return;
		}
		const normalizedUsername = username.trim().toLowerCase();
		if (mode === "signup") {
			if (fullName.trim().length < 2) {
				toast.error("Enter your full name");
				return;
			}
			if (!/^[a-z0-9_]{3,24}$/.test(normalizedUsername)) {
				toast.error("Username: 3–24 chars, lowercase letters, numbers or underscores");
				return;
			}
		}
		if (cooldown > 0) return;
		setBusy(true);
		setNotice(null);
		try {
			const res = mode === "signup" ? await requestSignUp({ data: {
				email: trimmed,
				full_name: fullName.trim(),
				username: normalizedUsername
			} }) : await requestSignIn({ data: { email: trimmed } });
			if (!res?.success) {
				const code = res?.code;
				const message = res?.message ?? "Couldn't send security code. Please try again.";
				if (code === "ACCOUNT_EXISTS") {
					toast.error("Account already exists! Please Log In.");
					setMode("login");
					setStep("email");
					setCode("");
					setNotice({
						kind: "account_exists",
						message: "Account already exists — please log in."
					});
					return;
				}
				if (code === "NO_ACCOUNT") {
					toast.error("No account found with this email. Please Sign Up first!");
					setMode("signup");
					setStep("email");
					setCode("");
					setNotice({
						kind: "no_account",
						message: "No account found — create one to continue."
					});
					return;
				}
				if (code === "USERNAME_TAKEN") {
					setNotice({
						kind: "info",
						message
					});
					toast.error(message);
					return;
				}
				toast.error(message);
				return;
			}
			toast.success(isResend ? "New code sent. Check your inbox and spam folder." : "Security code sent. Check your inbox and spam folder.");
			setStep("code");
			setCooldown(60);
		} catch (err) {
			console.error("Send OTP error:", err);
			parseTaggedError(err, "Couldn't send security code. Please try again.");
		} finally {
			setBusy(false);
		}
	}
	async function verify(e) {
		e.preventDefault();
		if (busy) return;
		if (!/^\d{6}$/.test(code)) {
			toast.error("Enter the 6-digit code sent to your email.");
			return;
		}
		setBusy(true);
		try {
			const payload = {
				email: trimmedEmail,
				code
			};
			const { token_hash } = mode === "signup" ? await verifySignUp({ data: {
				...payload,
				full_name: fullName.trim(),
				username: username.trim().toLowerCase()
			} }) : await verifySignIn({ data: payload });
			const { error } = await supabase.auth.verifyOtp({
				type: "magiclink",
				token_hash
			});
			if (error) throw error;
			toast.success(mode === "signup" ? "Welcome to tribeX!" : "You're signed in!");
			onSuccess();
		} catch (err) {
			console.error("Verify OTP error:", err);
			parseTaggedError(err, "Couldn't verify code. Please try again.");
		} finally {
			setBusy(false);
		}
	}
	if (step === "email") return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "mx-auto flex w-full max-w-md flex-col gap-3 antialiased",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mb-1",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "text-xl font-bold tracking-tight",
					children: mode === "signup" ? "Create your account" : "Welcome back"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-0.5 text-xs text-muted-foreground",
					children: mode === "signup" ? "Join tribeX — we'll email you a one-time code." : "Log in with a one-time code sent to your email."
				})]
			}),
			mode === "signup" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_jsx_runtime.Fragment, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3 transition focus-within:border-primary",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(User, { className: "h-4 w-4 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
					type: "text",
					value: fullName,
					onChange: (e) => setFullName(e.target.value),
					placeholder: "Full name",
					autoComplete: "name",
					maxLength: 80,
					className: "w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
				})]
			}) }),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3 transition focus-within:border-primary",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Mail, { className: "h-4 w-4 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
					type: "email",
					value: email,
					onChange: (e) => onEmailChange(e.target.value),
					placeholder: "Email address",
					autoComplete: "email",
					inputMode: "email",
					spellCheck: false,
					autoCapitalize: "none",
					className: "w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
				})]
			}),
			mode === "signup" && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3 transition focus-within:border-primary",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(AtSign, { className: "h-4 w-4 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
					type: "text",
					value: username,
					onChange: (e) => setUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, "").slice(0, 24)),
					placeholder: "Username",
					autoComplete: "username",
					maxLength: 24,
					className: "w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
				})]
			}),
			notice && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: `antialiased flex items-center gap-3 rounded-xl border p-4 ${notice.kind === "account_exists" || notice.kind === "no_account" ? "border-destructive/30 bg-destructive/10" : "border-primary/30 bg-primary/5"}`,
				children: [
					(notice.kind === "account_exists" || notice.kind === "no_account") && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TriangleAlert, { className: "h-5 w-5 flex-shrink-0 text-destructive" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "min-w-0 flex-1",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: `text-sm font-semibold ${notice.kind === "account_exists" || notice.kind === "no_account" ? "text-destructive" : "text-foreground"}`,
							children: notice.message
						})
					}),
					notice.kind === "account_exists" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						type: "button",
						onClick: () => switchMode("login"),
						className: "flex-shrink-0 rounded-lg bg-primary px-4 py-2 text-xs font-semibold text-primary-foreground shadow-sm transition-all hover:opacity-90 whitespace-nowrap",
						children: "Log In instead"
					}),
					notice.kind === "no_account" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						type: "button",
						onClick: () => switchMode("signup"),
						className: "flex-shrink-0 rounded-lg bg-primary px-4 py-2 text-xs font-semibold text-primary-foreground shadow-sm transition-all hover:opacity-90 whitespace-nowrap",
						children: "Sign Up instead"
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
				type: "button",
				onClick: () => sendCode(false),
				disabled: !canSubmitEmail,
				className: "flex items-center justify-center gap-2 rounded-2xl bg-primary py-3.5 text-sm font-semibold text-primary-foreground shadow-sm transition active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50",
				children: [busy && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-4 w-4 animate-spin" }), busy ? "Sending…" : mode === "signup" ? "Sign Up & Get OTP" : "Log In with OTP"]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "text-center text-xs text-muted-foreground",
				children: mode === "signup" ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
					"Already have an account?",
					" ",
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						type: "button",
						onClick: () => switchMode("login"),
						className: "font-semibold text-primary hover:underline",
						children: "Log In"
					})
				] }) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
					"New to tribeX?",
					" ",
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						type: "button",
						onClick: () => switchMode("signup"),
						className: "font-semibold text-primary hover:underline",
						children: "Create an Account"
					})
				] })
			})
		]
	});
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
		onSubmit: verify,
		className: "mx-auto flex w-full max-w-md flex-col gap-3 antialiased",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
				type: "button",
				onClick: resetTransient,
				className: "mb-1 flex items-center gap-1 self-start text-xs font-medium text-muted-foreground transition hover:text-foreground",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowLeft, { className: "h-3 w-3" }), " Change email"]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center gap-2 rounded-2xl border border-primary/30 bg-primary/5 px-4 py-3 text-xs text-muted-foreground",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShieldCheck, { className: "h-4 w-4 text-primary" }),
					"Code sent to ",
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						className: "truncate font-semibold text-foreground",
						children: email
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
				inputMode: "numeric",
				pattern: "\\d{6}",
				maxLength: 6,
				autoFocus: true,
				value: code,
				onChange: (e) => setCode(e.target.value.replace(/\D/g, "").slice(0, 6)),
				placeholder: "6-digit code",
				className: "w-full rounded-2xl border border-border/60 bg-card px-4 py-4 text-center text-2xl font-semibold tracking-[0.6em] outline-none focus:border-primary"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
				type: "submit",
				disabled: busy || code.length !== 6,
				className: "flex items-center justify-center gap-2 rounded-2xl bg-primary py-3.5 text-sm font-semibold text-primary-foreground shadow-sm transition active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50",
				children: [busy && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-4 w-4 animate-spin" }), busy ? "Verifying…" : "Verify & sign in"]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
				type: "button",
				onClick: () => sendCode(true),
				disabled: busy || cooldown > 0,
				className: "text-center text-xs font-medium text-muted-foreground transition hover:text-foreground disabled:opacity-60",
				children: cooldown > 0 ? `Resend code in ${cooldown}s` : "Resend code"
			})
		]
	});
}
/**
* Unified loading primitives for tribeX. All async surfaces should render one
* of these so users see the same animation, timing, and colour treatment.
*/
function Spinner({ className, size = 16 }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, {
		"aria-hidden": "true",
		style: {
			width: size,
			height: size
		},
		className: cn("animate-spin text-primary", className)
	});
}
/** Full-viewport loader used for route transitions and Suspense fallbacks. */
function PageLoader({ label = "Loading" }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		role: "status",
		"aria-live": "polite",
		className: "flex min-h-[60vh] w-full flex-col items-center justify-center gap-3 px-6 text-center animate-fade-in",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
			className: "flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Spinner, { size: 22 })
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
			className: "text-sm font-medium text-muted-foreground",
			children: [label, "…"]
		})]
	});
}
var Route$8 = createFileRoute("/auth")({
	head: () => ({ meta: [{ title: "Sign in · tribeX" }] }),
	component: AuthPage
});
function AuthPage() {
	const navigate = useNavigate();
	const { user, loading } = useAuth();
	const [busy, setBusy] = (0, import_react.useState)(false);
	(0, import_react.useEffect)(() => {
		if (!loading && user) navigate({ to: "/" });
	}, [
		user,
		loading,
		navigate
	]);
	if (loading || user) return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PageLoader, { label: "Checking session" });
	async function onGoogle() {
		setBusy(true);
		try {
			const { error } = await supabase.auth.signInWithOAuth({
				provider: "google",
				options: { redirectTo: `${window.location.origin}` }
			});
			if (error) {
				toast.error(error.message ?? "Google sign-in failed");
				setBusy(false);
			}
		} catch (err) {
			toast.error(friendlyError(err, "Google sign-in failed"));
			setBusy(false);
		}
	}
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex min-h-[80vh] flex-col justify-center gap-6 px-5 pt-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", { children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground",
					children: "Get started"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h1", {
					className: "mt-1 text-3xl font-bold tracking-tight",
					children: [
						"Join ",
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-primary",
							children: "tribe"
						}),
						"X"
					]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-1 text-sm text-muted-foreground",
					children: "Passwordless — we'll email you a one-time code."
				})
			] }),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
				onClick: onGoogle,
				disabled: busy,
				className: "flex w-full items-center justify-center gap-3 rounded-2xl border border-border/60 bg-card py-3 text-sm font-semibold transition hover:bg-accent active:scale-[0.98] disabled:opacity-60",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(GoogleIcon, { className: "h-5 w-5" }), "Continue with Google"]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center gap-3 text-[11px] uppercase tracking-wider text-muted-foreground",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-px flex-1 bg-border/60" }),
					" or ",
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-px flex-1 bg-border/60" })
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(OtpAuthForm, {
				defaultMode: "signup",
				onSuccess: () => navigate({ to: "/" })
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
				className: "text-center text-[11px] leading-relaxed text-muted-foreground",
				children: [
					"By continuing you agree to our",
					" ",
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
						to: "/terms-and-policies",
						className: "font-semibold text-primary hover:underline",
						children: "Terms & Privacy Policy"
					}),
					"."
				]
			})
		]
	});
}
var Route$7 = createFileRoute("/complete-profile")({
	head: () => ({ meta: [{ title: "Complete your profile · tribeX" }, {
		name: "description",
		content: "Set your name, handle and city to start joining plans on tribeX."
	}] }),
	component: CompleteProfile
});
var usernameRegex = /^[a-zA-Z0-9_]{3,20}$/;
var schema = objectType({
	full_name: stringType().trim().min(2, "Full name must be at least 2 characters").max(80),
	username: stringType().trim().regex(usernameRegex, "3–20 letters, numbers, or underscores"),
	city: stringType().trim().min(2, "Pick your city").max(80),
	bio: stringType().trim().max(200).optional()
});
function CompleteProfile() {
	const { user, loading } = useAuth();
	const navigate = useNavigate();
	const qc = useQueryClient();
	const [fullName, setFullName] = (0, import_react.useState)("");
	const [username, setUsername] = (0, import_react.useState)("");
	const [city, setCity] = (0, import_react.useState)("");
	const [coords, setCoords] = (0, import_react.useState)(null);
	const [bio, setBio] = (0, import_react.useState)("");
	const [avatarUrl, setAvatarUrl] = (0, import_react.useState)(null);
	const [avatarUploading, setAvatarUploading] = (0, import_react.useState)(false);
	const [saving, setSaving] = (0, import_react.useState)(false);
	const [usernameState, setUsernameState] = (0, import_react.useState)({ status: "idle" });
	const [profileLoading, setProfileLoading] = (0, import_react.useState)(true);
	const fileRef = (0, import_react.useRef)(null);
	(0, import_react.useEffect)(() => {
		if (!loading && !user) navigate({
			to: "/auth",
			replace: true
		});
	}, [
		loading,
		user,
		navigate
	]);
	(0, import_react.useEffect)(() => {
		if (!user) {
			setProfileLoading(false);
			return;
		}
		getProfile(user.id).then((p) => {
			if (!p) {
				setProfileLoading(false);
				return;
			}
			if (p.has_completed_profile) {
				navigate({
					to: "/",
					replace: true
				});
				return;
			}
			const emailPrefix = user.email ? user.email.split("@")[0] : "";
			if (p.full_name && p.full_name !== emailPrefix) setFullName(p.full_name);
			if (p.username && p.username !== emailPrefix) setUsername(p.username);
			if (p.city) setCity(p.city);
			const pp = p;
			if (pp.latitude != null && pp.longitude != null) setCoords({
				lat: pp.latitude,
				lon: pp.longitude
			});
			if (p.bio) setBio(p.bio);
			if (p.avatar_url) setAvatarUrl(p.avatar_url);
			setProfileLoading(false);
		}).catch(() => {
			setProfileLoading(false);
		});
	}, [user, navigate]);
	(0, import_react.useEffect)(() => {
		const trimmed = username.trim();
		if (!trimmed) {
			setUsernameState({ status: "idle" });
			return;
		}
		if (!usernameRegex.test(trimmed)) {
			setUsernameState({
				status: "invalid",
				message: "3–20 letters, numbers, or underscores"
			});
			return;
		}
		setUsernameState({ status: "checking" });
		const handle = setTimeout(async () => {
			try {
				const ok = await isUsernameAvailable(trimmed, user?.id);
				setUsernameState({ status: ok ? "available" : "taken" });
			} catch {
				setUsernameState({ status: "idle" });
			}
		}, 350);
		return () => clearTimeout(handle);
	}, [username, user?.id]);
	async function onPickAvatar(e) {
		const file = e.target.files?.[0];
		e.target.value = "";
		if (!file || !user) return;
		if (![
			"image/jpeg",
			"image/png",
			"image/webp"
		].includes(file.type)) {
			toast.error("Use a JPG, PNG or WEBP image");
			return;
		}
		if (file.size > 5 * 1024 * 1024) {
			toast.error("Image must be under 5MB");
			return;
		}
		setAvatarUploading(true);
		try {
			const url = await uploadAvatar(user.id, file);
			setAvatarUrl(url);
			toast.success("Photo uploaded");
		} catch (err) {
			toast.error(friendlyError(err));
		} finally {
			setAvatarUploading(false);
		}
	}
	async function handleSubmit(e) {
		e.preventDefault();
		if (!user) return;
		const parsed = schema.safeParse({
			full_name: fullName,
			username,
			city,
			bio
		});
		if (!parsed.success) {
			toast.error(parsed.error.issues[0]?.message ?? "Please fix the highlighted fields");
			return;
		}
		if (usernameState.status === "taken") {
			toast.error("That username is already taken");
			return;
		}
		if (usernameState.status === "invalid") {
			toast.error(usernameState.message);
			return;
		}
		if (usernameState.status === "checking") {
			toast.error("Checking username, please wait…");
			return;
		}
		setSaving(true);
		try {
			if (!await isUsernameAvailable(parsed.data.username, user.id)) {
				setUsernameState({ status: "taken" });
				toast.error("That username was just taken — pick another");
				return;
			}
			await updateProfile(user.id, {
				full_name: parsed.data.full_name,
				username: parsed.data.username,
				city: parsed.data.city,
				bio: parsed.data.bio?.trim() || null,
				has_completed_profile: true,
				...coords ? {
					latitude: coords.lat,
					longitude: coords.lon
				} : {}
			});
			await qc.invalidateQueries({ queryKey: ["profile", user.id] });
			await qc.invalidateQueries({ queryKey: ["onboarding-status", user.id] });
			toast.success("Welcome to tribeX 🎉");
			navigate({
				to: "/",
				replace: true
			});
		} catch (err) {
			toast.error(friendlyError(err));
		} finally {
			setSaving(false);
		}
	}
	if (loading || user && profileLoading) return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PageLoader, { label: "Checking profile status" });
	const initial = (fullName || user?.email || "U")[0]?.toUpperCase() ?? "U";
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex min-h-screen flex-col gap-6 px-5 pb-10 pt-10",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", {
			className: "flex flex-col gap-2",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/15 text-primary",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkles, { className: "h-6 w-6" })
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
					className: "text-3xl font-bold tracking-tight",
					children: "Complete your profile"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-sm text-muted-foreground",
					children: "Just a few details so your squad knows who they're meeting."
				})
			]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
			onSubmit: handleSubmit,
			className: "flex flex-col gap-5",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center gap-4",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "relative shrink-0",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "flex h-20 w-20 items-center justify-center overflow-hidden rounded-full bg-primary text-2xl font-bold text-primary-foreground",
								children: avatarUrl ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
									src: avatarUrl,
									alt: "",
									className: "h-full w-full object-cover"
								}) : initial
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: () => fileRef.current?.click(),
								disabled: avatarUploading,
								className: "absolute -bottom-1 -right-1 flex h-8 w-8 items-center justify-center rounded-full border border-border bg-background text-foreground shadow transition hover:scale-105 active:scale-95 disabled:opacity-60",
								"aria-label": "Upload photo",
								children: avatarUploading ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-4 w-4 animate-spin" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Camera, { className: "h-4 w-4" })
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
								ref: fileRef,
								type: "file",
								accept: "image/jpeg,image/png,image/webp",
								className: "hidden",
								onChange: onPickAvatar
							})
						]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-sm font-semibold",
						children: "Profile photo"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs text-muted-foreground",
						children: "Optional · JPG, PNG or WEBP up to 5MB"
					})] })]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
					className: "flex flex-col gap-1.5",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
						className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
						children: ["Full name ", /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-destructive",
							children: "*"
						})]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center gap-2 rounded-2xl border border-border/60 bg-card px-3 focus-within:border-primary",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(User, { className: "h-4 w-4 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
							value: fullName,
							onChange: (e) => setFullName(e.target.value),
							maxLength: 80,
							required: true,
							placeholder: "Ananya Rao",
							className: "w-full bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground"
						})]
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
					className: "flex flex-col gap-1.5",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
							className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
							children: ["Username ", /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-destructive",
								children: "*"
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: `flex items-center gap-2 rounded-2xl border bg-card px-3 focus-within:border-primary ${usernameState.status === "taken" || usernameState.status === "invalid" ? "border-destructive/60" : usernameState.status === "available" ? "border-green-500/60" : "border-border/60"}`,
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)(AtSign, { className: "h-4 w-4 text-muted-foreground" }),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
									value: username,
									onChange: (e) => setUsername(e.target.value.replace(/\s+/g, "")),
									maxLength: 20,
									required: true,
									placeholder: "ananya_r",
									autoCapitalize: "off",
									autoCorrect: "off",
									spellCheck: false,
									className: "w-full bg-transparent py-3 text-sm lowercase outline-none placeholder:text-muted-foreground"
								}),
								usernameState.status === "checking" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-4 w-4 animate-spin text-muted-foreground" }),
								usernameState.status === "available" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "h-4 w-4 text-green-500" }),
								(usernameState.status === "taken" || usernameState.status === "invalid") && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4 text-destructive" })
							]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
							className: "min-h-[1rem] text-[11px]",
							children: [
								usernameState.status === "available" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "text-green-600 dark:text-green-400",
									children: "Available"
								}),
								usernameState.status === "taken" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "text-destructive",
									children: "That username is already taken"
								}),
								usernameState.status === "invalid" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "text-destructive",
									children: usernameState.message
								}),
								usernameState.status === "idle" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "text-muted-foreground",
									children: "3–20 letters, numbers or underscores"
								})
							]
						})
					]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex flex-col gap-1.5",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
						className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
						children: ["City ", /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-destructive",
							children: "*"
						})]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center gap-2 rounded-2xl border border-border/60 bg-card px-3 focus-within:border-primary",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, { className: "h-4 w-4 shrink-0 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "flex-1 py-1.5",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PlaceSearch, {
								variant: "input",
								value: city,
								placeholder: "Search your city or pincode",
								onSelect: (p) => {
									setCity(p.short || p.city || "");
									setCoords({
										lat: p.lat,
										lon: p.lon
									});
								}
							})
						})]
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
					className: "flex flex-col gap-1.5",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
							className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
							children: ["Short bio ", /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-muted-foreground/70",
								children: "(optional)"
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", {
							value: bio,
							onChange: (e) => setBio(e.target.value),
							maxLength: 200,
							rows: 3,
							placeholder: "Weekend cricketer, coffee snob, always down for a trek.",
							className: "resize-none rounded-2xl border border-border/60 bg-card px-3 py-3 text-sm outline-none placeholder:text-muted-foreground focus:border-primary"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
							className: "text-right text-[10px] text-muted-foreground",
							children: [bio.length, "/200"]
						})
					]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					type: "submit",
					disabled: saving || usernameState.status === "checking",
					className: "mt-2 w-full rounded-2xl bg-primary py-4 text-sm font-semibold text-primary-foreground shadow-lg transition hover:scale-[1.01] active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-50",
					children: saving ? "Saving…" : "Continue"
				})
			]
		})]
	});
}
var inputSchema = objectType({ activityId: stringType().uuid() });
var notifyMatchingUsersPush = createServerFn({ method: "POST" }).middleware([requireSupabaseAuth]).validator((input) => inputSchema.parse(input)).handler(createSsrRpc("6f633a35e95c4fa3aa8de5b5d4fdfdca34939b6f119e9f5f97b744d22b19e44d"));
var Route$6 = createFileRoute("/create")({
	head: () => ({ meta: [{ title: "Host a plan · tribeX" }, {
		name: "description",
		content: "Post a plan and let your squad find you."
	}] }),
	component: Create
});
var planSchema = objectType({
	title: stringType().trim().min(4, { message: "Title must be at least 4 characters" }).max(80, { message: "Keep it under 80 characters" }),
	description: stringType().trim().min(10, { message: "Add a bit more detail (10+ chars)" }).max(500, { message: "Keep it under 500 characters" }),
	category: stringType().min(1, { message: "Pick a category" }),
	date: stringType().min(1, { message: "Pick a date" }),
	time: stringType().min(1, { message: "Pick a time" }),
	location: stringType().trim().max(120, { message: "Keep location under 120 characters" }).optional().default(""),
	is_online: booleanType(),
	meeting_link: stringType().trim().max(500, { message: "Link is too long" }).optional().default(""),
	slots: numberType({ message: "Slots is required" }).int({ message: "Whole numbers only" }).gt(0, { message: "Slots must be greater than 0" }).max(50, { message: "Max 50 slots" }),
	cost: numberType({ message: "Cost is required" }).min(0, { message: "Cost cannot be negative" }).max(1e5, { message: "That looks too high" }),
	topic_tags: stringType().trim().max(120).optional().default("")
}).superRefine((val, ctx) => {
	if (val.is_online) {
		const url = val.meeting_link ?? "";
		if (!/^https?:\/\/\S+$/i.test(url)) ctx.addIssue({
			code: ZodIssueCode.custom,
			path: ["meeting_link"],
			message: "Add a valid meeting URL (Meet, Discord, Zoom…)"
		});
	} else if ((val.location ?? "").trim().length < 3) ctx.addIssue({
		code: ZodIssueCode.custom,
		path: ["location"],
		message: "Add a venue or area (at least 3 characters)"
	});
});
var empty = {
	title: "",
	description: "",
	category: "",
	date: "",
	time: "",
	location: "",
	slots: "8",
	cost: "0",
	is_online: false,
	meeting_link: "",
	topic_tags: ""
};
var STEP_TITLES = [
	"What & when",
	"Where & who",
	"Details & preview"
];
function Create() {
	const { user, loading } = useAuth();
	const navigate = useNavigate();
	const qc = useQueryClient();
	const [currentStep, setCurrentStep] = (0, import_react.useState)(0);
	const [form, setForm] = (0, import_react.useState)(empty);
	const [errors, setErrors] = (0, import_react.useState)({});
	const fileRef = (0, import_react.useRef)(null);
	const [imageFile, setImageFile] = (0, import_react.useState)(null);
	const [imagePreview, setImagePreview] = (0, import_react.useState)(null);
	const [uploading, setUploading] = (0, import_react.useState)(false);
	const [pinnedPlace, setPinnedPlace] = (0, import_react.useState)(null);
	const [womenOnly, setWomenOnly] = (0, import_react.useState)(false);
	const [verifiedOnly, setVerifiedOnly] = (0, import_react.useState)(false);
	const [amenities, setAmenities] = (0, import_react.useState)([]);
	const [groupFilter, setGroupFilter] = (0, import_react.useState)("Sports & Outdoor");
	const mutation = useMutation({
		mutationFn: createActivity,
		onSuccess: (created) => {
			qc.invalidateQueries({ queryKey: ["activities"] });
			qc.invalidateQueries({ queryKey: ["user-activities", user?.id] });
			qc.invalidateQueries({ queryKey: ["user-stats", user?.id] });
			qc.invalidateQueries({ queryKey: ["chats", user?.id] });
			qc.invalidateQueries({ queryKey: ["profile", user?.id] });
			setForm(empty);
			setErrors({});
			setImageFile(null);
			setImagePreview(null);
			setCurrentStep(0);
			toast.success("Plan published — your squad will find you.");
			if (created?.id) notifyMatchingUsersPush({ data: { activityId: created.id } }).catch((e) => console.warn("[push] dispatch failed", e));
			navigate({ to: "/" });
		},
		onError: (e) => toast.error(e.message)
	});
	const set = (key, value) => {
		setForm((f) => ({
			...f,
			[key]: value
		}));
		if (errors[key]) setErrors((e) => ({
			...e,
			[key]: void 0
		}));
	};
	function toggleAmenity(key) {
		setAmenities((prev) => prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key]);
	}
	const selectedCategoryDef = form.category ? CATEGORY_MAP[form.category] : null;
	const isIndoorCategory = selectedCategoryDef?.group === "Education & Skills" || selectedCategoryDef?.group === "Tech & Creative";
	function onPickImage(e) {
		const file = e.target.files?.[0];
		e.target.value = "";
		if (!file) return;
		if (!file.type.startsWith("image/")) {
			toast.error("Pick an image file");
			return;
		}
		if (file.size > 5 * 1024 * 1024) {
			toast.error("Image must be under 5MB");
			return;
		}
		setImageFile(file);
		setImagePreview(URL.createObjectURL(file));
	}
	function clearImage() {
		if (imagePreview) URL.revokeObjectURL(imagePreview);
		setImageFile(null);
		setImagePreview(null);
	}
	function validateStep1() {
		const errs = {};
		if (!form.category) errs.category = "Please select a category";
		if (form.title.trim().length < 4) errs.title = "Title must be at least 4 characters";
		if (form.description.trim().length < 10) errs.description = "Add a bit more detail (10+ characters)";
		if (!form.date) errs.date = "Pick a date";
		if (!form.time) errs.time = "Pick a time";
		setErrors(errs);
		if (Object.keys(errs).length > 0) {
			toast.error("Please fill in the required fields to continue");
			return false;
		}
		return true;
	}
	function validateStep2() {
		const errs = {};
		const slotsNum = Number(form.slots);
		if (isNaN(slotsNum) || slotsNum < 1 || slotsNum > 50) errs.slots = "Slots must be between 1 and 50";
		if (form.is_online) {
			const link = form.meeting_link.trim();
			if (!link) errs.meeting_link = "Meeting link is required for virtual plans";
			else if (!/^https?:\/\/\S+$/i.test(link)) errs.meeting_link = "Enter a valid URL (https://...)";
		} else if (form.location.trim().length < 3) errs.location = "Add a venue or area (at least 3 characters)";
		setErrors(errs);
		if (Object.keys(errs).length > 0) {
			toast.error("Please fix the highlighted fields to continue");
			return false;
		}
		return true;
	}
	const onSubmit = async () => {
		if (!user) {
			navigate({ to: "/auth" });
			return;
		}
		if (!validateStep1()) {
			setCurrentStep(0);
			return;
		}
		if (!validateStep2()) {
			setCurrentStep(1);
			return;
		}
		const parsed = planSchema.safeParse({
			...form,
			slots: Number(form.slots),
			cost: Number(form.cost)
		});
		if (!parsed.success) {
			const fieldErrors = {};
			for (const issue of parsed.error.issues) {
				const key = issue.path[0];
				if (!fieldErrors[key]) fieldErrors[key] = issue.message;
			}
			setErrors(fieldErrors);
			toast.error("Please fix the highlighted fields");
			return;
		}
		const p = parsed.data;
		const cleanTags = p.topic_tags ? p.topic_tags.split(",").map((t) => t.trim()).filter(Boolean).slice(0, 8) : [];
		let image_url = null;
		if (imageFile) {
			setUploading(true);
			try {
				image_url = await uploadActivityImage(user.id, imageFile);
			} catch (err) {
				setUploading(false);
				toast.error(err instanceof Error ? err.message : "Couldn't upload photo");
				return;
			}
			setUploading(false);
		}
		const safeTime = p.time.length === 5 ? `${p.time}:00` : p.time;
		let finalLat = null;
		let finalLon = null;
		if (!p.is_online) {
			if (pinnedPlace?.lat != null && pinnedPlace?.lon != null) {
				finalLat = pinnedPlace.lat;
				finalLon = pinnedPlace.lon;
			} else if (p.location.trim()) try {
				const geocoded = await searchPlaces(p.location.trim());
				if (geocoded.length > 0) {
					finalLat = geocoded[0].lat;
					finalLon = geocoded[0].lon;
				}
			} catch {}
			if (finalLat == null || finalLon == null) {
				finalLat = DEFAULT_LAT;
				finalLon = DEFAULT_LON;
			}
		}
		mutation.mutate({
			title: p.title,
			description: p.description,
			category: p.category,
			date_time: (/* @__PURE__ */ new Date(`${p.date}T${safeTime}`)).toISOString(),
			location: p.is_online ? p.location.trim() || "Online" : p.location,
			total_slots: p.slots,
			cost_per_head: p.cost,
			image_url: image_url ?? "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&auto=format&fit=crop&q=80",
			latitude: p.is_online ? null : finalLat,
			longitude: p.is_online ? null : finalLon,
			women_only: womenOnly,
			verified_only: verifiedOnly,
			is_online: p.is_online,
			meeting_link: p.is_online ? p.meeting_link.trim() : null,
			amenities: p.is_online ? [] : amenities,
			topic_tags: cleanTags
		});
	};
	if (!loading && !user) return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex flex-col items-start gap-4 px-5 pt-8",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
				className: "text-2xl font-bold tracking-tight",
				children: "Sign in to host a plan"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "text-sm text-muted-foreground",
				children: "Create a free account so your squad can find and join your plans."
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
				onClick: () => navigate({ to: "/auth" }),
				className: "rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground",
				children: "Continue"
			})
		]
	});
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex flex-col gap-5 px-5 pt-6 pb-28",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", { children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
					className: "text-2xl font-bold tracking-tight",
					children: "Host a plan"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
					className: "mt-1 text-xs font-medium text-muted-foreground",
					children: [
						"Step ",
						currentStep + 1,
						" of 3 · ",
						STEP_TITLES[currentStep]
					]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "mt-3 flex items-center gap-1.5",
					children: STEP_TITLES.map((_, idx) => {
						return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: `h-1.5 flex-1 rounded-full transition-all duration-300 ${idx === currentStep ? "bg-primary" : idx < currentStep ? "bg-primary/50" : "bg-secondary"}` }, idx);
					})
				})
			] }),
			currentStep === 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col gap-4 animate-in fade-in duration-200",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
							icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Tag, { className: "h-3.5 w-3.5" }),
							children: "Select Category"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "-mx-5 mt-2 flex gap-1.5 overflow-x-auto px-5 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden",
							children: CATEGORY_GROUPS.map((g) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: () => setGroupFilter(g),
								className: `shrink-0 rounded-full border px-3 py-1 text-[11px] font-semibold uppercase tracking-wider transition ${groupFilter === g ? "border-primary/60 bg-primary/10 text-primary" : "border-border/60 bg-card text-muted-foreground"}`,
								children: g
							}, g))
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "-mx-5 mt-2 flex gap-2 overflow-x-auto px-5 pb-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden",
							children: CATEGORIES.filter((c) => c.group === groupFilter).map((c) => {
								const active = form.category === c.key;
								const Icon = c.icon;
								return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
									type: "button",
									onClick: () => {
										set("category", c.key);
										if (c.defaultMode === "online" && !form.is_online) set("is_online", true);
										if (c.defaultMode === "in_person" && form.is_online) set("is_online", false);
									},
									className: `flex shrink-0 items-center gap-1.5 rounded-full border px-3.5 py-2 text-xs font-medium transition ${active ? "border-primary bg-primary text-primary-foreground" : "border-border/60 bg-card text-muted-foreground hover:border-primary/50"}`,
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Icon, { className: "h-3.5 w-3.5" }), c.label]
								}, c.key);
							})
						}),
						errors.category && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "mt-1.5 text-[11px] font-medium text-destructive",
							children: errors.category
						})
					] }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Field, {
						label: "Plan Title",
						icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Type, { className: "h-3.5 w-3.5" }),
						error: errors.title,
						hint: `${form.title.length}/80`,
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
							value: form.title,
							onChange: (e) => set("title", e.target.value),
							maxLength: 80,
							placeholder: "e.g. Weekend Box Cricket Turf Match",
							className: "w-full bg-transparent text-sm font-medium outline-none placeholder:text-muted-foreground"
						})
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Field, {
						label: "Description",
						icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TextAlignStart, { className: "h-3.5 w-3.5" }),
						error: errors.description,
						hint: `${form.description.length}/500`,
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", {
							value: form.description,
							onChange: (e) => set("description", e.target.value),
							maxLength: 500,
							rows: 3,
							placeholder: "Tell attendees what to expect, skill level, what to bring, etc.",
							className: "w-full resize-none bg-transparent text-xs outline-none placeholder:text-muted-foreground"
						})
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "grid grid-cols-2 gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Field, {
							label: "Date",
							icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Calendar, { className: "h-3.5 w-3.5" }),
							error: errors.date,
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
								type: "date",
								value: form.date,
								onChange: (e) => set("date", e.target.value),
								className: "w-full bg-transparent text-xs outline-none [color-scheme:light] dark:[color-scheme:dark]"
							})
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Field, {
							label: "Time",
							icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Clock, { className: "h-3.5 w-3.5" }),
							error: errors.time,
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
								type: "time",
								value: form.time,
								onChange: (e) => set("time", e.target.value),
								className: "w-full bg-transparent text-xs outline-none [color-scheme:light] dark:[color-scheme:dark]"
							})
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
							icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Image$1, { className: "h-3.5 w-3.5" }),
							children: "Cover Photo (Optional)"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
							ref: fileRef,
							type: "file",
							accept: "image/*",
							className: "hidden",
							onChange: onPickImage
						}),
						imagePreview ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "relative mt-2 overflow-hidden rounded-2xl border border-border/60",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
								src: imagePreview,
								alt: "Cover preview",
								className: "h-40 w-full object-cover"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: clearImage,
								className: "absolute right-2 top-2 flex h-7 w-7 items-center justify-center rounded-full bg-background/90 shadow transition hover:scale-105 active:scale-95",
								"aria-label": "Remove photo",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-3.5 w-3.5" })
							})]
						}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							type: "button",
							onClick: () => fileRef.current?.click(),
							className: "mt-2 flex h-28 w-full items-center justify-center rounded-2xl border border-dashed border-border bg-card/50 text-muted-foreground transition hover:border-primary/60 hover:text-primary active:scale-[0.99]",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex flex-col items-center gap-1 text-xs",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Image$1, { className: "h-5 w-5" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: "Tap to choose cover image" })]
							})
						})
					] })
				]
			}),
			currentStep === 1 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col gap-4 animate-in fade-in duration-200",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
						icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(MonitorSmartphone, { className: "h-3.5 w-3.5" }),
						children: "Format"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "mt-2 grid grid-cols-2 gap-2",
						children: [{
							on: false,
							emoji: "📍",
							label: "In-Person Venue"
						}, {
							on: true,
							emoji: "💻",
							label: "Online / Virtual"
						}].map((opt) => {
							return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
								type: "button",
								onClick: () => set("is_online", opt.on),
								className: `flex items-center justify-center gap-2 rounded-2xl border px-3 py-3 text-xs font-semibold transition ${form.is_online === opt.on ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-card text-muted-foreground hover:border-primary/40"}`,
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "text-base leading-none",
									children: opt.emoji
								}), opt.label]
							}, opt.label);
						})
					})] }),
					form.is_online ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Field, {
						label: "Meeting URL",
						icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link$1, { className: "h-3.5 w-3.5" }),
						error: errors.meeting_link,
						hint: "Google Meet, Discord, Zoom…",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
							type: "url",
							value: form.meeting_link,
							onChange: (e) => set("meeting_link", e.target.value),
							maxLength: 500,
							placeholder: "https://meet.google.com/xyz-abcd-efg",
							className: "w-full bg-transparent text-xs outline-none placeholder:text-muted-foreground"
						})
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
						className: "-mt-2 flex items-center gap-1.5 text-[11px] text-muted-foreground",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Lock, { className: "h-3 w-3 text-primary shrink-0" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: "Link is securely hidden until you approve attendee join requests." })]
					})] }) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Field, {
						label: "Venue Location",
						icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, { className: "h-3.5 w-3.5" }),
						error: errors.location,
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
							value: form.location,
							onChange: (e) => set("location", e.target.value),
							maxLength: 120,
							placeholder: isIndoorCategory ? "Third Wave Coffee, Indiranagar" : "Turf Arena, Indiranagar",
							className: "w-full bg-transparent text-xs outline-none placeholder:text-muted-foreground"
						})
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "-mt-2 flex items-center justify-between gap-2 rounded-2xl border border-dashed border-border/60 bg-card/40 px-3 py-2 text-[11px]",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "min-w-0 flex-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "font-semibold uppercase tracking-wider text-muted-foreground",
								children: "Pin venue on map"
							}), pinnedPlace ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
								className: "mt-0.5 truncate text-foreground font-medium",
								children: [
									"📍 ",
									pinnedPlace.short,
									" (",
									pinnedPlace.lat.toFixed(3),
									", ",
									pinnedPlace.lon.toFixed(3),
									")"
								]
							}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "mt-0.5 text-muted-foreground",
								children: "Enables 15 km hyper-local discovery and GPS check-in."
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PlaceSearch, {
							value: pinnedPlace?.short ?? "",
							onSelect: (p) => {
								setPinnedPlace(p);
								if (!form.location.trim()) set("location", p.short);
							},
							variant: "chip"
						})]
					})] }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Field, {
						label: "Available Squad Slots",
						icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Users, { className: "h-3.5 w-3.5" }),
						error: errors.slots,
						hint: "Max 50",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
							type: "number",
							inputMode: "numeric",
							min: 1,
							max: 50,
							value: form.slots,
							onChange: (e) => set("slots", e.target.value),
							className: "w-full bg-transparent text-sm font-semibold outline-none"
						})
					})
				]
			}),
			currentStep === 2 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col gap-4 animate-in fade-in duration-200",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Field, {
						label: "Cost per Attendee",
						icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DollarSign, { className: "h-3.5 w-3.5" }),
						error: errors.cost,
						hint: "0 for free plans",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center gap-1.5",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-sm font-semibold text-muted-foreground",
								children: "₹"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
								type: "number",
								inputMode: "decimal",
								min: 0,
								value: form.cost,
								onChange: (e) => set("cost", e.target.value),
								className: "w-full bg-transparent text-sm font-semibold outline-none"
							})]
						})
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Field, {
						label: "Topic & Interest Tags",
						icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Hash, { className: "h-3.5 w-3.5" }),
						hint: "Comma separated",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
							value: form.topic_tags,
							onChange: (e) => set("topic_tags", e.target.value),
							maxLength: 120,
							placeholder: "e.g. Beginners welcome, casual, weekend",
							className: "w-full bg-transparent text-xs outline-none placeholder:text-muted-foreground"
						})
					}),
					!form.is_online && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
						icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "h-3.5 w-3.5" }),
						children: "Venue Amenities"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "mt-2 flex flex-wrap gap-1.5",
						children: AMENITIES.map((a) => {
							const active = amenities.includes(a.key);
							const Icon = a.icon;
							return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
								type: "button",
								onClick: () => toggleAmenity(a.key),
								className: `flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition ${active ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-card text-muted-foreground"}`,
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Icon, { className: "h-3.5 w-3.5" }), a.label]
							}, a.key);
						})
					})] }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "rounded-2xl border border-border/60 bg-card/50 p-3.5",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
							className: "flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Shield, { className: "h-3.5 w-3.5 text-primary" }), " Safety & Audience"]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mt-3 flex flex-col gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SafetyToggle, {
								icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "text-base leading-none",
									children: "♀︎"
								}),
								label: "Women-only plan",
								hint: "Visible and joinable only by female members.",
								checked: womenOnly,
								onChange: setWomenOnly
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SafetyToggle, {
								icon: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BadgeCheck, { className: "h-3.5 w-3.5" }),
								label: "Verified users only",
								hint: "Requires attendees to have completed verification.",
								checked: verifiedOnly,
								onChange: setVerifiedOnly
							})]
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground mb-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Eye, { className: "h-3.5 w-3.5 text-primary" }), " Feed Card Preview"]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "overflow-hidden rounded-2xl border border-border/60 bg-card p-4 shadow-sm",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex items-start justify-between gap-2",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "rounded-full bg-primary/15 px-2.5 py-0.5 text-[10px] font-bold text-primary",
									children: form.category || "General"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "text-xs font-bold text-foreground",
									children: Number(form.cost) > 0 ? `₹${form.cost}` : "Free"
								})]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
								className: "mt-2 text-sm font-bold line-clamp-1",
								children: form.title || "Your Plan Title"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "mt-1 text-xs text-muted-foreground line-clamp-2",
								children: form.description || "Plan description preview..."
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "mt-3 flex items-center justify-between border-t border-border/60 pt-2 text-[11px] text-muted-foreground",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
									className: "flex items-center gap-1",
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, { className: "h-3 w-3" }),
										" ",
										form.is_online ? "Online event" : form.location || "Venue"
									]
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
									className: "flex items-center gap-1 font-semibold",
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Users, { className: "h-3 w-3" }),
										" ",
										form.slots,
										" spots"
									]
								})]
							})
						]
					})] })
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("footer", {
				className: "fixed inset-x-0 bottom-0 z-40 border-t border-border/60 bg-card/95 backdrop-blur-md px-5 py-3",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "mx-auto flex max-w-md items-center justify-between gap-3",
					children: [currentStep > 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
						type: "button",
						disabled: mutation.isPending || uploading,
						onClick: () => setCurrentStep((s) => s - 1),
						className: "flex items-center gap-1.5 rounded-full border border-border/60 px-4 py-2.5 text-xs font-semibold hover:bg-accent transition active:scale-95 disabled:opacity-50",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowLeft, { className: "h-3.5 w-3.5" }), " Back"]
					}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {}), currentStep < 2 ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
						type: "button",
						onClick: () => {
							if (currentStep === 0 && validateStep1()) setCurrentStep(1);
							else if (currentStep === 1 && validateStep2()) setCurrentStep(2);
						},
						className: "flex items-center gap-1.5 rounded-full bg-primary px-6 py-2.5 text-xs font-semibold text-primary-foreground hover:scale-105 active:scale-95 transition",
						children: ["Continue ", /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowRight, { className: "h-3.5 w-3.5" })]
					}) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
						type: "button",
						disabled: mutation.isPending || uploading,
						onClick: onSubmit,
						className: "flex items-center gap-1.5 rounded-full bg-primary px-6 py-2.5 text-xs font-semibold text-primary-foreground hover:scale-105 active:scale-95 transition disabled:opacity-50",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "h-3.5 w-3.5" }), uploading ? "Uploading photo…" : mutation.isPending ? "Publishing…" : "Publish plan"]
					})]
				})
			})
		]
	});
}
function SafetyToggle({ icon, label, hint, checked, onChange }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex items-center gap-3 rounded-xl bg-background/60 px-3 py-2 select-none",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
				className: "flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary/15 text-primary",
				children: icon
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
				className: "min-w-0 flex-1",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
					className: "block text-xs font-semibold",
					children: label
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
					className: "block text-[10px] text-muted-foreground",
					children: hint
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
				type: "button",
				role: "switch",
				"aria-checked": checked,
				"aria-label": label,
				onClick: () => onChange(!checked),
				className: `relative inline-flex h-5 w-10 shrink-0 items-center rounded-full transition ${checked ? "bg-primary" : "bg-secondary"}`,
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { className: `inline-block h-4 w-4 rounded-full bg-background shadow transition ${checked ? "translate-x-5" : "translate-x-0.5"}` })
			})
		]
	});
}
function Label({ children, icon }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground",
		children: [icon, children]
	});
}
function Field({ label, icon, error, hint, children }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: `rounded-2xl border bg-card px-4 py-3 transition ${error ? "border-destructive/60" : "border-border/60"}`,
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "flex items-center justify-between",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
				icon,
				children: label
			}), hint && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
				className: "text-[10px] text-muted-foreground",
				children: hint
			})]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "mt-1.5",
			children
		})]
	}), error && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
		className: "mt-1.5 pl-1 text-[11px] font-medium text-destructive",
		children: error
	})] });
}
var Route$5 = createFileRoute("/messages")({
	head: () => ({ meta: [{ title: "Messages · tribeX" }, {
		name: "description",
		content: "Chat with your squads and plan hosts."
	}] }),
	component: Messages
});
function Messages() {
	const { user, loading } = useAuth();
	const navigate = useNavigate();
	const [q, setQ] = (0, import_react.useState)("");
	const { data: chats = [], isLoading, error, refetch } = useQuery({
		queryKey: ["chats", user?.id],
		queryFn: () => listUserChats(user.id),
		enabled: !!user,
		staleTime: 0,
		refetchOnMount: "always",
		refetchOnWindowFocus: true
	});
	if (!loading && !user) return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex flex-col items-start gap-4 px-5 pt-8",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
				className: "text-2xl font-bold tracking-tight",
				children: "Your squad chats"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "text-sm text-muted-foreground",
				children: "Sign in to see messages from plans you host or joined."
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
				onClick: () => navigate({ to: "/auth" }),
				className: "rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground",
				children: "Sign in"
			})
		]
	});
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex flex-col gap-5 px-5 pt-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground",
				children: "Inbox"
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
				className: "mt-1 text-3xl font-bold tracking-tight",
				children: "Messages"
			})] }),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
				className: "flex items-center gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Search, { className: "h-4 w-4 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
					value: q,
					onChange: (e) => setQ(e.target.value),
					placeholder: "Search chats",
					className: "w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
				})]
			}),
			isLoading ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ListSkeleton, {
				count: 3,
				variant: "row"
			}) : error ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "rounded-3xl border border-destructive/30 bg-destructive/10 p-5 text-sm text-destructive",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "font-semibold",
					children: "Couldn't load chats right now."
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					type: "button",
					onClick: () => refetch(),
					className: "mt-3 rounded-full bg-destructive px-4 py-2 text-xs font-bold text-destructive-foreground",
					children: "Retry"
				})]
			}) : chats.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "rounded-3xl border border-dashed border-border bg-card/40 p-6 text-center text-sm text-muted-foreground",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MessageCircle, { className: "mx-auto mb-2 h-6 w-6 text-muted-foreground/60" }), "No chats yet. Join or host a plan to start a squad chat."]
			}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
				className: "flex flex-col",
				children: chats.filter((c) => {
					const t = q.trim().toLowerCase();
					if (!t) return true;
					return c.title.toLowerCase().includes(t) || c.location.toLowerCase().includes(t) || c.category.toLowerCase().includes(t);
				}).map((c) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Link, {
					to: "/chat/$activityId",
					params: { activityId: c.id },
					className: "flex items-center gap-3 border-b border-border/50 py-3 transition hover:bg-accent/30 active:scale-[0.99] last:border-b-0",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-secondary text-xl",
						children: emojiFor(c.category)
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "min-w-0 flex-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center justify-between gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
								className: "truncate text-sm font-semibold",
								children: c.title
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "shrink-0 text-[11px] text-muted-foreground",
								children: new Date(c.date_time).toLocaleDateString([], {
									month: "short",
									day: "numeric"
								})
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "truncate text-xs text-muted-foreground",
							children: c.location
						})]
					})]
				}) }, c.id))
			})
		]
	});
}
var APP_ID = "";
var sdkPromise = null;
var listenerAttached = false;
function isOneSignalConfigured() {
	return false;
}
function loadSdk() {
	if (typeof window === "undefined") return Promise.reject(/* @__PURE__ */ new Error("client-only"));
	if (!isOneSignalConfigured()) return Promise.reject(/* @__PURE__ */ new Error("OneSignal app id missing"));
	if (sdkPromise) return sdkPromise;
	sdkPromise = new Promise((resolve, reject) => {
		if (window.OneSignal) return resolve(window.OneSignal);
		window.OneSignalDeferred = window.OneSignalDeferred ?? [];
		if (!document.querySelector("script[data-onesignal=\"v16\"]")) {
			const s = document.createElement("script");
			s.src = "https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js";
			s.async = true;
			s.defer = true;
			s.dataset.onesignal = "v16";
			s.onerror = () => reject(/* @__PURE__ */ new Error("Failed to load OneSignal SDK"));
			document.head.appendChild(s);
		}
		window.OneSignalDeferred.push(async (OneSignal) => {
			try {
				await OneSignal.init({
					appId: APP_ID,
					allowLocalhostAsSecureOrigin: true,
					serviceWorkerPath: "/OneSignalSDKWorker.js",
					notifyButton: { enable: false }
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
function attachListener(os) {
	if (listenerAttached) return;
	listenerAttached = true;
	os.User.PushSubscription.addEventListener("change", (change) => {
		savePushTokenToProfile(change.current?.id ?? null).catch((e) => console.warn("[OneSignal] save token", e));
	});
}
async function savePushTokenToProfile(token) {
	const { data } = await supabase.auth.getUser();
	const uid = data.user?.id;
	if (!uid) return;
	await supabase.from("profiles").update({ push_token: token }).eq("id", uid);
}
async function initOneSignal() {
	if (!isOneSignalConfigured()) return null;
	try {
		return await loadSdk();
	} catch (e) {
		console.warn("[OneSignal] init failed", e);
		return null;
	}
}
var DENIED_MESSAGE = "Notification access is blocked in your browser settings. Click the lock icon (🔒) next to the URL in your browser address bar to allow Notifications.";
function isNativeCapacitor() {
	if (typeof window === "undefined") return false;
	const cap = window.Capacitor;
	try {
		return !!cap?.isNativePlatform?.();
	} catch {
		return false;
	}
}
async function requestNativePushPermission() {
	try {
		const mod = await import(
			/* @vite-ignore */
			"@capacitor/push-notifications"
).catch(() => null);
		if (!mod?.PushNotifications) return {
			status: "unsupported",
			message: "Native push plugin not installed"
		};
		const { PushNotifications } = mod;
		const current = await PushNotifications.checkPermissions();
		if (current.receive === "denied") return {
			status: "denied",
			message: DENIED_MESSAGE
		};
		let state = current.receive;
		if (state !== "granted") state = (await PushNotifications.requestPermissions()).receive;
		if (state !== "granted") {
			if (state === "denied") return {
				status: "denied",
				message: DENIED_MESSAGE
			};
			return {
				status: "dismissed",
				message: "Notification prompt dismissed"
			};
		}
		const tokenPromise = new Promise((resolve) => {
			const timer = setTimeout(() => resolve(null), 6e3);
			PushNotifications.addListener("registration", (t) => {
				clearTimeout(timer);
				resolve(t.value);
			}).catch(() => resolve(null));
		});
		await PushNotifications.register();
		const token = await tokenPromise;
		if (token) await savePushTokenToProfile(token);
		return {
			status: "granted",
			token
		};
	} catch (e) {
		return {
			status: "error",
			message: e instanceof Error ? e.message : "Native push failed"
		};
	}
}
async function requestPushPermission() {
	if (isNativeCapacitor()) return requestNativePushPermission();
	if (typeof window === "undefined" || !("Notification" in window)) return {
		status: "unsupported",
		message: "This browser doesn't support notifications."
	};
	if (Notification.permission === "denied") return {
		status: "denied",
		message: DENIED_MESSAGE
	};
	if (!isOneSignalConfigured()) return {
		status: "unsupported",
		message: "Push notifications aren't configured."
	};
	try {
		const os = await initOneSignal();
		if (!os) return {
			status: "error",
			message: "Notification service failed to load."
		};
		const native = os.Notifications.permissionNative;
		if (native === "granted") {
			if (!os.User.PushSubscription.optedIn) await os.User.PushSubscription.optIn();
			const id = await waitForSubscriptionId(os);
			if (id) await savePushTokenToProfile(id);
			return {
				status: "granted",
				token: id
			};
		}
		if (native === "denied") return {
			status: "denied",
			message: DENIED_MESSAGE
		};
		if (!await os.Notifications.requestPermission()) {
			if (Notification.permission === "denied") return {
				status: "denied",
				message: DENIED_MESSAGE
			};
			return {
				status: "dismissed",
				message: "Notification prompt dismissed"
			};
		}
		if (!os.User.PushSubscription.optedIn) await os.User.PushSubscription.optIn();
		const id = await waitForSubscriptionId(os);
		if (id) await savePushTokenToProfile(id);
		return {
			status: "granted",
			token: id
		};
	} catch (e) {
		console.warn("[Push] permission flow failed", e);
		return {
			status: "error",
			message: e instanceof Error ? e.message : "Couldn't enable notifications."
		};
	}
}
async function disablePushForCurrentUser() {
	const os = await initOneSignal();
	if (!os) return;
	try {
		await os.User.PushSubscription.optOut();
	} catch (e) {
		console.warn("[OneSignal] optOut failed", e);
	}
	await savePushTokenToProfile(null);
}
async function getPushStatus() {
	if (typeof window === "undefined" || !("Notification" in window)) return {
		supported: false,
		permission: "unsupported",
		optedIn: false,
		subscriptionId: null
	};
	if (!isOneSignalConfigured()) return {
		supported: false,
		permission: Notification.permission,
		optedIn: false,
		subscriptionId: null
	};
	const os = await initOneSignal();
	if (!os) return {
		supported: true,
		permission: Notification.permission,
		optedIn: false,
		subscriptionId: null
	};
	return {
		supported: true,
		permission: os.Notifications.permissionNative,
		optedIn: !!os.User.PushSubscription.optedIn,
		subscriptionId: os.User.PushSubscription.id ?? null
	};
}
async function waitForSubscriptionId(os, timeoutMs = 4e3) {
	const start = Date.now();
	while (Date.now() - start < timeoutMs) {
		const id = os.User.PushSubscription.id;
		if (id) return id;
		await new Promise((r) => setTimeout(r, 200));
	}
	return os.User.PushSubscription.id ?? null;
}
var Route$4 = createFileRoute("/onboarding")({
	head: () => ({ meta: [{ title: "Pick your interests · tribeX" }, {
		name: "description",
		content: "Tell us what you love so we can match you to plans nearby."
	}] }),
	component: Onboarding
});
var INTERESTS = [
	{
		key: "Cricket",
		emoji: "🏏"
	},
	{
		key: "Football",
		emoji: "⚽"
	},
	{
		key: "Trek",
		emoji: "🥾"
	},
	{
		key: "Music",
		emoji: "🎸"
	},
	{
		key: "Food",
		emoji: "🍜"
	},
	{
		key: "Board games",
		emoji: "🎲"
	},
	{
		key: "Run",
		emoji: "🏃"
	},
	{
		key: "Cycling",
		emoji: "🚴"
	},
	{
		key: "Parties",
		emoji: "🎉"
	},
	{
		key: "Social",
		emoji: "🤝"
	},
	{
		key: "Outdoors",
		emoji: "🌄"
	},
	{
		key: "Sports",
		emoji: "🏅"
	}
];
function Onboarding() {
	const { user, loading } = useAuth();
	const navigate = useNavigate();
	const qc = useQueryClient();
	const [selected, setSelected] = (0, import_react.useState)(/* @__PURE__ */ new Set());
	const [saving, setSaving] = (0, import_react.useState)(false);
	const [profileLoading, setProfileLoading] = (0, import_react.useState)(true);
	(0, import_react.useEffect)(() => {
		if (!loading && !user) navigate({
			to: "/auth",
			replace: true
		});
	}, [
		loading,
		user,
		navigate
	]);
	(0, import_react.useEffect)(() => {
		if (!user) {
			setProfileLoading(false);
			return;
		}
		getProfile(user.id).then((p) => {
			if (p?.has_completed_onboarding) {
				navigate({
					to: "/",
					replace: true
				});
				return;
			}
			if (p?.interests?.length) setSelected(new Set(p.interests));
			setProfileLoading(false);
		}).catch(() => {
			setProfileLoading(false);
		});
	}, [user, navigate]);
	if (loading || user && profileLoading) return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PageLoader, { label: "Loading onboarding" });
	function toggle(k) {
		setSelected((prev) => {
			const next = new Set(prev);
			if (next.has(k)) next.delete(k);
			else next.add(k);
			return next;
		});
	}
	async function handleSave() {
		if (!user) return;
		if (selected.size < 1) {
			toast.error("Pick at least one interest");
			return;
		}
		setSaving(true);
		try {
			const updated = await updateProfile(user.id, {
				interests: Array.from(selected),
				has_completed_onboarding: true
			});
			qc.setQueryData(["profile", user.id], updated);
			qc.setQueryData(["onboarding-status", user.id], updated);
			qc.invalidateQueries({ queryKey: ["profile", user.id] });
			qc.invalidateQueries({ queryKey: ["onboarding-status", user.id] });
			toast.success("You're all set!");
			requestPushPermission().then((res) => {
				if (res.status === "granted") toast.success("Notifications enabled — you'll hear about new plans nearby.");
				else if (res.status === "denied") toast("Notifications blocked", {
					description: res.message,
					duration: 8e3
				});
			}).catch(() => {});
			navigate({
				to: "/",
				replace: true
			});
		} catch (e) {
			toast.error(e instanceof Error ? e.message : "Couldn't save preferences");
		} finally {
			setSaving(false);
		}
	}
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex min-h-screen flex-col gap-6 px-5 pb-10 pt-10",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", {
				className: "flex flex-col gap-2",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/15 text-primary",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkles, { className: "h-6 w-6" })
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
						className: "text-3xl font-bold tracking-tight",
						children: "What are you into?"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-sm text-muted-foreground",
						children: "Pick one or more so we can surface plans you'll actually love. You can update these later."
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid grid-cols-2 gap-2.5 sm:grid-cols-3",
				children: INTERESTS.map((c) => {
					const on = selected.has(c.key);
					return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
						type: "button",
						onClick: () => toggle(c.key),
						className: `relative flex items-center gap-2 rounded-2xl border px-4 py-3.5 text-left text-sm font-medium transition active:scale-[0.98] ${on ? "border-primary bg-primary/10 text-foreground" : "border-border/60 bg-card text-muted-foreground hover:border-primary/50"}`,
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-lg",
								children: c.emoji
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "flex-1",
								children: c.key
							}),
							on && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "flex h-5 w-5 items-center justify-center rounded-full bg-primary text-primary-foreground",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "h-3 w-3" })
							})
						]
					}, c.key);
				})
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "sticky bottom-4 mt-auto flex flex-col gap-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-center text-xs text-muted-foreground",
					children: selected.size === 0 ? "Select at least one to continue" : `${selected.size} selected`
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					onClick: handleSave,
					disabled: saving || selected.size < 1,
					className: "w-full rounded-2xl bg-primary py-4 text-sm font-semibold text-primary-foreground shadow-lg transition hover:scale-[1.01] active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-50",
					children: saving ? "Saving…" : "Save & Continue"
				})]
			})
		]
	});
}
var EMPTY = {
	rating: 0,
	badges: [],
	comment: ""
};
function RateSquadModal({ open, onClose, planId, planTitle, hostId, viewerId }) {
	const qc = useQueryClient();
	const enabled = !!(open && planId && hostId && viewerId);
	const { data: participants = [], isLoading: loadingPeople } = useQuery({
		queryKey: [
			"rate-participants",
			planId,
			viewerId
		],
		queryFn: () => listRateableParticipants(planId, hostId, viewerId),
		enabled,
		staleTime: 6e4
	});
	const { data: existing = [], isLoading: loadingRatings } = useQuery({
		queryKey: [
			"my-ratings",
			planId,
			viewerId
		],
		queryFn: () => listMyRatingsForPlan(planId, viewerId),
		enabled,
		staleTime: 6e4
	});
	const existingMap = (0, import_react.useMemo)(() => {
		const m = /* @__PURE__ */ new Map();
		existing.forEach((r) => m.set(r.reviewee_id, r));
		return m;
	}, [existing]);
	const [drafts, setDrafts] = (0, import_react.useState)({});
	(0, import_react.useEffect)(() => {
		if (!enabled) return;
		setDrafts((prev) => {
			const next = { ...prev };
			participants.forEach((p) => {
				if (next[p.id]) return;
				const r = existingMap.get(p.id);
				next[p.id] = r ? {
					rating: r.rating,
					badges: r.badges ?? [],
					comment: r.comment ?? ""
				} : { ...EMPTY };
			});
			return next;
		});
	}, [
		enabled,
		participants,
		existingMap
	]);
	const [savingId, setSavingId] = (0, import_react.useState)(null);
	const save = useMutation({
		mutationFn: async ({ revieweeId, draft }) => {
			return upsertRating({
				plan_id: planId,
				reviewee_id: revieweeId,
				rating: draft.rating,
				badges: draft.badges,
				comment: draft.comment
			});
		},
		onSuccess: (_data, vars) => {
			toast.success("Rating saved");
			qc.invalidateQueries({ queryKey: [
				"my-ratings",
				planId,
				viewerId
			] });
			qc.invalidateQueries({ queryKey: ["profile", vars.revieweeId] });
		},
		onError: (e) => toast.error(friendlyError(e)),
		onSettled: () => setSavingId(null)
	});
	if (!open || !planId || !viewerId) return null;
	const loading = loadingPeople || loadingRatings;
	if (typeof document === "undefined") return null;
	return (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm antialiased",
		onClick: onClose,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			onClick: (e) => e.stopPropagation(),
			className: "fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-5 shadow-2xl",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mb-3 flex items-start justify-between gap-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "text-base font-bold tracking-tight",
					children: "Rate your squad"
				}), planTitle && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mt-0.5 truncate text-xs text-muted-foreground",
					children: planTitle
				})] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					type: "button",
					onClick: onClose,
					className: "rounded-full p-1 hover:bg-accent",
					"aria-label": "Close",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4" })
				})]
			}), loading ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex flex-col gap-3",
				children: [
					0,
					1,
					2
				].map((i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-28 animate-pulse rounded-2xl border border-border/60 bg-background" }, i))
			}) : participants.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "rounded-2xl border border-dashed border-border bg-background p-6 text-center text-sm text-muted-foreground",
				children: "No other participants to rate for this plan."
			}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
				className: "flex flex-col gap-3",
				children: participants.map((p) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ParticipantRow, {
					person: p,
					isHost: p.id === hostId,
					submitted: existingMap.has(p.id),
					draft: drafts[p.id] ?? EMPTY,
					onChange: (next) => setDrafts((d) => ({
						...d,
						[p.id]: next
					})),
					saving: savingId === p.id && save.isPending,
					onSubmit: () => {
						const d = drafts[p.id];
						if (!d || d.rating < 1) {
							toast.error("Pick a star rating first");
							return;
						}
						setSavingId(p.id);
						save.mutate({
							revieweeId: p.id,
							draft: d
						});
					}
				}, p.id))
			})]
		})
	}), document.body);
}
function ParticipantRow({ person, isHost, submitted, draft, onChange, onSubmit, saving }) {
	const name = person.full_name || person.username || "Squad mate";
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
		className: "rounded-2xl border border-border/60 bg-background p-3",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mb-2 flex items-center gap-3",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "h-9 w-9 shrink-0 overflow-hidden rounded-full bg-primary/15 text-xs font-semibold text-primary",
						children: person.avatar_url ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
							src: person.avatar_url,
							alt: "",
							className: "h-full w-full object-cover"
						}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "flex h-full w-full items-center justify-center",
							children: name[0]?.toUpperCase()
						})
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "min-w-0 flex-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "truncate text-sm font-semibold",
							children: name
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-[11px] text-muted-foreground",
							children: isHost ? "Host" : "Attendee"
						})]
					}),
					submitted && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
						className: "flex items-center gap-1 rounded-full bg-green-500/15 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-green-600 dark:text-green-400",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "h-3 w-3" }), " Submitted"]
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex items-center gap-1",
				children: [
					1,
					2,
					3,
					4,
					5
				].map((n) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					type: "button",
					onClick: () => onChange({
						...draft,
						rating: n
					}),
					className: "p-1 transition active:scale-90",
					"aria-label": `Rate ${n} star${n === 1 ? "" : "s"}`,
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: `h-6 w-6 ${n <= draft.rating ? "fill-amber-400 text-amber-400" : "text-muted-foreground/40"}` })
				}, n))
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "mt-2 flex flex-wrap gap-1.5",
				children: RATING_BADGES.map((b) => {
					const on = draft.badges.includes(b.key);
					return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
						type: "button",
						onClick: () => onChange({
							...draft,
							badges: on ? draft.badges.filter((k) => k !== b.key) : [...draft.badges, b.key]
						}),
						className: `flex items-center gap-1 rounded-full border px-2.5 py-1 text-[11px] font-medium transition ${on ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-card text-muted-foreground hover:border-primary/50"}`,
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: b.emoji }),
							" ",
							b.label
						]
					}, b.key);
				})
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", {
				value: draft.comment,
				onChange: (e) => onChange({
					...draft,
					comment: e.target.value
				}),
				maxLength: 500,
				rows: 2,
				placeholder: "Optional note (private to them)…",
				className: "mt-2 w-full resize-none rounded-xl border border-border/60 bg-card px-3 py-2 text-xs outline-none focus:border-primary"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
				type: "button",
				onClick: onSubmit,
				disabled: saving || draft.rating < 1,
				className: "mt-2 flex w-full items-center justify-center gap-1.5 rounded-full bg-primary py-2 text-xs font-semibold text-primary-foreground transition active:scale-[0.98] disabled:opacity-50",
				children: saving ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-3.5 w-3.5 animate-spin" }), " Saving…"] }) : submitted ? "Update Rating" : "Submit Rating"
			})
		]
	});
}
var HELPLINES = [
	{
		label: "Police",
		numbers: ["112", "100"],
		hint: "All-India emergency"
	},
	{
		label: "Ambulance",
		numbers: ["108"],
		hint: "Medical emergency"
	},
	{
		label: "Women Helpline",
		numbers: ["1091"],
		hint: "24×7 support"
	}
];
function EmergencySosModal({ open, onClose }) {
	const [sharing, setSharing] = (0, import_react.useState)(false);
	if (!open) return null;
	async function shareLiveLocation() {
		if (typeof navigator === "undefined" || !navigator.geolocation) {
			toast.error("Location isn't available on this device");
			return;
		}
		setSharing(true);
		try {
			const { latitude, longitude } = await new Promise((resolve, reject) => {
				navigator.geolocation.getCurrentPosition((p) => resolve(p.coords), (err) => reject(new Error(err.message || "Location permission denied")), {
					enableHighAccuracy: true,
					timeout: 1e4,
					maximumAge: 0
				});
			});
			const mapsUrl = `https://maps.google.com/?q=${latitude},${longitude}`;
			const message = `🚨 tribeX SOS — I need help. My live location: ${mapsUrl}`;
			if (typeof navigator.share === "function") try {
				await navigator.share({
					title: "tribeX SOS",
					text: message,
					url: mapsUrl
				});
				return;
			} catch (e) {
				if (e?.name === "AbortError") return;
			}
			const wa = `https://wa.me/?text=${encodeURIComponent(message)}`;
			window.open(wa, "_blank", "noopener,noreferrer");
		} catch (err) {
			toast.error(err instanceof Error ? err.message : "Couldn't get your location");
		} finally {
			setSharing(false);
		}
	}
	if (typeof document === "undefined") return null;
	return (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
		onClick: onClose,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			role: "dialog",
			"aria-modal": "true",
			"aria-labelledby": "sos-title",
			onClick: (e) => e.stopPropagation(),
			className: "fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-destructive/40 bg-background p-6 shadow-2xl",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "mb-4 flex items-start justify-between",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "flex h-11 w-11 items-center justify-center rounded-2xl bg-destructive/15 text-destructive",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShieldAlert, { className: "h-6 w-6" })
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
							id: "sos-title",
							className: "text-lg font-bold",
							children: "Emergency SOS"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-xs text-muted-foreground",
							children: "India helplines · live location"
						})] })]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						type: "button",
						onClick: onClose,
						className: "rounded-full p-1 text-muted-foreground hover:bg-accent",
						"aria-label": "Close",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4" })
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
					className: "flex flex-col gap-2",
					children: HELPLINES.map((h) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
						className: "flex items-center justify-between rounded-2xl border border-border/60 bg-background p-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "min-w-0",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm font-semibold",
								children: h.label
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-[11px] text-muted-foreground",
								children: h.hint
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "flex flex-wrap justify-end gap-1.5",
							children: h.numbers.map((n) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
								href: `tel:${n}`,
								className: "flex items-center gap-1 rounded-full bg-destructive px-3 py-1.5 text-xs font-bold text-destructive-foreground transition hover:scale-105 active:scale-95",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Phone, { className: "h-3 w-3" }),
									" ",
									n
								]
							}, n))
						})]
					}, h.label))
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					type: "button",
					onClick: shareLiveLocation,
					disabled: sharing,
					className: "mt-4 flex w-full items-center justify-center gap-2 rounded-2xl bg-foreground py-3 text-sm font-semibold text-background transition hover:scale-[1.01] active:scale-95 disabled:opacity-60",
					children: [sharing ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-4 w-4 animate-spin" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Share2, { className: "h-4 w-4" }), sharing ? "Getting your location…" : "Share My Live Location"]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
					className: "mt-2 flex items-center justify-center gap-1 text-[11px] text-muted-foreground",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, { className: "h-3 w-3" }), " Opens WhatsApp or your share sheet with GPS coordinates."]
				})
			]
		})
	}), document.body);
}
var Route$3 = createFileRoute("/profile")({
	head: () => ({ meta: [{ title: "Profile · tribeX" }, {
		name: "description",
		content: "Your hosted plans, ratings, and squad stats."
	}] }),
	component: ProfileLayout
});
function ProfileLayout() {
	if (useRouterState().location.pathname === "/profile/settings") return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Outlet, {});
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Profile, {});
}
function Profile() {
	const { user, loading } = useAuth();
	const navigate = useNavigate();
	const qc = useQueryClient();
	const { clearLocation } = useLocation();
	const { data: profile, isLoading: isProfileLoading } = useQuery({
		queryKey: ["profile", user?.id],
		queryFn: () => getProfile(user.id),
		enabled: !!user
	});
	const { data: acts, isLoading: isActsLoading } = useQuery({
		queryKey: ["user-activities", user?.id],
		queryFn: () => getUserActivities(user.id),
		enabled: !!user,
		staleTime: 120 * 1e3,
		gcTime: 600 * 1e3
	});
	useQuery({
		queryKey: ["user-stats", user?.id],
		queryFn: () => getUserStats(user.id),
		enabled: !!user
	});
	const [showSos, setShowSos] = (0, import_react.useState)(false);
	const [editingPlan, setEditingPlan] = (0, import_react.useState)(null);
	const [deletingPlan, setDeletingPlan] = (0, import_react.useState)(null);
	const [myPlansTab, setMyPlansTab] = (0, import_react.useState)("joined");
	const [manageActivityId, setManageActivityId] = (0, import_react.useState)(null);
	const [ratingPlan, setRatingPlan] = (0, import_react.useState)(null);
	const [signingOut, setSigningOut] = (0, import_react.useState)(false);
	const { data: hostPending = [] } = useQuery({
		queryKey: ["pending-requests-host", user?.id],
		queryFn: () => listPendingRequestsForHost(user.id),
		enabled: !!user
	});
	const pendingByActivity = hostPending.reduce((m, r) => {
		m[r.activity_id] = (m[r.activity_id] ?? 0) + 1;
		return m;
	}, {});
	const deleteMut = useMutation({
		mutationFn: (id) => deleteActivity(id),
		onSuccess: async () => {
			await Promise.all([
				qc.refetchQueries({ queryKey: ["user-activities", user?.id] }),
				qc.invalidateQueries({ queryKey: ["activities"] }),
				qc.invalidateQueries({ queryKey: ["user-stats", user?.id] }),
				qc.invalidateQueries({ queryKey: ["profile", user?.id] })
			]);
			toast.success("Plan deleted");
			setDeletingPlan(null);
		},
		onError: (e) => {
			console.error("[delete-plan] failed", e);
			toast.error(friendlyError(e, "Couldn't delete plan. Please try again."));
		}
	});
	if (!loading && !user) return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex flex-col items-start gap-4 px-5 pt-8",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
				className: "text-2xl font-bold tracking-tight",
				children: "Your profile"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "text-sm text-muted-foreground",
				children: "Sign in to see your hosted plans, ratings and squad stats."
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
				onClick: () => navigate({ to: "/auth" }),
				className: "rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground",
				children: "Sign in"
			})
		]
	});
	if (isProfileLoading || isActsLoading) return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PageLoader, { label: "Loading profile" });
	const displayName = profile?.full_name || profile?.username || "You";
	const initial = (displayName[0] ?? "U").toUpperCase();
	const hosted = acts?.hosted ?? [];
	const joined = acts?.joined ?? [];
	const hostedCount = hosted.length;
	const joinedCount = joined.length;
	const rating = Number(profile?.rating ?? 5).toFixed(2);
	const reliability = Math.round(Number(profile?.reliability_score ?? 100));
	const reliabilityLabel = formatReliabilityLabel(reliability, getReliabilityTitle(user, {
		hosted,
		joined
	}));
	const reliabilityTone = reliability >= 90 ? "bg-green-500/15 text-green-600 dark:text-green-400" : reliability >= 70 ? "bg-amber-500/15 text-amber-600 dark:text-amber-400" : "bg-red-500/15 text-red-600 dark:text-red-400";
	const sortByDateDesc = (a, b) => a.date_time < b.date_time ? 1 : -1;
	const hostedSorted = [...hosted].sort(sortByDateDesc);
	const joinedSorted = [...joined].sort(sortByDateDesc);
	function directionsHref(a) {
		if (a.latitude != null && a.longitude != null) return `https://www.google.com/maps/dir/?api=1&destination=${a.latitude},${a.longitude}`;
		return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(a.location)}`;
	}
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex flex-col gap-5 px-5 pt-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", {
				className: "flex items-start justify-between",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground",
					children: "Profile"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
					className: "mt-1 text-3xl font-bold tracking-tight",
					children: "You"
				})] }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center gap-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
						to: "/profile/settings",
						className: "flex h-10 w-10 items-center justify-center rounded-full border border-border/60 bg-card text-foreground transition hover:border-primary hover:text-primary active:scale-95",
						title: "Settings & Edit Profile",
						"aria-label": "Settings",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(UserCog, { className: "h-4 w-4" })
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						onClick: async () => {
							if (signingOut) return;
							setSigningOut(true);
							try {
								const work = (async () => {
									await qc.cancelQueries();
									qc.clear();
									clearLocation();
									const { error } = await supabase.auth.signOut();
									if (error) throw error;
								})();
								await Promise.all([work, new Promise((r) => setTimeout(r, 500))]);
								toast.success("Signed out");
								navigate({
									to: "/",
									replace: true
								});
							} catch (e) {
								setSigningOut(false);
								toast.error(friendlyError(e, "Couldn't sign out. Please try again."));
							}
						},
						disabled: signingOut,
						className: "flex h-10 w-10 items-center justify-center rounded-full border border-border/60 bg-card transition hover:border-destructive/60 hover:text-destructive active:scale-95 disabled:opacity-60",
						title: "Sign out",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LogOut, { className: "h-4 w-4" })
					})]
				})]
			}),
			signingOut && typeof document !== "undefined" && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "fixed inset-0 z-[99998] bg-black/80 backdrop-blur-sm" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "fixed left-1/2 top-1/2 z-[99999] flex w-[90vw] max-w-xs -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-3 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-6 w-6 animate-spin text-primary" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-sm font-semibold",
					children: "Signing you out…"
				})]
			})] }), document.body),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "rounded-3xl border border-border/60 bg-card p-5",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center gap-4",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "relative shrink-0",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "flex h-16 w-16 items-center justify-center overflow-hidden rounded-full bg-primary text-2xl font-bold text-primary-foreground",
								children: profile?.avatar_url ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
									src: profile.avatar_url,
									alt: displayName,
									className: "h-full w-full object-cover"
								}) : initial
							}), profile?.is_verified && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "absolute -top-1 -right-1 flex h-6 w-6 items-center justify-center rounded-full bg-background",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BadgeCheck, { className: "h-5 w-5 fill-primary text-primary-foreground" })
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "min-w-0",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									className: "flex items-center gap-1.5",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
										className: "truncate text-lg font-semibold",
										children: displayName
									}), profile?.is_verified && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
										className: "inline-flex items-center gap-1 rounded-full bg-primary/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-primary",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BadgeCheck, { className: "h-3 w-3" }), " Verified"]
									})]
								}),
								profile?.city && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
									className: "flex items-center gap-1 text-xs text-muted-foreground truncate",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, { className: "h-3 w-3" }), profile.city]
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
									className: "mt-1 flex items-center gap-1 text-xs",
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-3.5 w-3.5 fill-current text-primary" }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
											className: "font-semibold",
											children: rating
										}),
										/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
											className: "text-muted-foreground",
											children: [
												"host rating · ",
												hostedCount,
												" plans"
											]
										})
									]
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
									className: `mt-1 inline-flex w-fit items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold ${reliabilityTone}`,
									children: ["⭐ ", reliabilityLabel]
								})
							]
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mt-4 flex items-center justify-between gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "flex-1 text-sm leading-relaxed text-muted-foreground",
							children: profile?.bio || "Tell your squad about yourself in settings."
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
							to: "/profile/settings",
							className: "shrink-0 rounded-full border border-border/60 bg-background/80 px-3 py-1.5 text-xs font-semibold text-foreground transition hover:border-primary hover:text-primary active:scale-95",
							children: "Edit profile"
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mt-5 grid grid-cols-3 gap-2 text-center",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Stat, {
								label: "Hosted",
								value: String(hostedCount)
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Stat, {
								label: "Joined",
								value: String(joinedCount)
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Stat, {
								label: "Rating",
								value: rating
							})
						]
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", { children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "mb-2 flex items-center justify-between",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
						className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
						children: "My plans"
					})
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "mb-3 flex rounded-full border border-border/60 bg-card p-1 text-xs",
					children: [{
						k: "joined",
						label: `Joined · ${joinedSorted.length}`
					}, {
						k: "hosted",
						label: `Hosted · ${hostedSorted.length}`
					}].map((t) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						onClick: () => setMyPlansTab(t.k),
						className: `flex-1 rounded-full px-3 py-1.5 font-medium transition ${myPlansTab === t.k ? "bg-foreground text-background" : "text-muted-foreground"}`,
						children: t.label
					}, t.k))
				}),
				myPlansTab === "joined" ? joinedSorted.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "rounded-3xl border border-dashed border-border bg-card/40 p-6 text-center text-sm text-muted-foreground",
					children: "You haven't joined any plans yet. Discover one on the Explore tab."
				}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
					className: "flex flex-col gap-2",
					children: joinedSorted.map((p) => {
						const canRate = isEventEnded(p);
						return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
							className: "flex flex-col gap-2 rounded-2xl border border-border/60 bg-card p-3",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex items-center gap-3",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
										className: "flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-primary/10 text-lg",
										children: emojiFor(p.category)
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "min-w-0 flex-1",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
											className: "truncate text-sm font-semibold",
											children: p.title
										}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
											className: "flex items-center gap-1 text-xs text-muted-foreground",
											children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Calendar, { className: "h-3 w-3" }), new Date(p.date_time).toLocaleDateString([], {
												month: "short",
												day: "numeric",
												hour: "numeric",
												minute: "2-digit"
											})]
										})]
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "flex shrink-0 items-center gap-1.5",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
											to: "/chat/$activityId",
											params: { activityId: p.id },
											className: "flex h-8 w-8 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-primary/60 hover:text-primary active:scale-95",
											"aria-label": "Group chat",
											title: "Group chat",
											children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("svg", {
												className: "h-3.5 w-3.5",
												viewBox: "0 0 24 24",
												fill: "none",
												stroke: "currentColor",
												strokeWidth: "2",
												children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" })
											})
										}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
											href: directionsHref(p),
											target: "_blank",
											rel: "noopener noreferrer",
											className: "flex h-8 w-8 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-primary/60 hover:text-primary active:scale-95",
											"aria-label": "Venue directions",
											title: "Venue directions",
											children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("svg", {
												className: "h-3.5 w-3.5",
												viewBox: "0 0 24 24",
												fill: "none",
												stroke: "currentColor",
												strokeWidth: "2",
												children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("polygon", { points: "3 11 22 2 13 21 11 13 3 11" })
											})
										})]
									})
								]
							}), canRate && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
								onClick: () => setRatingPlan(p),
								className: "flex items-center justify-center gap-1.5 rounded-full bg-gradient-to-r from-amber-500 to-orange-500 px-3 py-1.5 text-[11px] font-semibold text-white shadow-sm transition active:scale-95",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkles, { className: "h-3 w-3" }), " Event ended · Rate your squad"]
							})]
						}, p.id);
					})
				}) : hostedSorted.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "rounded-3xl border border-dashed border-border bg-card/40 p-6 text-center text-sm text-muted-foreground",
					children: "You haven't hosted a plan yet. Tap Create to host one."
				}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
					className: "flex flex-col gap-2",
					children: hostedSorted.map((p) => {
						const pending = pendingByActivity[p.id] ?? 0;
						const attendees = Math.max(0, (p.total_slots ?? 0) - (p.slots_left ?? 0));
						const isEnded = isEventEnded(p);
						return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
							className: "flex flex-col gap-2 rounded-2xl border border-border/60 bg-card p-3",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex items-center gap-3",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
										className: "flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-primary/10 text-lg",
										children: emojiFor(p.category)
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "min-w-0 flex-1",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
											className: "truncate text-sm font-semibold",
											children: p.title
										}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
											className: "flex flex-wrap items-center gap-x-2 gap-y-0.5 text-xs text-muted-foreground",
											children: [
												/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
													className: "inline-flex items-center gap-1",
													children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Calendar, { className: "h-3 w-3" }), new Date(p.date_time).toLocaleDateString([], {
														month: "short",
														day: "numeric",
														hour: "numeric",
														minute: "2-digit"
													})]
												}),
												/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
													className: "inline-flex items-center gap-1",
													children: [
														/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Users, { className: "h-3 w-3" }),
														attendees,
														"/",
														p.total_slots,
														" joined"
													]
												}),
												/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
													className: "inline-flex items-center gap-1",
													children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trophy, { className: "h-3 w-3" }), " Hosting"]
												})
											]
										})]
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "flex shrink-0 items-center gap-1.5",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
											onClick: () => setManageActivityId(p.id),
											className: `relative flex items-center gap-1 rounded-full px-3 py-1.5 text-xs font-semibold transition active:scale-95 ${pending > 0 ? "bg-primary text-primary-foreground hover:scale-105" : "border border-border/60 bg-background text-foreground hover:border-primary/60"}`,
											title: "Manage requests",
											children: ["Manage", pending > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
												className: "ml-0.5 rounded-full bg-background/25 px-1.5 py-0.5 text-[10px] font-bold",
												children: pending
											})]
										}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
											onClick: () => setDeletingPlan(p),
											className: "flex h-8 w-8 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-destructive/60 hover:text-destructive active:scale-95",
											"aria-label": "Delete plan",
											title: "Delete plan",
											children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trash2, { className: "h-3.5 w-3.5" })
										})]
									})
								]
							}), isEnded && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
								onClick: () => setRatingPlan(p),
								className: "flex items-center justify-center gap-1.5 rounded-full bg-gradient-to-r from-amber-500 to-orange-500 px-3 py-1.5 text-[11px] font-semibold text-white shadow-sm transition active:scale-95",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkles, { className: "h-3 w-3" }), " Event ended · Rate your squad"]
							})]
						}, p.id);
					})
				})
			] }),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "mt-2 flex flex-col overflow-hidden rounded-2xl border border-border/60 bg-card",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Link, {
					to: "/profile/settings",
					className: "flex items-center justify-between p-4 text-left text-sm font-semibold transition hover:bg-accent active:scale-[0.99]",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
						className: "flex items-center gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(UserCog, { className: "h-4 w-4 text-primary" }), "Settings"]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						className: "text-xs text-muted-foreground",
						children: "→"
					})]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					onClick: () => setShowSos(true),
					className: "flex items-center gap-3 p-4 text-left text-sm font-bold text-destructive transition hover:bg-destructive/10 active:scale-[0.99]",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShieldAlert, { className: "h-4 w-4" }), "Emergency SOS"]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "pb-6 pt-2 text-center text-[11px] text-muted-foreground/70",
				children: "tribeX v1.0.0"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(EmergencySosModal, {
				open: showSos,
				onClose: () => setShowSos(false)
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ManageRequestsModal, {
				activityId: manageActivityId,
				activityTitle: hostedSorted.find((a) => a.id === manageActivityId)?.title,
				open: manageActivityId !== null,
				onClose: () => setManageActivityId(null)
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(RateSquadModal, {
				open: ratingPlan !== null,
				onClose: () => setRatingPlan(null),
				planId: ratingPlan?.id ?? null,
				planTitle: ratingPlan?.title,
				hostId: ratingPlan?.host_id ?? null,
				viewerId: user?.id ?? null
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(EditPlanModal, {
				open: !!editingPlan,
				activity: editingPlan,
				onClose: () => setEditingPlan(null)
			}),
			deletingPlan && typeof document !== "undefined" && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
				onClick: () => !deleteMut.isPending && setDeletingPlan(null),
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					onClick: (e) => e.stopPropagation(),
					className: "fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
							className: "text-lg font-bold",
							children: "Delete this plan?"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
							className: "mt-1 text-sm text-muted-foreground",
							children: [
								"\"",
								deletingPlan.title,
								"\" will be removed for everyone. This can't be undone."
							]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mt-5 flex items-center justify-end gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								onClick: () => setDeletingPlan(null),
								disabled: deleteMut.isPending,
								className: "rounded-full border border-border/60 px-4 py-2 text-xs font-semibold transition hover:bg-accent disabled:opacity-60",
								children: "Cancel"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
								onClick: () => deleteMut.mutate(deletingPlan.id),
								disabled: deleteMut.isPending,
								className: "flex items-center gap-1.5 rounded-full bg-destructive px-4 py-2 text-xs font-semibold text-destructive-foreground transition hover:scale-[1.02] active:scale-95 disabled:opacity-60",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trash2, { className: "h-3.5 w-3.5" }), deleteMut.isPending ? "Deleting…" : "Delete"]
							})]
						})
					]
				})
			}), document.body)
		]
	});
}
function Stat({ label, value }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "rounded-2xl border border-primary/20 bg-primary/10 py-3",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
			className: "text-lg font-bold text-primary",
			children: value
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
			className: "text-[10px] font-medium uppercase tracking-wider text-muted-foreground",
			children: label
		})]
	});
}
var Route$2 = createFileRoute("/terms-and-policies")({
	head: () => ({ meta: [{ title: "Terms & Privacy · tribeX" }, {
		name: "description",
		content: "tribeX terms of use and privacy policy — safety, host guidelines, data usage, and liability."
	}] }),
	component: TermsPage
});
function TermsPage() {
	const navigate = useNavigate();
	const [tab, setTab] = (0, import_react.useState)("terms");
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex flex-col gap-5 px-5 pt-6 pb-10",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", {
				className: "flex items-center gap-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
					onClick: () => navigate({ to: "/profile" }),
					className: "flex h-9 w-9 items-center justify-center rounded-full border border-border/60 bg-card transition hover:border-primary/60 active:scale-95",
					"aria-label": "Back",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowLeft, { className: "h-4 w-4" })
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground",
					children: "Legal"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
					className: "mt-1 text-2xl font-bold tracking-tight",
					children: "Terms & Privacy"
				})] })]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex rounded-full border border-border/60 bg-card p-1 text-xs",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					onClick: () => setTab("terms"),
					className: `flex flex-1 items-center justify-center gap-1.5 rounded-full px-3 py-2 font-semibold transition ${tab === "terms" ? "bg-foreground text-background" : "text-muted-foreground"}`,
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ScrollText, { className: "h-3.5 w-3.5" }), " Terms"]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					onClick: () => setTab("privacy"),
					className: `flex flex-1 items-center justify-center gap-1.5 rounded-full px-3 py-2 font-semibold transition ${tab === "privacy" ? "bg-foreground text-background" : "text-muted-foreground"}`,
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShieldCheck, { className: "h-3.5 w-3.5" }), " Privacy"]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("article", {
				className: "prose prose-sm max-w-none rounded-3xl border border-border/60 bg-card p-5 text-sm leading-relaxed text-foreground",
				children: tab === "terms" ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TermsContent, {}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PrivacyContent, {})
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
				className: "text-center text-[11px] text-muted-foreground/70",
				children: ["Last updated: ", (/* @__PURE__ */ new Date()).toLocaleDateString([], {
					year: "numeric",
					month: "long",
					day: "numeric"
				})]
			})
		]
	});
}
function Section({ title, children }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
		className: "mb-5 last:mb-0",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
			className: "mb-1.5 text-sm font-bold uppercase tracking-wider text-primary",
			children: title
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "space-y-2 text-muted-foreground",
			children
		})]
	});
}
function TermsContent() {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "1. Eligibility",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "You must be at least 18 years old to create an account, host a plan, or join an activity on tribeX. By using tribeX you confirm that you meet this requirement." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Section, {
			title: "2. User Safety & Personal Responsibility",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "tribeX is a discovery platform. All meet-ups, activities, and interactions happen offline between independent users. You participate at your own personal risk and assume full responsibility for your safety, conduct, and belongings." }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "Always meet in public places, share your live location with a trusted contact, and trust your instincts. Report unsafe behaviour immediately." })]
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "3. Host Guidelines",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "Hosts are responsible for the accuracy of the plan details (title, location, time, cost, slots). Hosts must not organise illegal activities, gambling, adult-only content, or anything that risks the safety of participants." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "4. Prohibited Conduct",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "You agree not to harass, threaten, discriminate against, or misrepresent yourself to other users. Sharing personal contact details of other members without consent is prohibited." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "5. Liability Disclaimer",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "tribeX does not verify users, vet activities, or supervise meet-ups. To the fullest extent permitted by law, tribeX and its team are not liable for any injury, loss, damage, dispute, or claim arising from your use of the app or participation in any activity." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "6. Account Termination",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "We may suspend or delete accounts that violate these Terms, receive credible safety reports, or misuse the platform, with or without notice." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "7. Changes",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "We may update these Terms as the product evolves. Continued use after an update means you accept the revised Terms." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "8. Contact",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", { children: [
				"Questions? Reach us at ",
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
					href: "mailto:tribex.apk@gmail.com",
					className: "font-semibold text-primary",
					children: "tribex.apk@gmail.com"
				}),
				"."
			] })
		})
	] });
}
function PrivacyContent() {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "1. Data We Collect",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "Account details you provide (name, email, phone, gender, city, bio, avatar), plans you host or join, chat messages, and your chosen or GPS-derived location. We collect only what the product needs to work." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "2. How We Use Your Data",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "To show you nearby plans, connect you with hosts and squads, secure your account, and improve tribeX. We do not sell your personal data to advertisers." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "3. Location Data",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "Location is used only to surface nearby activities. GPS is requested with your explicit permission and can be revoked from your device settings at any time. You can clear the stored location from your profile." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "4. Sharing With Others",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "Your public profile (name, avatar, bio, city, rating) is visible to hosts and members of plans you interact with. Chat messages are visible to members of that plan's chat." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "5. Service Providers",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "We use trusted providers to run the app (authentication, database, storage, geocoding). They process data only to deliver these services." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "6. Data Retention & Deletion",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", { children: [
				"Your data is retained while your account is active. Email ",
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
					href: "mailto:tribex.apk@gmail.com",
					className: "font-semibold text-primary",
					children: "tribex.apk@gmail.com"
				}),
				" to delete your account and associated data."
			] })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "7. Security",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "We use industry-standard encryption in transit and at rest, row-level access rules, and least-privilege server access. No internet service can be 100% secure — please use a strong, unique password." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "8. Children",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "tribeX is not intended for anyone under 18. We do not knowingly collect data from minors." })
		}),
		/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Section, {
			title: "9. Contact",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", { children: [
				"Privacy questions? Email ",
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
					href: "mailto:tribex.apk@gmail.com",
					className: "font-semibold text-primary",
					children: "tribex.apk@gmail.com"
				}),
				"."
			] })
		})
	] });
}
function ExpenseCard({ expenseId, currentUserId }) {
	const qc = useQueryClient();
	const { data: expense, isLoading } = useQuery({
		queryKey: ["expense", expenseId],
		queryFn: () => getExpense(expenseId),
		staleTime: 15e3
	});
	if (isLoading) return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-32 w-full animate-pulse rounded-2xl bg-card" });
	if (!expense) return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "rounded-2xl border border-dashed border-border/60 bg-card/40 p-3 text-xs text-muted-foreground",
		children: "This expense was removed."
	});
	const isCreator = currentUserId === expense.created_by;
	const total = Number(expense.total_amount) || 0;
	const totalPaid = expense.shares.filter((s) => s.status === "paid").reduce((a, s) => a + Number(s.amount), 0);
	const pct = total > 0 ? Math.min(100, Math.round(totalPaid / total * 100)) : 0;
	const amounts = expense.shares.map((s) => Number(s.amount));
	const isEvenSplit = amounts.length > 0 && Math.max(...amounts) - Math.min(...amounts) <= .010000001;
	async function toggle(shareId, next) {
		try {
			await markShareStatus(shareId, next);
			await qc.invalidateQueries({ queryKey: ["expense", expenseId] });
		} catch (err) {
			toast.error(friendlyError(err, "Couldn't update payment status"));
		}
	}
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("article", {
		className: "w-full overflow-hidden rounded-2xl border border-border/60 bg-card shadow-sm",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", {
				className: "flex items-start justify-between gap-3 border-b border-border/60 bg-secondary/40 px-4 py-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "min-w-0",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-[10px] font-semibold uppercase tracking-wider text-primary",
						children: "Split Expense"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
						className: "mt-0.5 truncate text-sm font-semibold",
						children: expense.description
					})]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "text-right",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
						className: "flex items-center justify-end text-base font-bold tabular-nums",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(IndianRupee, { className: "h-3.5 w-3.5" }), Number(expense.total_amount).toFixed(2)]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-[10px] text-muted-foreground",
						children: isEvenSplit ? `₹${amounts[0].toFixed(2)} / person` : expense.shares.length > 0 ? `${expense.shares.length} members · custom split` : null
					})]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "px-4 pt-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "h-1.5 w-full overflow-hidden rounded-full bg-secondary",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "h-full rounded-full bg-emerald-500 transition-all",
						style: { width: `${pct}%` }
					})
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
					className: "mt-1.5 text-[11px] text-muted-foreground",
					children: [
						"₹",
						totalPaid.toFixed(2),
						" of ₹",
						Number(expense.total_amount).toFixed(2),
						" collected · ",
						pct,
						"%"
					]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
				className: "flex flex-col divide-y divide-border/60 px-2 py-2",
				children: expense.shares.map((s) => {
					const name = s.user?.full_name || s.user?.username || "Member";
					const isPaid = s.status === "paid";
					const isMine = s.user_id === currentUserId;
					const canToggle = isCreator || isMine;
					const upi = expense.upi_id;
					const upiHref = upi ? `upi://pay?pa=${encodeURIComponent(upi)}&pn=${encodeURIComponent(name)}&am=${Number(s.amount).toFixed(2)}&cu=INR&tn=${encodeURIComponent("tribeX Plan")}` : null;
					return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
						className: "flex items-center gap-3 px-2 py-2",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "flex h-8 w-8 shrink-0 items-center justify-center overflow-hidden rounded-full bg-secondary text-xs font-semibold",
								children: s.user?.avatar_url ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
									src: s.user.avatar_url,
									alt: "",
									className: "h-full w-full object-cover"
								}) : name.slice(0, 1).toUpperCase()
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "min-w-0 flex-1",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
									className: "truncate text-sm font-medium",
									children: [name, isMine && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "ml-1 text-[10px] text-muted-foreground",
										children: "(you)"
									})]
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
									className: "text-[11px] text-muted-foreground tabular-nums",
									children: ["₹", Number(s.amount).toFixed(2)]
								})]
							}),
							isPaid ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "inline-flex items-center gap-1 rounded-full bg-emerald-500/15 px-2 py-0.5 text-[10px] font-semibold text-emerald-600 dark:text-emerald-400",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "h-3 w-3" }), " Paid"]
							}) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "inline-flex items-center gap-1 rounded-full bg-amber-500/15 px-2 py-0.5 text-[10px] font-semibold text-amber-600 dark:text-amber-400",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Clock, { className: "h-3 w-3" }), " Pending"]
							}),
							!isPaid && isMine && upiHref && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
								href: upiHref,
								className: "ml-1 inline-flex items-center gap-1 rounded-full bg-primary px-2.5 py-1 text-[10px] font-semibold text-primary-foreground transition hover:opacity-90 active:scale-95",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Smartphone, { className: "h-3 w-3" }), " Pay via UPI"]
							}),
							canToggle && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								onClick: () => toggle(s.id, isPaid ? "pending" : "paid"),
								className: "ml-1 rounded-full border border-border/60 px-2 py-1 text-[10px] font-medium transition hover:bg-accent",
								children: isPaid ? "Undo" : "Mark paid"
							})
						]
					}, s.id);
				})
			}),
			!expense.upi_id && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "border-t border-border/60 px-4 py-2 text-[10px] text-muted-foreground",
				children: "Tip: add a UPI ID when creating an expense to enable one-tap payments."
			})
		]
	});
}
function isExpenseMessage(text) {
	const m = text.match(/^\[\[expense:([0-9a-fA-F-]{36})\]\]/);
	return m ? m[1] : null;
}
var Dialog = Dialog$1;
var DialogPortal = DialogPortal$1;
var DialogOverlay = import_react.forwardRef(({ className, ...props }, ref) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogOverlay$1, {
	ref,
	className: cn("fixed inset-0 z-[99998] bg-black/80 backdrop-blur-sm data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0", className),
	...props
}));
DialogOverlay.displayName = DialogOverlay$1.displayName;
var DialogContent = import_react.forwardRef(({ className, children, ...props }, ref) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogPortal, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogOverlay, {}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogContent$1, {
	ref,
	className: cn("fixed left-[50%] top-[50%] z-[99999] grid w-[90vw] max-w-md translate-x-[-50%] translate-y-[-50%] gap-4 border bg-background p-6 shadow-2xl duration-200 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 sm:rounded-lg", className),
	...props,
	children: [children, /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogClose, {
		className: "absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background cursor-pointer transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:pointer-events-none data-[state=open]:bg-accent data-[state=open]:text-muted-foreground",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
			className: "sr-only",
			children: "Close"
		})]
	})]
})] }));
DialogContent.displayName = DialogContent$1.displayName;
var DialogHeader = ({ className, ...props }) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
	className: cn("flex flex-col space-y-1.5 text-center sm:text-left", className),
	...props
});
DialogHeader.displayName = "DialogHeader";
var DialogFooter = ({ className, ...props }) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
	className: cn("flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2", className),
	...props
});
DialogFooter.displayName = "DialogFooter";
var DialogTitle = import_react.forwardRef(({ className, ...props }, ref) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogTitle$1, {
	ref,
	className: cn("text-lg font-semibold leading-none tracking-tight", className),
	...props
}));
DialogTitle.displayName = DialogTitle$1.displayName;
var DialogDescription = import_react.forwardRef(({ className, ...props }, ref) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogDescription$1, {
	ref,
	className: cn("text-sm text-muted-foreground", className),
	...props
}));
DialogDescription.displayName = DialogDescription$1.displayName;
function SplitExpenseModal({ activityId, open, onOpenChange, currentUserId }) {
	const qc = useQueryClient();
	const { data: members = [], isLoading } = useQuery({
		queryKey: ["plan-members", activityId],
		queryFn: () => listPlanMembers(activityId),
		enabled: open
	});
	const [description, setDescription] = (0, import_react.useState)("");
	const [amount, setAmount] = (0, import_react.useState)("");
	const [upi, setUpi] = (0, import_react.useState)("");
	const [splitType, setSplitType] = (0, import_react.useState)("equal");
	const [selected, setSelected] = (0, import_react.useState)(/* @__PURE__ */ new Set());
	const [saving, setSaving] = (0, import_react.useState)(false);
	const effectiveIds = (0, import_react.useMemo)(() => {
		if (splitType === "equal") return members.map((m) => m.id);
		return members.filter((m) => selected.has(m.id)).map((m) => m.id);
	}, [
		splitType,
		members,
		selected
	]);
	const perHead = (0, import_react.useMemo)(() => {
		const n = effectiveIds.length;
		const t = Number(amount);
		if (!n || !t || Number.isNaN(t)) return 0;
		return Math.round(t / n * 100) / 100;
	}, [amount, effectiveIds.length]);
	function reset() {
		setDescription("");
		setAmount("");
		setUpi("");
		setSplitType("equal");
		setSelected(/* @__PURE__ */ new Set());
	}
	async function onSubmit(e) {
		e.preventDefault();
		const total = Number(amount);
		if (!description.trim()) return toast.error("Add a description");
		if (!(total > 0)) return toast.error("Enter a valid amount");
		if (effectiveIds.length === 0) return toast.error("Select at least one member");
		if (upi.trim() && !/^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$/.test(upi.trim())) return toast.error("UPI ID looks invalid (e.g. name@upi)");
		setSaving(true);
		try {
			await createExpense({
				activityId,
				description: description.trim(),
				totalAmount: total,
				upiId: upi.trim() || null,
				memberIds: effectiveIds,
				splitType: "equal"
			});
			toast.success("Expense posted to chat");
			await qc.invalidateQueries({ queryKey: ["messages", activityId] });
			reset();
			onOpenChange(false);
		} catch (err) {
			toast.error(friendlyError(err, "Couldn't create expense"));
		} finally {
			setSaving(false);
		}
	}
	function toggle(id) {
		setSelected((prev) => {
			const next = new Set(prev);
			if (next.has(id)) next.delete(id);
			else next.add(id);
			return next;
		});
	}
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Dialog, {
		open,
		onOpenChange,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogContent, {
			className: "max-h-[90dvh] w-[calc(100vw-2rem)] max-w-md overflow-y-auto rounded-3xl p-0 sm:w-full",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogHeader, {
				className: "border-b border-border/60 px-5 pb-3 pt-5",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogTitle, {
					className: "text-base",
					children: "Split an expense"
				})
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
				onSubmit,
				className: "flex flex-col gap-4 px-5 py-4",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
						className: "flex flex-col gap-1.5",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-xs font-medium text-muted-foreground",
							children: "Description"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
							value: description,
							onChange: (e) => setDescription(e.target.value),
							maxLength: 120,
							placeholder: "Turf rent, Food & drinks…",
							className: "rounded-2xl border border-border/60 bg-background px-4 py-3 text-sm outline-none transition focus:border-primary"
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "grid grid-cols-2 gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
							className: "flex flex-col gap-1.5",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-xs font-medium text-muted-foreground",
								children: "Total amount"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex items-center gap-1 rounded-2xl border border-border/60 bg-background px-3 py-2.5 focus-within:border-primary",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(IndianRupee, { className: "h-4 w-4 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
									type: "number",
									step: "0.01",
									min: "0",
									inputMode: "decimal",
									value: amount,
									onChange: (e) => setAmount(e.target.value),
									placeholder: "0.00",
									className: "w-full bg-transparent text-sm outline-none tabular-nums"
								})]
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
							className: "flex flex-col gap-1.5",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-xs font-medium text-muted-foreground",
								children: "UPI ID (optional)"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
								value: upi,
								onChange: (e) => setUpi(e.target.value),
								placeholder: "name@upi",
								className: "rounded-2xl border border-border/60 bg-background px-3 py-2.5 text-sm outline-none transition focus:border-primary"
							})]
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex flex-col gap-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-xs font-medium text-muted-foreground",
							children: "Split"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "grid grid-cols-2 gap-2 rounded-2xl bg-secondary p-1",
							children: ["equal", "specific"].map((t) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: () => setSplitType(t),
								className: `rounded-xl px-3 py-2 text-xs font-semibold transition ${splitType === t ? "bg-background shadow-sm" : "text-muted-foreground"}`,
								children: t === "equal" ? "Split equally" : "Select members"
							}, t))
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "rounded-2xl border border-border/60",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center justify-between border-b border-border/60 px-3 py-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "flex items-center gap-1.5 text-xs font-medium text-muted-foreground",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Users, { className: "h-3.5 w-3.5" }),
									" Members (",
									effectiveIds.length,
									")"
								]
							}), perHead > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "text-[11px] font-semibold tabular-nums",
								children: [
									"₹",
									perHead.toFixed(2),
									" / person"
								]
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("ul", {
							className: "max-h-48 overflow-y-auto",
							children: [
								isLoading && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", {
									className: "px-3 py-4 text-xs text-muted-foreground",
									children: "Loading members…"
								}),
								!isLoading && members.length === 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", {
									className: "px-3 py-4 text-xs text-muted-foreground",
									children: "No confirmed members yet."
								}),
								members.map((m) => {
									const included = splitType === "equal" ? true : selected.has(m.id);
									const name = m.full_name || m.username || "Member";
									return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
										type: "button",
										disabled: splitType === "equal",
										onClick: () => toggle(m.id),
										className: `flex w-full items-center gap-3 px-3 py-2 text-left text-sm transition hover:bg-accent disabled:cursor-default disabled:hover:bg-transparent ${included ? "" : "opacity-60"}`,
										children: [
											/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
												className: "flex h-7 w-7 items-center justify-center overflow-hidden rounded-full bg-secondary text-[11px] font-semibold",
												children: m.avatar_url ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
													src: m.avatar_url,
													alt: "",
													className: "h-full w-full object-cover"
												}) : name.slice(0, 1).toUpperCase()
											}),
											/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
												className: "min-w-0 flex-1 truncate",
												children: [name, m.id === currentUserId && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
													className: "ml-1 text-[10px] text-muted-foreground",
													children: "(you)"
												})]
											}),
											/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
												className: `h-4 w-4 rounded border ${included ? "border-primary bg-primary" : "border-border"}`,
												children: included && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("svg", {
													viewBox: "0 0 24 24",
													className: "h-full w-full text-primary-foreground",
													children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", {
														fill: "currentColor",
														d: "M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z"
													})
												})
											})
										]
									}) }, m.id);
								})
							]
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center justify-end gap-2 pt-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							type: "button",
							onClick: () => onOpenChange(false),
							className: "rounded-full px-4 py-2 text-sm font-medium text-muted-foreground transition hover:bg-accent",
							children: "Cancel"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							type: "submit",
							disabled: saving,
							className: "rounded-full bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground transition hover:opacity-90 active:scale-95 disabled:opacity-60",
							children: saving ? "Posting…" : "Post to chat"
						})]
					})
				]
			})]
		})
	});
}
function MemoryBanner({ activity, canUpload, userId }) {
	const qc = useQueryClient();
	const [uploading, setUploading] = (0, import_react.useState)(false);
	const [sharing, setSharing] = (0, import_react.useState)(false);
	const inputRef = (0, import_react.useRef)(null);
	const start = new Date(activity.date_time).getTime();
	const end = start + 360 * 60 * 1e3;
	const isPast = Date.now() >= start + 10800 * 1e3;
	const { data: memories = [] } = useQuery({
		queryKey: ["event-memories", activity.id],
		queryFn: () => listEventMemories(activity.id),
		enabled: isPast,
		staleTime: 3e4
	});
	const latest = memories[0];
	async function handleFile(file) {
		if (!userId) return;
		setUploading(true);
		try {
			await uploadEventMemory(userId, activity.id, file);
			toast.success("Memory saved to the squad 📸");
			await qc.invalidateQueries({ queryKey: ["event-memories", activity.id] });
		} catch (err) {
			toast.error(friendlyError(err, "Couldn't upload photo"));
		} finally {
			setUploading(false);
		}
	}
	async function exportCard(mode) {
		if (!latest) return;
		setSharing(true);
		try {
			const blob = await renderMemoryCard({
				title: activity.title,
				category: activity.category,
				location: activity.location,
				date_time: activity.date_time,
				imageUrl: latest.image_url
			});
			if (mode === "share" && typeof navigator !== "undefined" && "share" in navigator) {
				const file = new File([blob], `tribeX-${activity.id}.png`, { type: "image/png" });
				const nav = navigator;
				if (nav.canShare?.({ files: [file] })) {
					await nav.share({
						files: [file],
						title: activity.title,
						text: `Played with tribeX Squad · ${activity.title}`
					});
					return;
				}
			}
			const url = URL.createObjectURL(blob);
			const a = document.createElement("a");
			a.href = url;
			a.download = `tribeX-${activity.title.replace(/[^a-z0-9]+/gi, "-")}.png`;
			a.click();
			setTimeout(() => URL.revokeObjectURL(url), 5e3);
			toast.success("Card downloaded — share your story!");
		} catch (err) {
			toast.error(friendlyError(err, "Couldn't export card"));
		} finally {
			setSharing(false);
		}
	}
	if (!isPast) return null;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "mb-3 overflow-hidden rounded-2xl border border-primary/30 bg-gradient-to-br from-primary/10 via-card to-card p-3",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-start gap-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/15 text-primary",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkles, { className: "h-4 w-4" })
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "min-w-0 flex-1",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs font-semibold uppercase tracking-wider text-primary",
						children: "Squad Memory"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-[11px] text-muted-foreground",
						children: latest ? "Your squad memory is ready. Share it to your story!" : Date.now() > end ? "The plan wrapped up — upload a photo to save this squad memory." : "Upload a photo from the plan to create a shareable memory card."
					})]
				})]
			}),
			latest && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "mt-3",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(MemoryCardPreview, {
					title: activity.title,
					category: activity.category,
					location: activity.location,
					date_time: activity.date_time,
					imageUrl: latest.image_url
				})
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "mt-3 flex flex-wrap gap-2",
				children: [canUpload && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
					ref: inputRef,
					type: "file",
					accept: "image/jpeg,image/png,image/webp",
					className: "hidden",
					onChange: (e) => {
						const f = e.target.files?.[0];
						if (f) handleFile(f);
						e.currentTarget.value = "";
					}
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					type: "button",
					onClick: () => inputRef.current?.click(),
					disabled: uploading,
					className: "inline-flex items-center gap-1.5 rounded-full bg-primary px-3 py-1.5 text-xs font-semibold text-primary-foreground transition hover:opacity-90 active:scale-95 disabled:opacity-60",
					children: [uploading ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-3.5 w-3.5 animate-spin" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Camera, { className: "h-3.5 w-3.5" }), uploading ? "Uploading…" : latest ? "Add another photo" : "Upload event photo"]
				})] }), latest && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					type: "button",
					onClick: () => exportCard("share"),
					disabled: sharing,
					className: "inline-flex items-center gap-1.5 rounded-full border border-border/60 bg-background px-3 py-1.5 text-xs font-semibold transition hover:bg-accent active:scale-95 disabled:opacity-60",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Share2, { className: "h-3.5 w-3.5" }), " Share card"]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					type: "button",
					onClick: () => exportCard("download"),
					disabled: sharing,
					className: "inline-flex items-center gap-1.5 rounded-full border border-border/60 bg-background px-3 py-1.5 text-xs font-semibold transition hover:bg-accent active:scale-95 disabled:opacity-60",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Download, { className: "h-3.5 w-3.5" }), " Download"]
				})] })]
			}),
			memories.length > 1 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "mt-3 flex gap-2 overflow-x-auto pb-1",
				children: memories.slice(1, 8).map((m) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
					src: m.image_url,
					alt: "",
					className: "h-14 w-14 shrink-0 rounded-lg object-cover",
					loading: "lazy"
				}, m.id))
			})
		]
	});
	function MemoryCardPreview(props) {
		const when = (0, import_react.useMemo)(() => new Date(props.date_time).toLocaleDateString([], {
			day: "numeric",
			month: "short",
			year: "numeric"
		}), [props.date_time]);
		const city = props.location.split(",").pop()?.trim() || props.location;
		return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "relative aspect-[4/5] w-full max-w-[220px] overflow-hidden rounded-2xl bg-black shadow-lg",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
					src: props.imageUrl,
					alt: "",
					className: "absolute inset-0 h-full w-full object-cover"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "absolute inset-0 bg-gradient-to-t from-black/85 via-black/20 to-black/40" }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "absolute right-2 top-2 rounded-full bg-white/95 px-2 py-0.5 text-[9px] font-black uppercase tracking-wider text-black",
					children: "tribeX"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "absolute inset-x-0 bottom-0 p-3 text-white",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
							className: "text-[10px] font-semibold uppercase tracking-widest text-white/70",
							children: [
								emojiFor(props.category),
								" ",
								props.category
							]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "mt-0.5 line-clamp-2 text-sm font-bold leading-tight",
							children: props.title
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
							className: "mt-1 text-[10px] text-white/80",
							children: [
								when,
								" · ",
								city
							]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "mt-2 inline-block rounded-full bg-white/15 px-2 py-0.5 text-[9px] font-bold uppercase tracking-wider backdrop-blur",
							children: "Played with tribeX Squad"
						})
					]
				})
			]
		});
	}
}
async function renderMemoryCard(data) {
	const W = 1080;
	const H = 1350;
	const canvas = document.createElement("canvas");
	canvas.width = W;
	canvas.height = H;
	const ctx = canvas.getContext("2d");
	if (!ctx) throw new Error("Canvas not supported");
	ctx.fillStyle = "#0F172A";
	ctx.fillRect(0, 0, W, H);
	const img = await loadImage(data.imageUrl);
	const ratio = Math.max(W / img.width, H / img.height);
	const iw = img.width * ratio;
	const ih = img.height * ratio;
	ctx.drawImage(img, (W - iw) / 2, (H - ih) / 2, iw, ih);
	const grad = ctx.createLinearGradient(0, 0, 0, H);
	grad.addColorStop(0, "rgba(15,23,42,0.55)");
	grad.addColorStop(.55, "rgba(15,23,42,0.15)");
	grad.addColorStop(1, "rgba(15,23,42,0.92)");
	ctx.fillStyle = grad;
	ctx.fillRect(0, 0, W, H);
	const badge = "tribeX";
	ctx.font = "800 42px 'Plus Jakarta Sans', system-ui, sans-serif";
	const bw = ctx.measureText(badge).width + 44;
	roundRect(ctx, W - bw - 40, 40, bw, 62, 999);
	ctx.fillStyle = "#FFFFFF";
	ctx.fill();
	ctx.fillStyle = "#0F172A";
	ctx.textBaseline = "middle";
	ctx.textAlign = "center";
	ctx.fillText(badge, W - 40 - bw / 2, 73);
	const catText = `${emojiFor(data.category)}  ${data.category.toUpperCase()}`;
	ctx.font = "700 32px system-ui, sans-serif";
	ctx.textAlign = "left";
	ctx.fillStyle = "rgba(255,255,255,0.75)";
	ctx.fillText(catText, 60, H - 380);
	ctx.font = "800 78px 'Plus Jakarta Sans', system-ui, sans-serif";
	ctx.fillStyle = "#FFFFFF";
	wrapText(ctx, data.title, 60, H - 300, W - 120, 88, 2);
	const when = new Date(data.date_time).toLocaleDateString([], {
		day: "numeric",
		month: "long",
		year: "numeric"
	});
	const city = data.location.split(",").pop()?.trim() || data.location;
	ctx.font = "500 34px system-ui, sans-serif";
	ctx.fillStyle = "rgba(255,255,255,0.82)";
	ctx.fillText(`${when}  ·  ${city}`, 60, H - 130);
	ctx.font = "800 26px 'Plus Jakarta Sans', system-ui, sans-serif";
	const pill = "PLAYED WITH TRIBEX SQUAD";
	const pw = ctx.measureText(pill).width + 44;
	roundRect(ctx, 60, H - 90, pw, 58, 999);
	ctx.fillStyle = "#6366F1";
	ctx.fill();
	ctx.fillStyle = "#FFFFFF";
	ctx.textBaseline = "middle";
	ctx.textAlign = "center";
	ctx.fillText(pill, 60 + pw / 2, 1291);
	return await new Promise((resolve, reject) => {
		canvas.toBlob((b) => b ? resolve(b) : reject(/* @__PURE__ */ new Error("Failed to export")), "image/png", .95);
	});
}
function loadImage(src) {
	return new Promise((resolve, reject) => {
		const im = new Image();
		im.crossOrigin = "anonymous";
		im.onload = () => resolve(im);
		im.onerror = () => reject(/* @__PURE__ */ new Error("Image load failed"));
		im.src = src;
	});
}
function roundRect(ctx, x, y, w, h, r) {
	const rr = Math.min(r, w / 2, h / 2);
	ctx.beginPath();
	ctx.moveTo(x + rr, y);
	ctx.arcTo(x + w, y, x + w, y + h, rr);
	ctx.arcTo(x + w, y + h, x, y + h, rr);
	ctx.arcTo(x, y + h, x, y, rr);
	ctx.arcTo(x, y, x + w, y, rr);
	ctx.closePath();
}
function wrapText(ctx, text, x, y, maxWidth, lineHeight, maxLines) {
	const words = text.split(/\s+/);
	const lines = [];
	let line = "";
	for (const w of words) {
		const test = line ? `${line} ${w}` : w;
		if (ctx.measureText(test).width > maxWidth && line) {
			lines.push(line);
			line = w;
			if (lines.length === maxLines) break;
		} else line = test;
	}
	if (line && lines.length < maxLines) lines.push(line);
	if (lines.length === maxLines) {
		let last = lines[maxLines - 1];
		if (ctx.measureText(last + "…").width > maxWidth) while (last.length > 0 && ctx.measureText(last + "…").width > maxWidth) last = last.slice(0, -1);
		lines[maxLines - 1] = last + (words.join(" ").length > lines.join(" ").length ? "…" : "");
	}
	lines.forEach((ln, i) => ctx.fillText(ln, x, y + i * lineHeight));
}
var Route$1 = createFileRoute("/chat/$activityId")({
	head: () => ({ meta: [{ title: "Chat · tribeX" }] }),
	component: ChatPage
});
function ChatPage() {
	const { activityId } = Route$1.useParams();
	const { user, loading } = useAuth();
	const navigate = useNavigate();
	const qc = useQueryClient();
	const [text, setText] = (0, import_react.useState)("");
	const [sending, setSending] = (0, import_react.useState)(false);
	const [splitOpen, setSplitOpen] = (0, import_react.useState)(false);
	const [attachOpen, setAttachOpen] = (0, import_react.useState)(false);
	const [reportOpen, setReportOpen] = (0, import_react.useState)(false);
	const [showLeaveConfirm, setShowLeaveConfirm] = (0, import_react.useState)(false);
	const [showBlockConfirm, setShowBlockConfirm] = (0, import_react.useState)(false);
	const [isLeaving, setIsLeaving] = (0, import_react.useState)(false);
	const bottomRef = (0, import_react.useRef)(null);
	const { data: activity, isLoading: isActivityLoading } = useQuery({
		queryKey: ["activity", activityId],
		queryFn: async () => {
			const { data, error } = await supabase.from("activities").select("id, title, category, location, date_time, host_id, latitude, longitude, host:profiles!activities_host_id_fkey(id, full_name, username, avatar_url)").eq("id", activityId).maybeSingle();
			if (error) throw error;
			return data;
		}
	});
	const { data: attendees = [], refetch: refetchAttendees } = useQuery({
		queryKey: ["attendees", activityId],
		queryFn: () => listAttendees(activityId),
		enabled: !!user
	});
	const { data: messages = [], isLoading, error, refetch } = useQuery({
		queryKey: ["messages", activityId],
		queryFn: () => listMessages(activityId),
		enabled: !!user,
		refetchInterval: 1e4
	});
	(0, import_react.useEffect)(() => {
		if (!activityId) return;
		const channel = supabase.channel(`chat-realtime:${activityId}`).on("postgres_changes", {
			event: "*",
			schema: "public",
			table: "messages",
			filter: `activity_id=eq.${activityId}`
		}, () => {
			qc.invalidateQueries({ queryKey: ["messages", activityId] });
		}).subscribe();
		return () => {
			supabase.removeChannel(channel);
		};
	}, [activityId, qc]);
	const blockMut = useMutation({
		mutationFn: (targetId) => blockUser(targetId),
		onSuccess: () => {
			toast.success("Host blocked");
			qc.invalidateQueries({ queryKey: ["blocked-ids", user?.id] });
			qc.invalidateQueries({ queryKey: ["activities"] });
			navigate({ to: "/" });
		},
		onError: (e) => toast.error(friendlyError(e))
	});
	(0, import_react.useEffect)(() => {
		bottomRef.current?.scrollIntoView({ behavior: "smooth" });
	}, [messages.length]);
	const canPost = !!user && !!activity;
	const hostName = activity?.host?.full_name || activity?.host?.username || "Host";
	const isHost = !!user && !!activity && activity.host_id === user.id;
	const myRequest = (0, import_react.useMemo)(() => user ? attendees.find((r) => r.user_id === user.id) : void 0, [attendees, user]);
	const isMember = isHost || !!myRequest;
	const when = (0, import_react.useMemo)(() => {
		if (!activity?.date_time) return "";
		return new Date(activity.date_time).toLocaleString([], {
			weekday: "short",
			month: "short",
			day: "numeric",
			hour: "numeric",
			minute: "2-digit"
		});
	}, [activity?.date_time]);
	if (!loading && !user) return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex flex-col items-start gap-4 px-5 pt-8",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
				className: "text-2xl font-bold tracking-tight",
				children: "Sign in to chat"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "text-sm text-muted-foreground",
				children: "You need an account to message hosts and squads."
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
				onClick: () => navigate({ to: "/auth" }),
				className: "rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground",
				children: "Sign in"
			})
		]
	});
	if (isActivityLoading) return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PageLoader, { label: "Opening chat" });
	async function onSend(e) {
		e.preventDefault();
		const trimmed = text.trim();
		if (!trimmed || !canPost) return;
		setSending(true);
		try {
			await sendMessage(activityId, trimmed);
			setText("");
			await qc.invalidateQueries({ queryKey: ["messages", activityId] });
		} catch (err) {
			toast.error(friendlyError(err, "Couldn't send message"));
		} finally {
			setSending(false);
		}
	}
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex h-dvh flex-col",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", {
				className: "flex shrink-0 items-center gap-3 border-b border-border/60 bg-background/90 px-4 py-3 backdrop-blur",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
						to: "/messages",
						className: "rounded-full p-1.5 transition hover:bg-accent active:scale-95",
						"aria-label": "Back",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowLeft, { className: "h-4 w-4" })
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-secondary text-lg",
						children: activity ? emojiFor(activity.category) : "💬"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "min-w-0 flex-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
							className: "truncate text-sm font-semibold",
							children: activity?.title ?? "Chat"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
							className: "flex items-center gap-2 truncate text-[11px] text-muted-foreground",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
									className: "truncate",
									children: ["Host · ", hostName]
								}),
								activity?.location && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
									className: "hidden items-center gap-0.5 sm:inline-flex",
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPin, { className: "h-3 w-3" }),
										" ",
										activity.location
									]
								}),
								when && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
									className: "hidden items-center gap-0.5 sm:inline-flex",
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Clock, { className: "h-3 w-3" }),
										" ",
										when
									]
								})
							]
						})]
					}),
					!isHost && activity?.host_id && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center gap-1.5",
						children: [
							myRequest && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								onClick: () => setShowLeaveConfirm(true),
								className: "flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-destructive/60 hover:text-destructive active:scale-95",
								title: "Leave plan",
								"aria-label": "Leave plan",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LogOut, { className: "h-3.5 w-3.5" })
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								onClick: () => setReportOpen(true),
								className: "flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-destructive/60 hover:text-destructive active:scale-95",
								title: "Report content or user",
								"aria-label": "Report",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Flag, { className: "h-3.5 w-3.5" })
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								onClick: () => setShowBlockConfirm(true),
								disabled: blockMut.isPending,
								className: "flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-destructive/60 hover:text-destructive active:scale-95",
								title: `Block ${hostName}`,
								"aria-label": `Block ${hostName}`,
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(UserX, { className: "h-4 w-4" })
							})
						]
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex-1 min-h-0 overflow-y-auto px-4 py-4",
				children: [
					activity && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CheckInPanel, {
						activity,
						isHost,
						attendees,
						myRequest,
						onChanged: () => refetchAttendees()
					}),
					activity && isMember && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(MemoryBanner, {
						activity,
						canUpload: isMember,
						userId: user?.id
					}),
					isLoading ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "flex flex-col gap-2",
						children: [
							0,
							1,
							2
						].map((i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-12 animate-pulse rounded-2xl bg-card" }, i))
					}) : error ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "rounded-2xl border border-destructive/40 bg-destructive/10 p-4 text-sm text-destructive",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "mb-2",
							children: friendlyError(error, "Couldn't load messages.")
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: () => refetch(),
							className: "rounded-full bg-destructive px-3 py-1.5 text-xs font-semibold text-destructive-foreground",
							children: "Retry"
						})]
					}) : messages.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mt-10 rounded-3xl border border-dashed border-border bg-card/40 p-6 text-center text-sm text-muted-foreground",
						children: [
							"No messages yet. Say hi to ",
							hostName,
							" 👋"
						]
					}) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("ul", {
						className: "flex flex-col gap-2",
						children: [messages.map((m) => {
							const expId = isExpenseMessage(m.text);
							if (expId) return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("li", {
								className: "flex justify-center",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "w-full max-w-sm",
									children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ExpenseCard, {
										expenseId: expId,
										currentUserId: user?.id
									})
								})
							}, m.id);
							return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(MessageBubble, {
								m,
								mine: m.sender_id === user.id
							}, m.id);
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { ref: bottomRef })]
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
				onSubmit: onSend,
				className: "relative shrink-0 flex items-center gap-2 border-t border-border/60 bg-background px-4 py-3",
				children: [
					attachOpen && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						type: "button",
						"aria-label": "Close attach menu",
						onClick: () => setAttachOpen(false),
						className: "fixed inset-0 z-30 cursor-default bg-transparent"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "absolute bottom-full left-3 z-40 mb-2 w-56 overflow-hidden rounded-2xl border border-border/60 bg-popover shadow-xl",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
							type: "button",
							onClick: () => {
								setAttachOpen(false);
								setSplitOpen(true);
							},
							className: "flex w-full items-center gap-3 px-4 py-3 text-left text-sm transition hover:bg-accent",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "flex h-8 w-8 items-center justify-center rounded-full bg-emerald-500/15 text-emerald-500",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(IndianRupee, { className: "h-4 w-4" })
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "block font-semibold",
								children: "Split expense"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "block text-[11px] text-muted-foreground",
								children: "Post a bill with UPI split"
							})] })]
						})
					})] }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						type: "button",
						onClick: () => setAttachOpen((v) => !v),
						disabled: !canPost,
						title: "Add",
						"aria-label": "Add attachment",
						"aria-expanded": attachOpen,
						className: `flex h-11 w-11 shrink-0 items-center justify-center rounded-full border border-border/60 bg-card text-foreground transition hover:bg-accent active:scale-95 disabled:opacity-50 ${attachOpen ? "rotate-45" : ""}`,
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Plus, { className: "h-5 w-5" })
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
						value: text,
						onChange: (e) => setText(e.target.value),
						placeholder: canPost ? `Message ${hostName}…` : "Join this plan to chat",
						maxLength: 1e3,
						disabled: !canPost || sending,
						className: "flex-1 rounded-full border border-border/60 bg-card px-4 py-3 text-sm outline-none transition focus:border-primary disabled:opacity-60"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						type: "submit",
						disabled: !canPost || sending || !text.trim(),
						className: "flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground transition hover:scale-105 active:scale-95 disabled:opacity-50 disabled:hover:scale-100",
						"aria-label": "Send",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Send, { className: "h-4 w-4" })
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SplitExpenseModal, {
				activityId,
				open: splitOpen,
				onOpenChange: setSplitOpen,
				currentUserId: user?.id
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ReportModal, {
				open: reportOpen,
				onClose: () => setReportOpen(false),
				targetType: "activity",
				targetId: activityId,
				targetTitle: activity?.title ?? "Activity"
			}),
			showLeaveConfirm && typeof document !== "undefined" && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
				onClick: () => !isLeaving && setShowLeaveConfirm(false),
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					onClick: (e) => e.stopPropagation(),
					className: "fixed left-1/2 top-1/2 z-[99999] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex flex-col items-center gap-3 text-center",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "flex h-12 w-12 items-center justify-center rounded-full bg-destructive/15 text-destructive",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LogOut, { className: "h-6 w-6" })
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
								className: "text-lg font-bold text-foreground",
								children: "Leave this plan?"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm text-muted-foreground leading-relaxed",
								children: "You will be removed from this plan and will lose access to the squad chat."
							})
						]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mt-6 flex flex-col gap-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							disabled: isLeaving,
							onClick: async () => {
								setIsLeaving(true);
								try {
									await leaveActivity(activityId);
									toast.success("You left the plan");
									qc.invalidateQueries({ queryKey: ["user-activities", user?.id] });
									qc.invalidateQueries({ queryKey: ["activities"] });
									navigate({ to: "/messages" });
								} catch (err) {
									toast.error(friendlyError(err, "Couldn't leave plan"));
									setIsLeaving(false);
									setShowLeaveConfirm(false);
								}
							},
							className: "w-full rounded-full bg-destructive py-2.5 text-sm font-semibold text-destructive-foreground transition hover:opacity-90 active:scale-95 disabled:opacity-50",
							children: isLeaving ? "Leaving…" : "Yes, Leave Plan"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							disabled: isLeaving,
							onClick: () => setShowLeaveConfirm(false),
							className: "w-full rounded-full border border-border/60 py-2.5 text-sm font-semibold transition hover:bg-accent",
							children: "Cancel"
						})]
					})]
				})
			}), document.body),
			showBlockConfirm && typeof document !== "undefined" && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
				onClick: () => !blockMut.isPending && setShowBlockConfirm(false),
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					onClick: (e) => e.stopPropagation(),
					className: "fixed left-1/2 top-1/2 z-[99999] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex flex-col items-center gap-3 text-center",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "flex h-12 w-12 items-center justify-center rounded-full bg-destructive/15 text-destructive",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShieldAlert, { className: "h-6 w-6" })
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h3", {
								className: "text-lg font-bold text-foreground",
								children: [
									"Block ",
									hostName,
									"?"
								]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm text-muted-foreground leading-relaxed",
								children: "You won't see their events or messages anymore. You can unblock them anytime from Settings."
							})
						]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mt-6 flex flex-col gap-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							disabled: blockMut.isPending,
							onClick: () => {
								if (activity?.host_id) blockMut.mutate(activity.host_id);
							},
							className: "w-full rounded-full bg-destructive py-2.5 text-sm font-semibold text-destructive-foreground transition hover:opacity-90 active:scale-95 disabled:opacity-50",
							children: blockMut.isPending ? "Blocking…" : `Yes, Block ${hostName}`
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							disabled: blockMut.isPending,
							onClick: () => setShowBlockConfirm(false),
							className: "w-full rounded-full border border-border/60 py-2.5 text-sm font-semibold transition hover:bg-accent",
							children: "Cancel"
						})]
					})]
				})
			}), document.body)
		]
	});
}
function MessageBubble({ m, mine }) {
	const time = new Date(m.created_at).toLocaleTimeString([], {
		hour: "numeric",
		minute: "2-digit"
	});
	const rawName = m.sender?.full_name?.trim();
	const rawUname = m.sender?.username?.trim();
	const senderName = !(!rawName || [
		"user",
		"squad member",
		"squad mate",
		"unknown user"
	].includes(rawName.toLowerCase())) ? rawName : rawUname ? `@${rawUname}` : mine ? "You" : "Member";
	const avatarUrl = m.sender?.avatar_url;
	const initial = (senderName.replace(/^@/, "") || "U")[0]?.toUpperCase() ?? "U";
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
		className: `flex gap-2 ${mine ? "justify-end" : "justify-start"}`,
		children: [!mine && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "flex h-7 w-7 shrink-0 items-center justify-center overflow-hidden rounded-full bg-primary/15 text-[10px] font-bold text-primary self-end mb-1",
			children: avatarUrl ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
				src: avatarUrl,
				alt: "",
				className: "h-full w-full object-cover"
			}) : initial
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: `max-w-[80%] rounded-2xl px-4 py-2 text-sm ${mine ? "bg-primary text-primary-foreground" : "bg-card border border-border/60"}`,
			children: [
				!mine && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "mb-0.5 text-[11px] font-semibold text-primary",
					children: senderName
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "whitespace-pre-wrap break-words",
					children: m.text
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: `mt-1 text-[10px] ${mine ? "text-primary-foreground/70" : "text-muted-foreground"}`,
					children: time
				})
			]
		})]
	});
}
function CheckInPanel({ activity, isHost, attendees, myRequest, onChanged }) {
	const [busy, setBusy] = (0, import_react.useState)(false);
	const [busyNoShow, setBusyNoShow] = (0, import_react.useState)(null);
	const hasPin = activity.latitude !== null && activity.longitude !== null;
	const start = new Date(activity.date_time).getTime();
	const now = Date.now();
	const inWindow = now >= start - 7200 * 1e3 && now <= start + 360 * 60 * 1e3;
	const canCheckIn = hasPin && inWindow && !isHost && !!myRequest && !myRequest.checked_in_at && !myRequest.no_show;
	const alreadyCheckedIn = !isHost && !!myRequest?.checked_in_at;
	async function handleCheckIn() {
		setBusy(true);
		try {
			const res = await checkInActivity(activity.id);
			if (res.status === "checked_in") {
				toast.success(`✅ Checked in · ${Math.round(res.distance_m)} m from venue`);
				onChanged();
			} else if (res.status === "already") toast.info("You're already checked in for this plan.");
			else if (res.status === "too_far") toast.error(`Too far — you're ${Math.round(res.distance_m)} m from the venue (150 m limit).`);
		} catch (err) {
			toast.error(friendlyError(err, "Couldn't check you in"));
		} finally {
			setBusy(false);
		}
	}
	async function handleNoShow(reqId) {
		setBusyNoShow(reqId);
		try {
			await markNoShow(reqId);
			toast.success("Marked as no-show");
			onChanged();
		} catch (err) {
			toast.error(friendlyError(err, "Couldn't update attendee"));
		} finally {
			setBusyNoShow(null);
		}
	}
	if (!hasPin && !isHost) return null;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "mb-3 rounded-2xl border border-border/60 bg-card p-3",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "flex items-start justify-between gap-3",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "min-w-0",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
						className: "flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShieldCheck, { className: "h-3.5 w-3.5 text-primary" }), " Venue check-in"]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "mt-0.5 text-[11px] text-muted-foreground",
						children: !hasPin ? "Host hasn't pinned the venue coordinates yet." : alreadyCheckedIn ? "You're verified as present. Enjoy the plan!" : inWindow ? "Tap check-in when you arrive (must be within 150 m)." : "Opens 2 hours before the plan starts."
					})]
				}),
				canCheckIn && !alreadyCheckedIn && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					onClick: handleCheckIn,
					disabled: busy,
					className: "flex shrink-0 items-center gap-1.5 rounded-full bg-primary px-3 py-1.5 text-xs font-semibold text-primary-foreground transition hover:scale-105 active:scale-95 disabled:opacity-50 disabled:hover:scale-100",
					children: [busy ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-3.5 w-3.5 animate-spin" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(MapPinned, { className: "h-3.5 w-3.5" }), busy ? "Checking…" : "Check in"]
				}),
				alreadyCheckedIn && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
					className: "flex shrink-0 items-center gap-1 rounded-full bg-green-500/15 px-3 py-1.5 text-xs font-semibold text-green-600 dark:text-green-400",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CircleCheck, { className: "h-3.5 w-3.5" }), " Verified"]
				})
			]
		}), isHost && attendees.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "mt-3 flex flex-col gap-1.5 border-t border-border/60 pt-3",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "text-[10px] font-semibold uppercase tracking-wider text-muted-foreground",
				children: "Attendee roster"
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
				className: "flex flex-col gap-1.5",
				children: attendees.map((r) => {
					const name = r.user?.full_name || r.user?.username || "Player";
					const verified = !!r.checked_in_at;
					const noShow = r.no_show;
					return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
						className: "flex items-center gap-2 rounded-xl bg-background/60 px-2.5 py-1.5",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "flex h-7 w-7 shrink-0 items-center justify-center overflow-hidden rounded-full bg-primary/15 text-[10px] font-bold text-primary",
								children: r.user?.avatar_url ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
									src: r.user.avatar_url,
									alt: "",
									className: "h-full w-full object-cover"
								}) : name[0]?.toUpperCase()
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "min-w-0 flex-1 truncate text-xs",
								children: name
							}),
							verified ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "flex items-center gap-1 rounded-full bg-green-500/15 px-2 py-0.5 text-[10px] font-semibold text-green-600 dark:text-green-400",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CircleCheck, { className: "h-3 w-3" }), " Verified"]
							}) : noShow ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "flex items-center gap-1 rounded-full bg-red-500/15 px-2 py-0.5 text-[10px] font-semibold text-red-600 dark:text-red-400",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(UserX, { className: "h-3 w-3" }), " No-show"]
							}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "rounded-full bg-secondary px-2 py-0.5 text-[10px] font-semibold text-muted-foreground",
								children: "Pending"
							}),
							!verified && !noShow && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								onClick: () => handleNoShow(r.id),
								disabled: busyNoShow === r.id,
								title: "Mark as no-show",
								className: "rounded-full border border-border/60 px-2 py-0.5 text-[10px] font-semibold text-muted-foreground transition hover:border-red-500/60 hover:text-red-500 active:scale-95 disabled:opacity-50",
								children: busyNoShow === r.id ? "…" : "No-show"
							})
						]
					}, r.id);
				})
			})]
		})]
	});
}
var Route = createFileRoute("/profile/settings")({
	head: () => ({ meta: [{ title: "Settings · tribeX" }, {
		name: "description",
		content: "Manage your account, notifications, and privacy."
	}] }),
	component: SettingsPage
});
function SettingsPage() {
	const { data: session, isLoading: isSessionLoading } = useQuery({
		queryKey: ["session"],
		queryFn: async () => {
			const { data } = await supabase.auth.getSession();
			return data.session;
		}
	});
	const user = session?.user;
	const navigate = useNavigate();
	const qc = useQueryClient();
	const { data: profile, isLoading: isProfileLoading } = useQuery({
		queryKey: ["profile", user?.id],
		queryFn: () => getProfile(user.id),
		enabled: !!user
	});
	const { data: blockedUsers = [] } = useQuery({
		queryKey: ["blocked-users", user?.id],
		queryFn: () => listBlockedUsers(user.id),
		enabled: !!user
	});
	const [showEditDetails, setShowEditDetails] = (0, import_react.useState)(false);
	const [savingEdit, setSavingEdit] = (0, import_react.useState)(false);
	const [fetchingGps, setFetchingGps] = (0, import_react.useState)(false);
	const [editDraft, setEditDraft] = (0, import_react.useState)({
		full_name: "",
		phone: "",
		gender: "",
		city: "",
		bio: "",
		username: ""
	});
	const [uploading, setUploading] = (0, import_react.useState)(false);
	const fileRef = (0, import_react.useRef)(null);
	const [modalAvatarFile, setModalAvatarFile] = (0, import_react.useState)(null);
	const [modalAvatarPreview, setModalAvatarPreview] = (0, import_react.useState)(null);
	const [modalAvatarRemoved, setModalAvatarRemoved] = (0, import_react.useState)(false);
	const modalFileRef = (0, import_react.useRef)(null);
	const [pushOn, setPushOn] = (0, import_react.useState)(false);
	const [pushBusy, setPushBusy] = (0, import_react.useState)(false);
	const [showBlockedModal, setShowBlockedModal] = (0, import_react.useState)(false);
	const [showFaq, setShowFaq] = (0, import_react.useState)(false);
	const [openFaqIndex, setOpenFaqIndex] = (0, import_react.useState)(null);
	const [showReportModal, setShowReportModal] = (0, import_react.useState)(false);
	const [reportText, setReportText] = (0, import_react.useState)("");
	const [submittingReport, setSubmittingReport] = (0, import_react.useState)(false);
	const [showFeedbackModal, setShowFeedbackModal] = (0, import_react.useState)(false);
	const [feedbackRating, setFeedbackRating] = (0, import_react.useState)(5);
	const [feedbackText, setFeedbackText] = (0, import_react.useState)("");
	const [submittingFeedback, setSubmittingFeedback] = (0, import_react.useState)(false);
	const [showDeleteConfirm, setShowDeleteConfirm] = (0, import_react.useState)(false);
	const [showDeleteFinal, setShowDeleteFinal] = (0, import_react.useState)(false);
	const [deleteInput, setDeleteInput] = (0, import_react.useState)("");
	const unblockMut = useMutation({
		mutationFn: (targetId) => unblockUser(targetId),
		onSuccess: () => {
			toast.success("User unblocked");
			qc.invalidateQueries({ queryKey: ["blocked-users", user?.id] });
			qc.invalidateQueries({ queryKey: ["blocked-ids", user?.id] });
			qc.invalidateQueries({ queryKey: ["activities"] });
		},
		onError: (e) => toast.error(friendlyError(e))
	});
	(0, import_react.useEffect)(() => {
		if (!user) return;
		getPushStatus().then((s) => setPushOn(s.optedIn && s.permission === "granted")).catch(() => {});
	}, [user]);
	async function togglePush() {
		if (!isOneSignalConfigured()) {
			setPushOn(false);
			toast("Push notifications are available on the mobile app!");
			return;
		}
		if (typeof window !== "undefined" && !("Notification" in window)) {
			setPushOn(false);
			toast("Push notifications are available on the mobile app!");
			return;
		}
		setPushBusy(true);
		try {
			if (pushOn) {
				await disablePushForCurrentUser();
				setPushOn(false);
				toast.success("Push notifications turned off");
			} else {
				const res = await requestPushPermission();
				if (res.status === "granted") {
					setPushOn(true);
					toast.success("Push notifications enabled");
				} else {
					setPushOn(false);
					if (res.status === "denied") toast.error("Notifications blocked", {
						description: res.message,
						duration: 8e3
					});
					else if (res.status === "dismissed") toast("Notifications not enabled", { description: res.message });
					else if (res.status === "unsupported") toast("Push notifications are available on the mobile app!");
					else toast.error(res.message);
				}
			}
		} catch (e) {
			setPushOn(false);
			toast("Push notifications are available on the mobile app!", { description: e instanceof Error ? e.message : void 0 });
		} finally {
			setPushBusy(false);
		}
	}
	async function onPickAvatar(e) {
		const file = e.target.files?.[0];
		e.target.value = "";
		if (!file || !user) return;
		if (!file.type.startsWith("image/")) {
			toast.error("Pick an image file");
			return;
		}
		if (file.size > 5 * 1024 * 1024) {
			toast.error("Image must be under 5MB");
			return;
		}
		setUploading(true);
		try {
			await uploadAvatar(user.id, file);
			await qc.invalidateQueries({ queryKey: ["profile", user.id] });
			toast.success("Avatar updated");
		} catch (err) {
			toast.error(friendlyError(err));
		} finally {
			setUploading(false);
		}
	}
	function onPickModalAvatar(e) {
		const file = e.target.files?.[0];
		e.target.value = "";
		if (!file) return;
		if (!file.type.startsWith("image/")) {
			toast.error("Pick an image file (JPG, PNG, or WebP)");
			return;
		}
		if (file.size > 5 * 1024 * 1024) {
			toast.error("Image must be under 5MB");
			return;
		}
		setModalAvatarFile(file);
		setModalAvatarPreview(URL.createObjectURL(file));
		setModalAvatarRemoved(false);
	}
	async function onRemoveAvatar() {
		if (!user) return;
		setUploading(true);
		try {
			await removeAvatar(user.id);
			await qc.invalidateQueries({ queryKey: ["profile", user.id] });
			toast.success("Photo removed");
		} catch (err) {
			toast.error(friendlyError(err));
		} finally {
			setUploading(false);
		}
	}
	function openEdit() {
		setEditDraft({
			full_name: profile?.full_name ?? "",
			phone: profile?.phone ?? "",
			gender: profile?.gender ?? "",
			city: profile?.city ?? "",
			bio: profile?.bio ?? "",
			username: profile?.username ?? ""
		});
		setModalAvatarFile(null);
		setModalAvatarPreview(profile?.avatar_url ?? null);
		setModalAvatarRemoved(false);
		setShowEditDetails(true);
	}
	async function saveEdit(e) {
		e.preventDefault();
		if (!user) return;
		const name = editDraft.full_name.trim();
		const uname = editDraft.username.trim().toLowerCase();
		if (!name) {
			toast.error("Name can't be empty");
			return;
		}
		if (!uname || uname.length < 3) {
			toast.error("Username must be at least 3 characters");
			return;
		}
		if (editDraft.phone && !/^\+?[\d\s-]{7,15}$/.test(editDraft.phone.trim())) {
			toast.error("Enter a valid phone number");
			return;
		}
		setSavingEdit(true);
		try {
			if (modalAvatarRemoved) await removeAvatar(user.id);
			else if (modalAvatarFile) await uploadAvatar(user.id, modalAvatarFile);
			await updateProfile(user.id, {
				full_name: name,
				username: uname,
				phone: editDraft.phone.trim() || null,
				gender: editDraft.gender || null,
				city: editDraft.city || null,
				bio: editDraft.bio.trim() || null
			});
			await qc.invalidateQueries({ queryKey: ["profile", user.id] });
			setShowEditDetails(false);
			toast.success("Profile updated");
		} catch (err) {
			toast.error(friendlyError(err));
		} finally {
			setSavingEdit(false);
		}
	}
	async function handleFetchProfileGPS() {
		if (!user) return;
		setFetchingGps(true);
		try {
			const updated = await saveVerifiedProfileLocation(user.id);
			setEditDraft((d) => ({
				...d,
				city: updated.city ?? ""
			}));
			await qc.invalidateQueries({ queryKey: ["profile", user.id] });
			toast.success("Profile location verified");
		} catch (err) {
			toast.error(friendlyError(err, "Couldn't fetch your location"));
		} finally {
			setFetchingGps(false);
		}
	}
	const handleReportSubmit = async (e) => {
		e.preventDefault();
		if (!reportText.trim()) return;
		setSubmittingReport(true);
		await new Promise((resolve) => setTimeout(resolve, 800));
		setSubmittingReport(false);
		setShowReportModal(false);
		setReportText("");
		toast.success("Issue reported! Our support team will look into it.");
	};
	const handleFeedbackSubmit = async (e) => {
		e.preventDefault();
		setSubmittingFeedback(true);
		await new Promise((resolve) => setTimeout(resolve, 800));
		setSubmittingFeedback(false);
		setShowFeedbackModal(false);
		setFeedbackText("");
		toast.success("Thank you for your feedback!");
	};
	const deleteAccountMut = useMutation({
		mutationFn: async () => {
			const { data, error } = await supabase.rpc("delete_user_account");
			if (error) throw error;
			return data;
		},
		onSuccess: async () => {
			toast.success("Account permanently deleted");
			await qc.cancelQueries();
			qc.clear();
			await supabase.auth.signOut();
			navigate({
				to: "/",
				replace: true
			});
		},
		onError: (e) => {
			toast.error(friendlyError(e, "Account deletion failed. Try again later."));
		}
	});
	const handleDeleteFinalConfirm = () => {
		if (deleteInput.trim().toUpperCase() !== "DELETE") {
			toast.error("Please type DELETE to confirm");
			return;
		}
		setShowDeleteFinal(false);
		deleteAccountMut.mutate();
	};
	if (isSessionLoading || user && isProfileLoading) return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PageLoader, { label: "Loading settings" });
	const displayName = profile?.full_name || profile?.username || "You";
	const initial = (displayName[0] ?? "U").toUpperCase();
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "page-in flex flex-col gap-5 px-5 pt-6 pb-20",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", {
				className: "flex items-center gap-3",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
					to: "/profile",
					className: "flex h-9 w-9 items-center justify-center rounded-full border border-border/60 bg-card transition hover:bg-accent active:scale-95",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowLeft, { className: "h-4 w-4" })
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-[10px] font-medium uppercase tracking-[0.18em] text-muted-foreground",
					children: "Settings"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
					className: "text-xl font-bold tracking-tight",
					children: "Account & Security"
				})] })]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "rounded-3xl border border-border/60 bg-card p-5",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
						className: "mb-4 text-xs font-semibold uppercase tracking-wider text-muted-foreground",
						children: "Account Profile"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center gap-4 border-b border-border/60 pb-5",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "relative shrink-0",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "flex h-16 w-16 items-center justify-center overflow-hidden rounded-full bg-primary text-2xl font-bold text-primary-foreground",
									children: profile?.avatar_url ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
										src: profile.avatar_url,
										alt: "",
										className: "h-full w-full object-cover"
									}) : initial
								}),
								profile?.avatar_url && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
									type: "button",
									onClick: onRemoveAvatar,
									disabled: uploading,
									className: "absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full border border-border bg-destructive text-destructive-foreground shadow transition hover:scale-105 active:scale-95 disabled:opacity-60",
									"aria-label": "Remove avatar",
									title: "Remove photo",
									children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-3 w-3" })
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
									type: "button",
									onClick: () => fileRef.current?.click(),
									disabled: uploading,
									className: "absolute -bottom-1 -right-1 flex h-7 w-7 items-center justify-center rounded-full border border-border bg-background text-foreground shadow transition hover:scale-105 active:scale-95 disabled:opacity-60",
									"aria-label": "Change avatar",
									children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Camera, { className: "h-3.5 w-3.5" })
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
									ref: fileRef,
									type: "file",
									accept: "image/*",
									className: "hidden",
									onChange: onPickAvatar
								})
							]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "min-w-0 flex-1",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
									className: "truncate text-lg font-semibold",
									children: displayName
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-xs text-muted-foreground truncate",
									children: user?.email || "No email linked"
								}),
								profile?.username && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
									className: "text-xs text-primary font-medium",
									children: ["@", profile.username]
								})
							]
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "mt-4 flex flex-col gap-2",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
							onClick: openEdit,
							className: "flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99]",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "flex items-center gap-3",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(User, { className: "h-4 w-4 text-primary" }), "Edit Basic Details"]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronRight, { className: "h-4 w-4 text-muted-foreground" })]
						})
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "rounded-3xl border border-border/60 bg-card p-5",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "mb-4 text-xs font-semibold uppercase tracking-wider text-muted-foreground",
					children: "Notifications"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					onClick: togglePush,
					disabled: pushBusy,
					className: "flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99] disabled:opacity-60",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
						className: "flex items-center gap-3",
						children: [pushOn ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Bell, { className: "h-4 w-4 text-primary" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BellOff, { className: "h-4 w-4 text-muted-foreground" }), "Push Notifications"]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
						className: `text-xs font-bold ${pushOn ? "text-primary" : "text-muted-foreground"}`,
						children: pushOn ? "ENABLED" : "DISABLED"
					})]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "rounded-3xl border border-border/60 bg-card p-5",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "mb-4 text-xs font-semibold uppercase tracking-wider text-muted-foreground",
					children: "Privacy"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					onClick: () => setShowBlockedModal(true),
					className: "flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99]",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
						className: "flex items-center gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(UserX, { className: "h-4 w-4 text-primary" }), "Blocked Users"]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
						className: "text-xs font-bold text-muted-foreground",
						children: [blockedUsers.length, " active"]
					})]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "rounded-3xl border border-border/60 bg-card p-5",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "mb-4 text-xs font-semibold uppercase tracking-wider text-muted-foreground",
					children: "Help & Support"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex flex-col gap-2",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
							onClick: () => setShowFaq(true),
							className: "flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99]",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "flex items-center gap-3",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(LifeBuoy, { className: "h-4 w-4 text-primary" }), "Frequently Asked Questions (FAQ)"]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronRight, { className: "h-4 w-4 text-muted-foreground" })]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
							onClick: () => setShowReportModal(true),
							className: "flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99]",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "flex items-center gap-3",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShieldAlert, { className: "h-4 w-4 text-primary" }), "Report a Problem"]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronRight, { className: "h-4 w-4 text-muted-foreground" })]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
							onClick: () => setShowFeedbackModal(true),
							className: "flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99]",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "flex items-center gap-3",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Info, { className: "h-4 w-4 text-primary" }), "Send Feedback"]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronRight, { className: "h-4 w-4 text-muted-foreground" })]
						})
					]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "rounded-3xl border border-border/60 bg-card p-5",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "mb-4 text-xs font-semibold uppercase tracking-wider text-muted-foreground",
					children: "Legal"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Link, {
					to: "/terms-and-policies",
					className: "flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99]",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
						className: "flex items-center gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FileText, { className: "h-4 w-4 text-primary" }), "Terms & Privacy Policy"]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronRight, { className: "h-4 w-4 text-muted-foreground" })]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "rounded-3xl border border-border/60 bg-card p-5",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "mb-4 text-xs font-semibold uppercase tracking-wider text-muted-foreground text-destructive",
					children: "Danger Zone"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
					onClick: () => setShowDeleteConfirm(true),
					className: "flex items-center justify-between w-full rounded-2xl border border-destructive/30 bg-destructive/5 hover:bg-destructive/10 px-4 py-3.5 text-sm font-bold text-destructive transition active:scale-[0.99]",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
						className: "flex items-center gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trash2, { className: "h-4 w-4" }), "Delete Account"]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronRight, { className: "h-4 w-4" })]
				})]
			}),
			showEditDetails && typeof document !== "undefined" && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
				onClick: () => setShowEditDetails(false),
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
					onSubmit: saveEdit,
					onClick: (e) => e.stopPropagation(),
					className: "fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mb-4 flex items-center justify-between",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
								className: "text-lg font-bold",
								children: "Edit Details"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: () => setShowEditDetails(false),
								className: "rounded-full p-1 hover:bg-accent",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4" })
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex flex-col gap-3 text-sm",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									className: "flex flex-col items-center gap-3 border-b border-border/60 pb-4",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "relative",
										children: [
											/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
												className: "flex h-20 w-20 items-center justify-center overflow-hidden rounded-full bg-primary text-3xl font-bold text-primary-foreground border-2 border-border/60",
												children: modalAvatarPreview && !modalAvatarRemoved ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
													src: modalAvatarPreview,
													alt: "Preview",
													className: "h-full w-full object-cover"
												}) : initial
											}),
											/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
												type: "button",
												onClick: () => modalFileRef.current?.click(),
												className: "absolute -bottom-1 -right-1 flex h-7 w-7 items-center justify-center rounded-full border border-border bg-background text-foreground shadow transition hover:scale-105 active:scale-95",
												title: "Change Photo",
												"aria-label": "Change Photo",
												children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Camera, { className: "h-3.5 w-3.5" })
											}),
											/* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
												ref: modalFileRef,
												type: "file",
												accept: "image/jpeg,image/png,image/webp",
												className: "hidden",
												onChange: onPickModalAvatar
											})
										]
									}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "flex items-center gap-2",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
											type: "button",
											onClick: () => modalFileRef.current?.click(),
											className: "rounded-full bg-secondary px-3 py-1 text-xs font-semibold hover:bg-secondary/80",
											children: modalAvatarPreview && !modalAvatarRemoved ? "Change Photo" : "Upload Photo"
										}), modalAvatarPreview && !modalAvatarRemoved && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
											type: "button",
											onClick: () => {
												setModalAvatarFile(null);
												setModalAvatarPreview(null);
												setModalAvatarRemoved(true);
											},
											className: "rounded-full border border-destructive/40 px-3 py-1 text-xs font-semibold text-destructive hover:bg-destructive/10",
											children: "Remove Photo"
										})]
									})]
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
									className: "flex flex-col gap-1",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
										children: "Full Name"
									}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
										value: editDraft.full_name,
										onChange: (e) => setEditDraft((d) => ({
											...d,
											full_name: e.target.value
										})),
										maxLength: 80,
										className: "rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
									})]
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
									className: "flex flex-col gap-1",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
										children: "Username"
									}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
										value: editDraft.username,
										onChange: (e) => setEditDraft((d) => ({
											...d,
											username: e.target.value
										})),
										maxLength: 24,
										className: "rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
									})]
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
									className: "flex flex-col gap-1",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
										children: "Phone"
									}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
										value: editDraft.phone,
										onChange: (e) => setEditDraft((d) => ({
											...d,
											phone: e.target.value
										})),
										placeholder: "+91 98765 43210",
										maxLength: 20,
										className: "rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
									})]
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
									className: "flex flex-col gap-1",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
										children: "Gender"
									}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("select", {
										value: editDraft.gender,
										onChange: (e) => setEditDraft((d) => ({
											...d,
											gender: e.target.value
										})),
										className: "rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary",
										children: [
											/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", {
												value: "",
												children: "Prefer not to say"
											}),
											/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", {
												value: "female",
												children: "Female"
											}),
											/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", {
												value: "male",
												children: "Male"
											}),
											/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", {
												value: "non-binary",
												children: "Non-binary"
											}),
											/* @__PURE__ */ (0, import_jsx_runtime.jsx)("option", {
												value: "other",
												children: "Other"
											})
										]
									})]
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									className: "flex flex-col gap-1",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
										children: "Verified Profile Location"
									}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "flex items-center gap-2",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
											className: "min-w-0 flex-1 truncate rounded-2xl border border-border/60 bg-secondary/50 px-3 py-2 text-muted-foreground",
											children: editDraft.city || "Location not set"
										}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
											type: "button",
											onClick: handleFetchProfileGPS,
											disabled: fetchingGps || savingEdit,
											className: "flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground transition active:scale-95 disabled:opacity-60",
											children: fetchingGps ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-4 w-4 animate-spin" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Navigation, { className: "h-4 w-4" })
										})]
									})]
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
									className: "flex flex-col gap-1",
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
											className: "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
											children: "Bio"
										}),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", {
											value: editDraft.bio,
											onChange: (e) => setEditDraft((d) => ({
												...d,
												bio: e.target.value
											})),
											maxLength: 200,
											rows: 3,
											className: "resize-none rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
										}),
										/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
											className: "text-right text-[10px] text-muted-foreground",
											children: [editDraft.bio.length, "/200"]
										})
									]
								})
							]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mt-5 flex justify-end gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: () => setShowEditDetails(false),
								className: "rounded-full border border-border/60 px-4 py-2 text-sm font-semibold transition hover:bg-accent",
								children: "Cancel"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "submit",
								disabled: savingEdit,
								className: "rounded-full bg-primary px-5 py-2 text-sm font-semibold text-primary-foreground transition hover:scale-[1.02] active:scale-95 disabled:opacity-60",
								children: savingEdit ? "Saving…" : "Save"
							})]
						})
					]
				})
			}), document.body),
			showBlockedModal && typeof document !== "undefined" && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
				onClick: () => setShowBlockedModal(false),
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					onClick: (e) => e.stopPropagation(),
					className: "fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mb-4 flex items-center justify-between",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
							className: "text-lg font-bold",
							children: "Blocked Users"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							type: "button",
							onClick: () => setShowBlockedModal(false),
							className: "rounded-full p-1 hover:bg-accent",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4" })
						})]
					}), blockedUsers.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "py-8 text-center text-sm text-muted-foreground",
						children: "You haven't blocked anyone yet."
					}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("ul", {
						className: "flex flex-col gap-2",
						children: blockedUsers.map((u) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
							className: "flex items-center justify-between gap-3 rounded-2xl border border-border/60 bg-card p-3",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex items-center gap-3 min-w-0",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "h-10 w-10 shrink-0 overflow-hidden rounded-full bg-primary/15 text-primary flex items-center justify-center text-sm font-semibold",
									children: u.avatar_url ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
										src: u.avatar_url,
										alt: "",
										className: "h-full w-full object-cover"
									}) : (u.full_name || u.username || "U")[0]?.toUpperCase()
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									className: "min-w-0",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "truncate text-sm font-semibold",
										children: u.full_name || u.username || "User"
									}), u.username && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
										className: "truncate text-xs text-muted-foreground",
										children: ["@", u.username]
									})]
								})]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								onClick: () => unblockMut.mutate(u.id),
								disabled: unblockMut.isPending,
								className: "rounded-full border border-border/60 px-3 py-1 text-xs font-semibold transition hover:bg-accent disabled:opacity-50",
								children: "Unblock"
							})]
						}, u.id))
					})]
				})
			}), document.body),
			showFaq && typeof document !== "undefined" && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
				onClick: () => setShowFaq(false),
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					onClick: (e) => e.stopPropagation(),
					className: "fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mb-4 flex items-center justify-between",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
								className: "text-lg font-bold",
								children: "Frequently Asked Questions"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								onClick: () => setShowFaq(false),
								className: "rounded-full p-1 hover:bg-accent",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4" })
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "flex flex-col gap-3",
							children: [
								{
									q: "How do I join a plan?",
									a: "Tap on any plan on the Explore tab, view the details, and request to join. The host will review and approve/reject your request."
								},
								{
									q: "How do I host a plan?",
									a: "Tap on the Create tab in the bottom bar, fill in the activity title, description, category, venue, and time, and publish it."
								},
								{
									q: "Are payments handled in the app?",
									a: "No, tribeX does not handle payments directly. Any cost per head should be settled with the host directly."
								},
								{
									q: "How does the Reliability Score work?",
									a: "Your Reliability Score reflects your attendance. Joining plans and attending venue check-ins increases it, while hosting/joining and failing to show up decreases it."
								}
							].map((faq, i) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "border-b border-border/60 pb-3",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
									onClick: () => setOpenFaqIndex(openFaqIndex === i ? null : i),
									className: "flex items-center justify-between w-full text-left font-semibold text-sm py-2 hover:text-primary transition",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: faq.q }), openFaqIndex === i ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronDown, { className: "h-4 w-4 transform rotate-180 transition-transform" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronDown, { className: "h-4 w-4 transition-transform" })]
								}), openFaqIndex === i && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "mt-2 text-xs text-muted-foreground leading-relaxed",
									children: faq.a
								})]
							}, i))
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "mt-6 text-center text-xs text-muted-foreground",
							children: "Still have questions? Contact support below."
						})
					]
				})
			}), document.body),
			showReportModal && typeof document !== "undefined" && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
				onClick: () => setShowReportModal(false),
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
					onSubmit: handleReportSubmit,
					onClick: (e) => e.stopPropagation(),
					className: "fixed left-1/2 top-1/2 z-[99999] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mb-4 flex items-center justify-between",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
								className: "text-lg font-bold",
								children: "Report a Problem"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: () => setShowReportModal(false),
								className: "rounded-full p-1 hover:bg-accent",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4" })
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "mb-3 text-xs text-muted-foreground leading-relaxed",
							children: "Describe the problem you're facing. Our technical crew will look into it."
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", {
							value: reportText,
							onChange: (e) => setReportText(e.target.value),
							required: true,
							rows: 4,
							maxLength: 500,
							placeholder: "Steps to reproduce, error message, or description...",
							className: "w-full resize-none rounded-2xl border border-border/60 bg-background p-3 text-sm outline-none focus:border-primary"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mt-5 flex justify-end gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: () => setShowReportModal(false),
								className: "rounded-full border border-border/60 px-4 py-2 text-sm font-semibold transition hover:bg-accent",
								children: "Cancel"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "submit",
								disabled: submittingReport,
								className: "rounded-full bg-primary px-5 py-2 text-sm font-semibold text-primary-foreground transition hover:scale-[1.02] active:scale-95 disabled:opacity-60",
								children: submittingReport ? "Submitting..." : "Submit Report"
							})]
						})
					]
				})
			}), document.body),
			showFeedbackModal && typeof document !== "undefined" && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
				onClick: () => setShowFeedbackModal(false),
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
					onSubmit: handleFeedbackSubmit,
					onClick: (e) => e.stopPropagation(),
					className: "fixed left-1/2 top-1/2 z-[99999] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mb-4 flex items-center justify-between",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
								className: "text-lg font-bold",
								children: "Send Feedback"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: () => setShowFeedbackModal(false),
								className: "rounded-full p-1 hover:bg-accent",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4" })
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "mb-4 flex items-center justify-center gap-2",
							children: [
								1,
								2,
								3,
								4,
								5
							].map((star) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: () => setFeedbackRating(star),
								className: "p-1 transition active:scale-125",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("svg", {
									className: `h-8 w-8 ${star <= feedbackRating ? "fill-current text-primary" : "text-muted-foreground"}`,
									viewBox: "0 0 24 24",
									fill: "none",
									stroke: "currentColor",
									strokeWidth: "2",
									children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("polygon", { points: "12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" })
								})
							}, star))
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", {
							value: feedbackText,
							onChange: (e) => setFeedbackText(e.target.value),
							rows: 4,
							maxLength: 500,
							placeholder: "What do you love? What can we do better?",
							className: "w-full resize-none rounded-2xl border border-border/60 bg-background p-3 text-sm outline-none focus:border-primary"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mt-5 flex justify-end gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								onClick: () => setShowFeedbackModal(false),
								className: "rounded-full border border-border/60 px-4 py-2 text-sm font-semibold transition hover:bg-accent",
								children: "Cancel"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "submit",
								disabled: submittingFeedback,
								className: "rounded-full bg-primary px-5 py-2 text-sm font-semibold text-primary-foreground transition hover:scale-[1.02] active:scale-95 disabled:opacity-60",
								children: submittingFeedback ? "Submitting..." : "Submit Feedback"
							})]
						})
					]
				})
			}), document.body),
			showDeleteConfirm && typeof document !== "undefined" && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
				onClick: () => setShowDeleteConfirm(false),
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					onClick: (e) => e.stopPropagation(),
					className: "fixed left-1/2 top-1/2 z-[99999] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex flex-col items-center gap-3 text-center",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "flex h-12 w-12 items-center justify-center rounded-full bg-destructive/15 text-destructive",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShieldAlert, { className: "h-6 w-6" })
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
								className: "text-lg font-bold text-foreground",
								children: "Delete your account?"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm text-muted-foreground leading-relaxed",
								children: "This action is permanent and cannot be undone. All your hosted plans, active chats, attendance check-ins, and personal profile settings will be permanently purged."
							})
						]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mt-6 flex flex-col gap-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: () => {
								setShowDeleteConfirm(false);
								setShowDeleteFinal(true);
							},
							className: "w-full rounded-full bg-destructive py-2.5 text-sm font-semibold text-destructive-foreground transition hover:opacity-90 active:scale-95",
							children: "Yes, Continue"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: () => setShowDeleteConfirm(false),
							className: "w-full rounded-full border border-border/60 py-2.5 text-sm font-semibold transition hover:bg-accent",
							children: "Cancel"
						})]
					})]
				})
			}), document.body),
			showDeleteFinal && typeof document !== "undefined" && (0, import_react_dom.createPortal)(/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm",
				onClick: () => setShowDeleteFinal(false),
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					onClick: (e) => e.stopPropagation(),
					className: "fixed left-1/2 top-1/2 z-[99999] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex flex-col items-center gap-3 text-center",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
								className: "text-lg font-bold text-destructive",
								children: "Final Confirmation"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
								className: "text-xs text-muted-foreground leading-relaxed",
								children: [
									"To permanently delete your user profile and all associated data, type",
									" ",
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("strong", {
										className: "text-destructive font-bold",
										children: "DELETE"
									}),
									" in the box below."
								]
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "mt-4",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("input", {
								type: "text",
								placeholder: "Type DELETE",
								value: deleteInput,
								onChange: (e) => setDeleteInput(e.target.value),
								className: "w-full text-center rounded-2xl border border-destructive/40 bg-background px-3 py-2 text-sm outline-none focus:border-destructive"
							})
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "mt-6 flex flex-col gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								onClick: handleDeleteFinalConfirm,
								disabled: deleteAccountMut.isPending,
								className: "flex items-center justify-center gap-1.5 w-full rounded-full bg-destructive py-2.5 text-sm font-bold text-white transition active:scale-95 disabled:opacity-60",
								children: deleteAccountMut.isPending ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-4 w-4 animate-spin" }), " Deleting..."] }) : "Delete Permanently"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								onClick: () => {
									setShowDeleteFinal(false);
									setDeleteInput("");
								},
								disabled: deleteAccountMut.isPending,
								className: "w-full rounded-full border border-border/60 py-2.5 text-sm font-semibold transition hover:bg-accent",
								children: "Cancel"
							})]
						})
					]
				})
			}), document.body)
		]
	});
}
var IndexRoute = Route$9.update({
	id: "/",
	path: "/",
	getParentRoute: () => Route$10
});
var AuthRoute = Route$8.update({
	id: "/auth",
	path: "/auth",
	getParentRoute: () => Route$10
});
var CompleteProfileRoute = Route$7.update({
	id: "/complete-profile",
	path: "/complete-profile",
	getParentRoute: () => Route$10
});
var CreateRoute = Route$6.update({
	id: "/create",
	path: "/create",
	getParentRoute: () => Route$10
});
var MessagesRoute = Route$5.update({
	id: "/messages",
	path: "/messages",
	getParentRoute: () => Route$10
});
var OnboardingRoute = Route$4.update({
	id: "/onboarding",
	path: "/onboarding",
	getParentRoute: () => Route$10
});
var ProfileRoute = Route$3.update({
	id: "/profile",
	path: "/profile",
	getParentRoute: () => Route$10
});
var TermsAndPoliciesRoute = Route$2.update({
	id: "/terms-and-policies",
	path: "/terms-and-policies",
	getParentRoute: () => Route$10
});
var ChatActivityIdRoute = Route$1.update({
	id: "/chat/$activityId",
	path: "/chat/$activityId",
	getParentRoute: () => Route$10
});
var ProfileRouteChildren = { ProfileSettingsRoute: Route.update({
	id: "/settings",
	path: "/settings",
	getParentRoute: () => ProfileRoute
}) };
var rootRouteChildren = {
	IndexRoute,
	AuthRoute,
	CompleteProfileRoute,
	CreateRoute,
	MessagesRoute,
	OnboardingRoute,
	ProfileRoute: ProfileRoute._addFileChildren(ProfileRouteChildren),
	TermsAndPoliciesRoute,
	ChatActivityIdRoute
};
var routeTree = Route$10._addFileChildren(rootRouteChildren)._addFileTypes();
var getRouter = () => {
	return createRouter({
		routeTree,
		context: { queryClient: new QueryClient({ defaultOptions: { queries: {
			staleTime: 300 * 1e3,
			gcTime: 900 * 1e3,
			refetchOnWindowFocus: false,
			retry: 1
		} } }) },
		scrollRestoration: true,
		defaultPreload: "intent",
		defaultPreloadStaleTime: 6e4,
		defaultPendingComponent: PageLoader$1,
		defaultPendingMs: 300,
		defaultPendingMinMs: 0
	});
};
//#endregion
export { getRouter };
