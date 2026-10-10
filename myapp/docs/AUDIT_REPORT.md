# TribeX Flutter Release Audit

**Project:** TribeX Flutter application  
**Audit date:** 10 October 2026  
**Scope:** `myapp/` Flutter project, including `lib/`, `test/`, Android/web platform files, package/configuration files, and release-related configuration. The root React/TanStack frontend is out of scope.  
**Declaration:** Read-only inspection. No source, test, configuration, dependency, generated, asset, database, or remote-service files were changed. The only file written by this audit is this report.

## Executive summary

| Severity | Count |
|---|---:|
| IMMEDIATE | 1 |
| HIGH | 3 |
| MEDIUM | 4 |
| LOW | 2 |

The Flutter project has a coherent feature set and useful tests for messaging, polls, location, expenses, safety, and UI flows. Android cleartext traffic is disabled, Supabase uses PKCE, and realtime channels and controllers are generally disposed.

**Recommendation: NO-GO.** A confirmed release-blocking configuration permits a release build to fall back to the debug signing key when `key.properties` is absent or incomplete. That must fail the build instead. In addition, the application suppresses uncaught errors and has failure paths that silently fall back to large inline Base64 image data. These issues should be corrected and verified in a clean release build before distribution.

The audit did not have a working runtime/device session, did not execute analyzer/tests because those commands can update project-local generated state, and found no iOS project or CI workflow to inspect. Those gaps are material to release readiness.

## Audit coverage

### Inventory

- Flutter root confirmed as `C:\Mayank Thakkar\tribeX - Find Local Fun (2)\tribeX - Find Local Fun\myapp`.
- Repository root is the parent directory containing the Flutter project.
- Git status before audit:
  - Modified: `lib/state/chat_state.dart`, `lib/widgets/chat/poll_card_widget.dart`, `test/messaging_complete_repair_test.dart`.
  - Untracked: `docs/POLL_BUG_FIX_REPORT.md`, `test/poll_system_regression_test.dart`.
  - These changes were preserved and not attributed to this audit.
- 225 files discovered under the Flutter project excluding `.git/`, `.dart_tool/`, and `build/`.
- 74 Dart files discovered under `lib/` and `test/`: 64 production files and 10 test files.
- `integration_test/` is absent.
- Measurable Dart source/test total: 30,177 lines.
- 64 production Dart files were inventoried by folder and inspected through targeted source review and static searches. Complete line-by-line inspection was not possible for every large file within this session; those files are marked as requiring verification rather than “no issue found.”
- Existing `UI_AUDIT_REPORT.md` was treated as prior context only; its visual recommendations were not copied as confirmed code defects.

### Folder checklist

- [x] `lib/core/` — 7 Dart files inventoried; theme, constants, and utility patterns sampled.
- [x] `lib/models/` — 8 Dart files inventoried; serialization and nullable model patterns searched.
- [x] `lib/screens/` — 11 screen files inventoried; screen-level source and interaction patterns searched.
- [x] `lib/services/` — 5 service files inventoried; authentication, storage, location, reporting, and Supabase access reviewed.
- [x] `lib/state/` — 5 state files inventoried; async state, realtime, disposal, and error paths reviewed.
- [x] `lib/widgets/` — 27 widget files inventoried; shared controls, chat, activity, profile, and common widgets sampled.
- [x] `test/` — 10 Dart test files inventoried; test names and coverage areas reviewed.
- [x] `android/` — Gradle, manifest, debug manifest, wrapper/configuration, and signing references reviewed.
- [x] `web/` — web shell and Supabase origin references inventoried.
- [x] Root package/config files — `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, splash/icon configuration, README, and metadata inventoried.
- [ ] `ios/` — not present; no iOS plist, entitlements, Podfile, signing, or privacy declarations exist to inspect.
- [ ] CI/CD workflows — no `.github/` workflow directory was found in the Flutter scope.
- [ ] Supabase migrations/database policies — no migrations were found in this Flutter scope; remote RLS/RPC definitions could not be verified read-only from this workspace.
- [ ] Runtime/device verification — not available during this audit.

### Configuration and release coverage

Inspected: `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `flutter_launcher_icons.yaml`, `flutter_native_splash.yaml`, Android Gradle files, Android manifests, `web/index.html`, and `netlify.toml` where present.

Not audited as release evidence: generated build output, local machine properties, unavailable remote Supabase policies, unavailable signing keystore, iOS configuration, and CI secrets/workflows. Generated `build/` and `.dart_tool/` content was excluded from the application audit.

## Findings

### IMMEDIATE

- **ID:** IMM-01
- **Title:** Release builds fall back to the debug signing key
- **Category:** Release / Security
- **Severity:** IMMEDIATE
- **Location:** `android/app/build.gradle.kts:62-66`
- **Evidence:** The release build type selects the configured release signing key only when `releaseConfig.storeFile` is non-null and exists; otherwise it explicitly selects `signingConfigs.getByName("debug")`.
- **Problem:** A clean checkout or incomplete release secret setup can produce a release artifact signed with the debug certificate instead of failing the build.
- **Impact:** The artifact is not suitable for production signing, can be rejected by distribution/update channels, and creates an unsafe release-readiness failure that can be missed in automation.
- **Recommended fix:** Require all release keystore properties and fail configuration with an actionable error when they are absent. Never use the debug signing config for `release`. Add a clean-environment release-build check that asserts the signing certificate is the expected production certificate.
- **Effort:** Small
- **Confidence:** High
- **Verification status:** Confirmed

### HIGH

- **ID:** HIGH-01
- **Title:** Image upload failure silently creates unbounded inline Base64 data
- **Category:** Performance / Bug / Storage
- **Severity:** HIGH
- **Location:** `lib/services/storage_service.dart:151-170`
- **Evidence:** `uploadBytes` tries three buckets, swallows every upload exception, then Base64-encodes the complete byte array and returns a `data:image/jpeg;base64,...` URL. The 5 MB check is only in `pickAndUploadImage`, not in the public `uploadBytes` method.
- **Problem:** Any storage outage, permission/RLS error, or caller supplying larger bytes turns a failed upload into a very large string that can be persisted with activity data.
- **Impact:** Large database rows, memory pressure, slow queries/rendering, request-size failures, and loss of the actual upload error. This also makes storage authorization failures look like successful uploads until later.
- **Recommended fix:** Make upload failure explicit; do not use a database-persisted Base64 fallback. Enforce a byte limit inside `uploadBytes`, validate MIME/type, surface the storage error to the caller, and use a bounded local retry or user retry action instead.
- **Effort:** Medium
- **Confidence:** High
- **Verification status:** Confirmed

- **ID:** HIGH-02
- **Title:** Supabase initialization failure is converted into a successful initialization state
- **Category:** Bug / Release
- **Severity:** HIGH
- **Location:** `lib/services/supabase_service.dart:11-25`; `lib/main.dart:67`
- **Evidence:** The initialization catch logs the exception, sets `_initialized = true`, and returns normally. `main` then always calls `runApp` after awaiting `SupabaseService.initialize`; subsequent `client` access can return null and callers silently skip network operations.
- **Problem:** A configuration, network, or startup initialization failure is not represented as an application startup failure or an explicit unavailable state.
- **Impact:** Authentication, discovery, messaging, and account operations can appear to do nothing or show misleading empty/error states instead of explaining that the backend is unavailable.
- **Recommended fix:** Preserve the failure state, return a typed initialization result or throw, and render a clear retry/offline startup state. Do not set the initialized flag on failure.
- **Effort:** Medium
- **Confidence:** High
- **Verification status:** Confirmed

- **ID:** HIGH-03
- **Title:** Global error handlers suppress crash visibility
- **Category:** Release / Observability
- **Severity:** HIGH
- **Location:** `lib/main.dart:24-32`
- **Evidence:** `FlutterError.onError` only calls `debugPrint`; `PlatformDispatcher.instance.onError` only logs and returns `true`, marking the error handled. No crash-reporting or persistent release telemetry integration is configured in the inspected source.
- **Problem:** Uncaught framework and platform errors are treated as handled without a release-safe reporting path.
- **Impact:** Production crashes and severe rendering/runtime failures can be invisible to operators, making release regressions difficult to detect and diagnose. The custom `ErrorWidget` can also make a failed screen look like a recoverable UI state.
- **Recommended fix:** Route uncaught errors to an approved crash-reporting system or a controlled release logging sink, preserve the original error semantics where appropriate, and add an explicit user retry/recovery path for failed screens.
- **Effort:** Medium
- **Confidence:** High
- **Verification status:** Confirmed

### MEDIUM

- **ID:** MED-01
- **Title:** Bottom navigation relies on GestureDetector for primary navigation controls
- **Category:** UI-UX / Accessibility
- **Severity:** MEDIUM
- **Location:** `lib/widgets/common/custom_bottom_nav.dart:102-111`
- **Evidence:** Each navigation item is a `Semantics` node containing a `GestureDetector`; the visible labels use an 11 px local text style. Semantics labels exist, but the control is not implemented as a Material button/navigation destination.
- **Problem:** Primary navigation behavior, focus treatment, keyboard activation, and pressed-state feedback are not provided by the control itself.
- **Impact:** Accessibility and non-touch navigation behavior can differ from standard Flutter navigation controls; small text and custom gesture handling reduce usability at larger text scales.
- **Recommended fix:** Use a `NavigationBar`/`NavigationDestination`, or an `InkWell`/button with explicit focus, tooltip, selected, and minimum tap-target behavior. Validate with TalkBack/VoiceOver and large text.
- **Effort:** Small
- **Confidence:** Medium
- **Verification status:** Confirmed for implementation pattern; runtime accessibility requires verification

- **ID:** MED-02
- **Title:** Location resolution may use a ten-year-old cached fix
- **Category:** Privacy / Bug / UX
- **Severity:** MEDIUM
- **Location:** `lib/services/location_service.dart:401-407`
- **Evidence:** The fallback call to `getCurrentPosition` requests `maxAge: const Duration(days: 3650)` after a timeout/unavailable result.
- **Problem:** A stale device location can be accepted as the current location when fresh GPS is unavailable.
- **Impact:** Explore radius, reverse-geocoded place, safety context, and location shown to the user may be materially wrong. This is especially risky for a local discovery and emergency-oriented product.
- **Recommended fix:** Bound the fallback age to a product-defined maximum, label stale results explicitly, and require confirmation before persisting or using stale coordinates for safety-sensitive operations.
- **Effort:** Small
- **Confidence:** High
- **Verification status:** Confirmed

- **ID:** MED-03
- **Title:** Large state and screen files concentrate unverified regression risk
- **Category:** Architecture / Maintainability
- **Severity:** MEDIUM
- **Location:** `lib/screens/create_plan_screen.dart` (1,879 lines), `lib/state/chat_state.dart` (1,698 lines), `lib/screens/explore_screen.dart` (1,428 lines), `lib/screens/settings_screen.dart` (1,328 lines), `lib/widgets/common/place_search_dialog.dart` (961 lines)
- **Evidence:** Measured file sizes show core flows and asynchronous business logic concentrated in a small number of very large widgets/classes.
- **Problem:** Rendering, validation, networking, and state transitions are difficult to isolate and fully regression-test. The current dirty worktree also includes active changes in `chat_state.dart` and poll tests.
- **Impact:** Changes to chat, plan creation, settings, or discovery can introduce hidden regressions; review and test coverage are harder to reason about.
- **Recommended fix:** Extract feature controllers/use cases, form sections, and independent async services incrementally, starting with chat and plan creation. Add focused tests for failure and retry transitions before moving logic.
- **Effort:** Large
- **Confidence:** High
- **Verification status:** Confirmed size/structure; regression impact requires runtime and test verification

- **ID:** MED-04
- **Title:** Critical release checks are not represented by integration tests or CI in scope
- **Category:** Release / Testing
- **Severity:** MEDIUM
- **Location:** Project scope: no `integration_test/` directory and no `.github/workflows/` directory found
- **Evidence:** Ten unit/widget-oriented Dart tests exist, but there is no integration-test directory and no discoverable CI workflow for analyzer, tests, or release signing.
- **Problem:** Authentication redirects, deep links, permissions, release signing, storage failure behavior, and realtime lifecycle are not demonstrated by an automated end-to-end gate in this repository scope.
- **Impact:** Important release blockers can pass local unit tests unnoticed.
- **Recommended fix:** Add CI outside this read-only audit: analyzer/test gates, a clean signed-release configuration check, and device/integration coverage for auth callback, permissions, storage failure, realtime reconnect, and account deletion.
- **Effort:** Large
- **Confidence:** High
- **Verification status:** Confirmed repository absence; CI may exist outside this checkout

### LOW

- **ID:** LOW-01
- **Title:** User-entered meeting links accept HTTP while Android disallows cleartext traffic
- **Category:** Bug / Security / UX
- **Severity:** LOW
- **Location:** `lib/widgets/activity/edit_plan_modal.dart:197`; `android/app/src/main/AndroidManifest.xml:17`
- **Evidence:** Validation text accepts URLs starting with `https://` or `http://`, while the Android application explicitly sets `android:usesCleartextTraffic="false"`.
- **Problem:** A saved HTTP meeting link may not open on Android even though the form accepts it.
- **Impact:** Users can create an apparently valid plan with a meeting link that fails at use time.
- **Recommended fix:** Require HTTPS for remote meeting links, or provide a clear documented exception and platform-specific handling.
- **Effort:** Small
- **Confidence:** High
- **Verification status:** Confirmed configuration mismatch

- **ID:** LOW-02
- **Title:** Several service failure paths swallow exceptions without user-visible context
- **Category:** Bug / Observability
- **Severity:** LOW
- **Location:** `lib/services/supabase_service.dart:32-34, 53-54, 90-92`; `lib/services/auth_service.dart:168-169, 246-247`
- **Evidence:** Multiple `catch (_) {}` blocks return null/false or continue without retaining an error result.
- **Problem:** The caller cannot reliably distinguish an empty result from a backend, authorization, or parsing failure.
- **Impact:** Troubleshooting and user recovery are weaker, and backend policy regressions can look like ordinary empty states.
- **Recommended fix:** Replace silent catches with typed failures or structured error results; log only non-sensitive diagnostic context and present retry guidance at the UI boundary.
- **Effort:** Medium
- **Confidence:** High
- **Verification status:** Confirmed

## Screen-by-screen and component table

| File | Status | Finding IDs |
|---|---|---|
| `lib/screens/auth_screen.dart` | Requires runtime verification; source-level auth paths inspected | HIGH-02, HIGH-03, LOW-02 |
| `lib/screens/chat_screen.dart` | Requires runtime verification; large async surface | MED-03, MED-04 |
| `lib/screens/complete_profile_screen.dart` | Requires runtime verification | MED-02 |
| `lib/screens/create_plan_screen.dart` | Issues Found; large form surface | MED-03, LOW-01 |
| `lib/screens/explore_screen.dart` | Requires runtime verification | MED-02, MED-03 |
| `lib/screens/main_shell.dart` | Requires runtime verification | MED-01 |
| `lib/screens/messages_screen.dart` | Requires runtime verification | MED-03, MED-04 |
| `lib/screens/onboarding_screen.dart` | Requires runtime verification | MED-04 |
| `lib/screens/profile_screen.dart` | Requires runtime verification | MED-04 |
| `lib/screens/settings_screen.dart` | Requires runtime verification; large conditional surface | MED-03, MED-04 |
| `lib/screens/terms_and_policies_screen.dart` | No issue found in inspected source; runtime not verified | — |

Shared widgets and services with confirmed findings are listed under their finding locations. Other widget/component files remain “requires runtime verification,” not “no issue found,” because a working device/web session was unavailable.

## Security and secrets summary

- `lib/services/supabase_service.dart` contains the Supabase project URL and a client publishable/anonymous key. The key is embedded in the client as expected for Supabase public clients; it is not a service-role credential based on its name and usage. Its exposure is not itself a confirmed secret leak. Supabase RLS and RPC authorization could not be verified from this checkout.
- Android release signing reads `android/key.properties` if present. The file is ignored by `android/.gitignore`, but the fallback to debug signing is a confirmed release risk. No keystore value was copied into this report.
- No service-role key, private key, password, or credential value is reproduced here.
- Android cleartext traffic is disabled in the main manifest.
- The app requests network and location permissions. Deep-link callback exposure is configured for `com.tribex.app://callback`; intent behavior requires device verification.

## Dependencies and release readiness

`pubspec.yaml` declares Flutter 3-era packages including `supabase_flutter`, `geolocator`, `image_picker`, `shared_preferences`, and `url_launcher`. `pubspec.lock` is present. No dependency vulnerability database or network advisory lookup was run, so no package is declared vulnerable from this audit.

Release readiness is blocked by IMM-01. Android target/compile values are delegated to Flutter defaults, and the release signing path must be verified in the actual production toolchain. No iOS release configuration or CI signing pipeline is present in the audited scope.

## Tests and checks

### Commands/checks actually run

- `git status --short` — confirmed pre-existing modified and untracked files listed above.
- Read-only file inventory and line-count scripts — found 74 Dart files and 30,177 Dart lines; 225 non-generated/non-build files in the project scope.
- Read-only `rg` searches for credentials, URLs, permissions, error handling, lifecycle methods, TODOs, and fixed UI patterns.
- Direct source/configuration reads for the release signing, Supabase initialization, storage upload, global error handling, location fallback, navigation, manifests, and package configuration.

### Not run

- `flutter analyze`, `flutter test`, and release builds were not run because this audit was required to be read-only and those commands may update `.dart_tool/`, build artifacts, coverage files, or other project-local generated state.
- No device, emulator, browser dev server, accessibility tree, deep-link, permission, network-failure, or release-signature verification was available.
- No dependency advisory scan was run.

## Positive observations

- Supabase auth is configured with PKCE in `lib/services/supabase_service.dart`.
- Android has `android:usesCleartextTraffic="false"`.
- Chat realtime channels are explicitly unsubscribed in `ChatState.clear`, `ChatState.dispose`, and per-activity unsubscribe paths.
- Auth and other state classes include mounted/disposed guards in many asynchronous UI transitions.
- Image picker input has a 5 MB check in the picker path and image dimensions/quality are constrained.
- The test suite covers meaningful domain areas including polls, location radius, messaging, expenses, safety, and virtual plans.
- The project uses analyzer lints including `unawaited_futures` and `cancel_subscriptions`.

## Prioritized action plan

### Do Now

1. Fix IMM-01: fail release configuration when production signing is unavailable; verify the certificate in a clean release build.
2. Remove the Base64 database fallback and make storage failures explicit (HIGH-01).
3. Make Supabase initialization failure observable and recoverable (HIGH-02).
4. Add release crash reporting/error handling that does not silently mark uncaught errors handled (HIGH-03).

### Do This Week

1. Add a bounded stale-location policy and user disclosure (MED-02).
2. Replace silent service catches with typed error results and retry UI (LOW-02).
3. Align meeting-link validation with Android cleartext policy (LOW-01).
4. Verify navigation semantics and large-text behavior on Android/iOS accessibility services (MED-01).

### Do This Sprint

1. Split oversized chat, plan creation, explore, settings, and place-search files (MED-03).
2. Add integration tests and CI gates for auth callbacks, permissions, storage failure, realtime reconnect, and release signing (MED-04).
3. Verify Supabase RLS and security-definer RPC policies against the client assumptions.

### Backlog

1. Maintain an auditable release checklist for iOS/Android/web configurations.
2. Add dependency advisory checks to CI once a workflow exists in scope.

## Final self-check

- Inventory counts and measurable line counts are recorded.
- All 74 Dart files were discovered by folder; large-file coverage is explicitly described as partial where complete reading/runtime verification was unavailable.
- Every listed finding has a source path and line or measurable file evidence.
- No finding is intentionally duplicated.
- Severity labels follow the requested definitions; only the debug-signing release blocker is IMMEDIATE.
- No source, test, config, dependency, generated, asset, database, or remote-service file was modified.
- Only `AUDIT_REPORT.md` was created by this audit.
- Significant gaps: no iOS project, no CI workflow in scope, no integration tests, no runtime/device session, no remote Supabase policy/migration verification, no clean release build/signature verification, and no dependency advisory scan.
