# TribeX Unnecessary Files Audit

**Audit date:** 10 October 2026  
**Repository:** `Maynk20/tribeX-app`  
**Requested report path:** `myapp/docs/UNNECESSARY_FILES_AUDIT.md`  
**Mode:** Read-only identification and documentation only

## 1. Executive summary

The repository contains two applications:

- **Root web application:** TanStack Start/React/TypeScript under `src/`, with Supabase, Netlify/Vite, and Capacitor configuration.
- **Flutter application:** `myapp/`, with Dart source, Android platform files, Flutter web files, assets, tests, and documentation.

No files were deleted, moved, renamed, or modified by this audit. Existing modified, deleted, and untracked worktree entries were preserved.

The strongest cleanup opportunities are generated artifacts and crash/replay logs, not application source:

1. `myapp/build/`, `myapp/.dart_tool/`, root `node_modules/`, root `dist/`, root `.output/`, `.wrangler/`, and `.tanstack/` are reproducible/generated or dependency-cache content.
2. `myapp/hs_err_pid*.log` and `myapp/replay_pid*.log` are crash/replay diagnostics and are not runtime inputs.
3. Several audit/report documents overlap, but they contain historical or implementation context and should not be removed without owner review.
4. A small number of widgets and root UI primitives have no confirmed static consumer, but dynamic imports, generated routes, or future feature use prevent an automatic removal recommendation.
5. No unused dependency can be classified with high confidence from static text search alone.

### Classification counts

Counts below are **candidate groups**, not a count of every file in the repository. A group can contain multiple files.

| Classification | Candidate groups | Meaning |
|---|---:|---|
| KEEP | 15 | Required, referenced, or important project knowledge |
| LIKELY SAFE TO REMOVE | 2 | Strong evidence of disposable diagnostics with no application references |
| NEEDS MANUAL VERIFICATION | 10 | Static analysis cannot rule out dynamic/tooling/deployment use |
| GENERATED / RECREATABLE | 7 | Reproducibly produced build/cache/dependency output |
| SECURITY REVIEW | 1 | Sensitive configuration requiring handling review |
| DO NOT REMOVE | 9 | Application, platform, migration, test, lockfile, or deployment-critical groups |

## 2. Repository structure and audit scope

### Application and source areas

| Area | Paths | Finding |
|---|---|---|
| Root web application | `src/`, `public/`, `package.json`, `bun.lock`, `package-lock.json`, `vite.config.ts`, `netlify.toml`, `capacitor.config.ts` | Active TanStack Start/React application with routes, components, Supabase integration, deployment, and optional Capacitor build |
| Flutter application | `myapp/lib/`, `myapp/test/`, `myapp/assets/`, `myapp/android/`, `myapp/web/` | Active Flutter application |
| Supabase | `supabase/config.toml`, `supabase/migrations/` | Seven migrations and local Supabase configuration; retain |
| Root scripts | `scripts/prepare-capacitor-build.js`, `generate_documentation_pdf.py` | Build/deployment and documentation tooling |
| Platform files | `android/`, `myapp/android/`, `myapp/web/` | Android/web integration; `myapp/ios/` is absent |
| Documentation | root `README.md`, root `UI_AUDIT_REPORT.md`, `myapp/docs/` | Historical, audit, implementation, and project documentation |

### Measured inventory

The read-only inventory excluded `.git/`, dependency/build/cache directories when measuring source scope, but separately measured those generated directories.

- Auditable non-generated files: **501**
- Measurable text lines in that scope: **115,108**
- Dart files: **74**
- TypeScript/TSX files: **103**
- Supabase SQL migration files: **7**
- SQL files total in repository scope: **40** including generated/dependency-related SQL
- Markdown files: **12**
- Image/font/icon assets: **46** by extension-based inventory
- Flutter production Dart files: **64**
- Flutter test Dart files: **10**
- `integration_test/`: not present
- `myapp/ios/`: not present

### Existing worktree state

The audit began with:

- Modified: `myapp/android/app/build.gradle.kts`
- Modified: `myapp/lib/main.dart`
- Modified: `myapp/lib/services/location_service.dart`
- Modified: `myapp/lib/services/storage_service.dart`
- Modified: `myapp/lib/services/supabase_service.dart`
- Modified: `myapp/lib/widgets/activity/edit_plan_modal.dart`
- Deleted in worktree: `myapp/tribeX_Complete_Project_Documentation.pdf`
- Untracked: `myapp/docs/AUDIT_REPORT.md`
- Untracked: `myapp/docs/tribeX_Complete_Project_Documentation.pdf`

These entries were not changed or reclassified as automatically removable. In particular, the PDF deletion plus untracked copy must be resolved by the owner before any cleanup.

## 3. High-confidence cleanup candidates

These are the only candidates close to an evidence-based safe-removal recommendation. They are still documented rather than deleted.

### LIKELY SAFE TO REMOVE

| Path | Type/purpose | Evidence | Consequences | Confidence | Next step |
|---|---|---|---|---|---|
| `myapp/hs_err_pid20980.log` | JVM crash log | Root-level crash-log naming; no source/config reference found; not a Flutter runtime input | Loses historical JVM crash diagnostics | High | Archive externally if needed, then remove from the working tree |
| `myapp/hs_err_pid24488.log`, `myapp/replay_pid24488.log` | JVM crash/replay diagnostics | Crash/replay naming; no source/config reference found; not referenced by Flutter, Gradle, or web code | Loses historical diagnostics only | High | Confirm no ongoing incident investigation, then remove or archive |

These files are not recommended for automatic deletion while an incident investigation is active.

## 4. Generated and recreatable files

### GENERATED / RECREATABLE

| Path | Purpose and evidence | References/dependencies checked | Consequences | Confidence | Next step |
|---|---|---|---|---|---|
| `myapp/build/` | Flutter/Android build output; approximately 8,966 files and 3.05 GB observed | Excluded by Flutter tooling and not part of application source | Next build regenerates it; deleting while a build is running would be unsafe | High | Remove only when no build/process is using it; use standard Flutter cleanup outside this audit |
| `myapp/.dart_tool/` | Dart/Flutter dependency and tool metadata; approximately 404 files and 853 MB observed | Generated by Dart/Flutter tooling; excluded from source audit | Dependencies/tool metadata regenerate; may make the next command slower | High | Regenerate with the project’s normal dependency workflow |
| `node_modules/` | Root JavaScript dependency installation; approximately 33,816 files and 316 MB observed | Recreated from `package.json` and lockfiles | Web commands cannot run until dependencies are restored | High | Reinstall from the chosen lockfile after confirming package-manager policy |
| `dist/` | Root Vite production output; approximately 87 files and 2.0 MB observed | Referenced as standard build output and ignored by root `.gitignore` | Preview/deployment artifacts disappear; rebuild recreates them | High | Rebuild when needed |
| `.output/` | TanStack/Nitro output; approximately 124 files and 4.5 MB observed | `capacitor.config.ts` and `scripts/prepare-capacitor-build.js` use `.output/public` | Capacitor preparation requires a fresh web build | High | Remove only outside an active Capacitor/deployment operation |
| `.wrangler/` and `.tanstack/` | Local framework/deployment metadata; `.wrangler` contains one small file and `.tanstack` was empty | Both are ignored by root `.gitignore`; `.tanstack` is part of route/build tooling | Local metadata is recreated; active local tooling may need it | High | Remove only after stopping local dev/deployment processes |
| `myapp/android/.gradle/` and other Android Gradle caches | Gradle cache/build metadata | Android tooling owns these directories and `.gitignore` excludes relevant generated content | Next Gradle invocation regenerates data and may be slower | High | Use Gradle/Flutter-supported cleanup only after confirming no build is running |

Generated output was not counted as application source and should not be committed or manually edited. The report does not authorize deletion.

## 5. Candidates requiring manual verification

### NEEDS MANUAL VERIFICATION

| Path/group | Type/purpose | Evidence collected | Possible consequence | Confidence | Recommended next step |
|---|---|---|---|---|---|
| `myapp/docs/AUDIT_REPORT.md` | Recent release audit | Untracked and created during prior work; references current findings and worktree state | Removing loses release/security history | High that it is intentional; removal not recommended | Retain until remediation history is archived |
| `myapp/docs/POLL_BUG_FIX_REPORT.md` | Poll repair report | Untracked report associated with `test/poll_system_regression_test.dart` and existing poll changes | Loses context for active poll work | High | Retain with the related fix until reviewed |
| `myapp/docs/MESSAGING_SYSTEM_EXPLANATION_HINGLISH.md`, `MESSAGING_SYSTEM_FORENSIC_AUDIT.md`, `MESSAGING_SYSTEM_HARDENING_REPORT.md` | Messaging design/audit/history | Hardening report explicitly references the forensic audit; explanation is a separate audience/documentation artifact | Removing may discard unique operational context | Medium | Compare content and retain the canonical report plus any unique setup guidance |
| `myapp/docs/UI_AUDIT_REPORT.md`, `myapp/docs/UI_UX_IMPLEMENTATION_REPORT.md` | UI audit and implementation record | Implementation report explicitly cites the UI audit and claims findings were addressed | Removing loses traceability between recommendations and changes | High | Retain through product sign-off; later archive as a documentation set |
| `myapp/docs/tribeX_Complete_Project_Documentation.pdf` and root `tribeX_Complete_Project_Documentation.pdf` | Project documentation PDFs | Root PDF is tracked while the Flutter copy is currently untracked and the root counterpart is deleted in the worktree; `generate_documentation_pdf.py` writes the root PDF | Removing or choosing one copy incorrectly can lose the canonical artifact or conflict with pending work | High | Resolve the tracked/deleted/untracked state and designate one canonical location |
| `myapp/lib/widgets/common/app_field.dart` | Reusable Flutter field widget | No confirmed consumer found by static name search beyond its declaration | May be used through future/dynamic code; removing can break planned screens | Medium | Search IDE references and run the full app/test suite before removal |
| `myapp/lib/widgets/common/remote_image.dart` | Reusable remote image widget | No confirmed consumer found by static name search beyond its declaration | Dynamic construction or future image flow may depend on it | Medium | Check runtime widget construction and asset/image conventions |
| `src/components/city-combobox.tsx` | Root web city selector | Filename/class search did not establish a route consumer, but the component imports city data and may be dynamically used | Removing could break profile/location flows | Low | Use TypeScript language-server references and exercise profile/create routes |
| `src/components/ui/drawer.tsx` and `src/components/ui/sidebar.tsx` | Generated-style shadcn/Radix UI primitives | Direct consumer search was inconclusive; primitives are commonly retained for future screens and may be imported through aliases | Removing can break dynamic or future UI imports | Low | Confirm with language-server references and build before considering removal |

No modified or untracked application source/test file is recommended for removal. The poll-related modified/untracked work was specifically preserved.

## 6. Duplicate-file findings

### Exact duplicate hashes observed

Exact duplicate content was found, but most duplicates are expected platform/resource variants and are **not** safe-removal candidates:

| Hash group | Files | Interpretation |
|---|---|---|
| Android launch background XML | `myapp/android/app/src/main/res/drawable/launch_background.xml`, `drawable-night/launch_background.xml`, `drawable-night-v21/launch_background.xml`, `drawable-v21/launch_background.xml` | Platform/night-mode resource variants; retain |
| Android splash PNGs | `myapp/android/app/src/main/res/drawable-*/splash.png` and `android12splash.png` variants | Density/night/API resource packaging; retain |
| `background.png` variants | `myapp/android/app/src/main/res/drawable/background.png`, `drawable-v21/background.png`, and night variants | Resource qualifier variants; retain unless Android resource generation is regenerated and proves redundancy |
| Web/app icons | `myapp/assets/images/logo.png`, `myapp/web/favicon.ico`, `favicon.png`, and web icon PNGs | Similar or identical branding at different platform sizes/formats; retain until icon generation is reviewed |
| IDE files | `myapp/.idea/deviceManager.xml` and `myapp/android/.idea/deviceManager.xml`; corresponding `.gitignore` files | IDE-local duplication; ignored tooling state, not application assets |
| Font weights | `PlusJakartaSans-Black.ttf` and `PlusJakartaSans-ExtraBold.ttf` were byte-identical | Potentially redundant font file, but both are declared in `pubspec.yaml` and may be intentionally mapped to distinct weights | 

**Classification:** `NEEDS MANUAL VERIFICATION` for the font pair and icon pair; `DO NOT REMOVE` for Android resource-qualified files. Hash equality alone is insufficient because resource qualifiers and generated manifests determine runtime selection.

No exact duplicate Dart/TS/TSX source implementation was established from hash and reference checks. Flutter and root web applications intentionally contain parallel product features, but they are separate implementations, not duplicate files eligible for automatic deletion.

## 7. Unused source findings

### Flutter

Static filename/reference inspection found these low-confidence candidates:

- `myapp/lib/widgets/common/app_field.dart`
- `myapp/lib/widgets/common/remote_image.dart`

The other Flutter files had route, import, provider, widget, service, model, test, or framework references, or were entry/configuration files. Files such as `main_shell.dart`, `complete_profile_screen.dart`, `notifications_bell_dialog.dart`, and feature modals appeared weak under simple basename counting but are referenced by runtime code or route/widget construction. They are therefore retained.

**Classification:** `NEEDS MANUAL VERIFICATION`, not `LIKELY SAFE TO REMOVE`.

### Root web application

Filename-only search reported many UI primitive files with no filename literal reference because the project uses path aliases and named exports. The generated route tree, barrel-like component imports, and dynamic UI composition make filename absence unreliable. No root web source file is classified as safely unused.

The following require manual verification only:

- `src/components/city-combobox.tsx`
- `src/components/ui/drawer.tsx`
- `src/components/ui/sidebar.tsx`
- Several generated-style `src/components/ui/*` primitives with no direct consumer found by the simple scan

The route tree is generated and explicitly referenced by `src/router.tsx`; do not remove `src/routeTree.gen.ts`.

## 8. Unused asset findings

### Flutter assets

`pubspec.yaml` declares the complete `assets/images/` directory and six Plus Jakarta Sans font files. `myapp/lib/widgets/common/welcome_splash.dart` references `assets/images/logo.png`. Font files are loaded by Flutter through the manifest rather than direct source references, so a raw text search is not evidence of unused fonts.

**Classification:** `KEEP` for the declared logo and fonts. The identical Black/ExtraBold pair is `NEEDS MANUAL VERIFICATION`.

### Root web public assets

- `public/favicon.ico` and `public/favicon.png` are referenced by web HTML/configuration and should be retained.
- `public/OneSignalSDKWorker.js` is referenced by `src/lib/onesignal.ts` and should be retained if push notifications remain enabled.
- `public/robots.txt` had no source text reference. It is a conventional deployment asset and may be consumed directly by crawlers.

**Classification:** `NEEDS MANUAL VERIFICATION` for `public/robots.txt`; not safe to call unused solely from source search.

## 9. Dependency review

### Flutter dependencies

All declared runtime Flutter dependencies had at least one source or manifest-level indication of use:

- `provider`: state providers
- `intl`: date/formatting
- `uuid`: identifiers and upload filenames
- `url_launcher`: external links, calls, maps, and safety flows
- `lucide_icons_flutter`: app icons
- `supabase_flutter`: auth/database/storage/realtime
- `shared_preferences`: local settings and persisted state
- `http`: reverse geocoding/network helpers
- `image_picker`: image selection
- `geolocator`: location services

**Classification:** `KEEP`. No dependency is classified as unused. `pubspec.lock` must be retained for reproducible Flutter dependency resolution.

### Root web dependencies

The root `package.json` contains React, TanStack, Supabase, Radix, form, chart, notification, Capacitor, build, and server dependencies. Static counting found direct or indirect evidence for the primary runtime/build dependencies. Radix primitives with low direct usage are generated-style components and need language-server/build verification before removal.

`package-lock.json` and `bun.lock` both exist. This is a potential package-manager duplication, but `package.json` does not itself establish which lockfile is canonical. Removing either can break reproducibility or deployment.

**Classification:** `NEEDS MANUAL VERIFICATION` for lockfile choice; `DO NOT REMOVE` both until package-manager policy is established.

## 10. Temporary, logs, and generated artifacts

### Disposable diagnostics

- `myapp/hs_err_pid20980.log`
- `myapp/hs_err_pid24488.log`
- `myapp/replay_pid24488.log`
- `android/hs_err_pid17080.log`
- `android/replay_pid17080.log`

The Android copies were found during repository inventory as well. They are JVM/Gradle crash/replay diagnostics, not application inputs. The two `myapp` crash/replay groups are high-confidence cleanup candidates; Android copies are also likely disposable but should be checked against any active build incident before removal.

### Generated artifacts

The root and Flutter build/cache directories listed in Section 4 are reproducible and should remain ignored. Do not manually edit generated files or commit them.

`myapp/android/build/reports/problems/problems-report.html` is generated Gradle diagnostics. Retain only when investigating a specific build problem; otherwise classify as `GENERATED / RECREATABLE`.

## 11. Documentation and reports

No report is declared obsolete solely because it is old. The documentation set contains explicit relationships:

- UI implementation report cites the UI audit.
- Messaging hardening report cites the forensic audit.
- Poll report is associated with active untracked poll regression work.
- Project PDF has conflicting root/Flutter copies and pending worktree changes.

The likely future cleanup is consolidation/archive, not deletion:

1. Choose a canonical current audit.
2. Preserve linked historical reports in an archive directory or release record.
3. Keep unique setup, incident, and verification sections.
4. Resolve the duplicate project PDF state before removing either copy.

**Classification:** `NEEDS MANUAL VERIFICATION` for all report/document groups.

## 12. Security-related file warnings

### SECURITY REVIEW

- Root `.env` exists. Do not print its contents, commit it, or move it into the report. Verify that it contains only client-safe configuration where applicable and that privileged credentials are not exposed to browser code.
- Supabase configuration and migrations under `supabase/` can encode security assumptions, RLS, RPC, and deployment state. Do not remove or edit migrations as cleanup.
- Android signing references include `myapp/android/key.properties` by convention and are protected by Android ignore rules. The file was not present in the visible inventory; verify local secret handling without exposing values.
- Root `supabase/.temp/linked-project.json` is local tooling metadata and may identify a remote project. Treat it as sensitive/local state; do not publish it.

No secret values, tokens, credentials, private keys, or environment contents are reproduced in this report.

## 13. Files that must definitely be retained

These groups are `DO NOT REMOVE` unless the application architecture is intentionally changed and rebuilt:

1. `myapp/pubspec.yaml` and `myapp/pubspec.lock`
2. Root `package.json`, the canonical selected lockfile, `vite.config.ts`, `tsconfig.json`, and `capacitor.config.ts`
3. Flutter entry point `myapp/lib/main.dart`
4. Root entry/router files: `src/entry-client.tsx`, `src/router.tsx`, `src/routeTree.gen.ts`, `src/start.ts`, and `src/server.ts`
5. `myapp/android/` Gradle files, manifests, signing references, and platform resources
6. `myapp/web/` manifest, index, icons, and favicon resources
7. `supabase/migrations/` and `supabase/config.toml`
8. Tests protecting messaging, polls, location, expenses, safety, and virtual plans
9. `scripts/prepare-capacitor-build.js`, `public/OneSignalSDKWorker.js`, and `generate_documentation_pdf.py` while their corresponding workflows remain supported

## 14. Prioritized cleanup checklist

### Priority 1 — Safe after process/incident confirmation

- [ ] Confirm no JVM/Gradle incident investigation needs the crash/replay logs.
- [ ] Archive or remove `myapp/hs_err_pid*.log`, `myapp/replay_pid*.log`, and Android crash/replay logs.
- [ ] Confirm no local Flutter/Gradle build is running before removing generated caches.

### Priority 2 — Generated output maintenance

- [ ] Establish standard cleanup instructions for `myapp/build/`, `myapp/.dart_tool/`, `dist/`, `.output/`, `.wrangler/`, `.tanstack/`, and `node_modules/`.
- [ ] Confirm all are ignored and absent from version control.
- [ ] Do not remove `.output/` while a Capacitor preparation/deployment task is active.

### Priority 3 — Manual source verification

- [ ] Use Dart/TypeScript language-server references for `app_field.dart`, `remote_image.dart`, `city-combobox.tsx`, `drawer.tsx`, `sidebar.tsx`, and any low-use UI primitives.
- [ ] Run the relevant web build and Flutter tests in a controlled branch before removing any source.
- [ ] Exercise dynamic routes, auth, profile/location, messaging, and image flows.

### Priority 4 — Documentation consolidation

- [ ] Resolve root/Flutter project PDF ownership and the tracked deletion/untracked copy.
- [ ] Compare overlapping messaging and UI reports and preserve unique evidence.
- [ ] Keep current release/security audit records until remediation is signed off.

### Priority 5 — Security and dependency governance

- [ ] Verify `.env`, signing, and Supabase local metadata handling without exposing values.
- [ ] Select one canonical JavaScript package manager and document the lockfile policy.
- [ ] Recheck dependency usage after route/component stabilization; do not remove packages solely from text counts.

## 15. Verification commands and expected effects

The following are proposed follow-up commands, not commands run by this audit:

```powershell
# Inspect candidate status without changing files
git status --short
git ls-files --others --exclude-standard

# Confirm generated/build output is ignored
git check-ignore -v myapp/build myapp/.dart_tool dist .output node_modules

# Verify exact duplicate files before any resource cleanup
Get-FileHash <path>

# Flutter reference/build verification
flutter analyze
flutter test

# Root web verification
bun run lint
bun run build

# Language-server references should be preferred for individual source candidates.
```

Expected effects:

- `git status` and `git check-ignore` are read-only.
- Hashing and reference searches are read-only.
- Flutter/web validation may update local caches or generated output; run only in a controlled worktree and do not interpret a successful build as proof that a dynamically loaded file is unused.
- No cleanup command is authorized by this report.

## 16. Limitations and false-positive risks

- Static filename/import searches cannot detect all dynamic imports, reflection, generated references, route registration, alias imports, browser direct requests, or future feature use.
- Root web UI primitives resemble generated shadcn components; low direct references are not proof of dead code.
- Flutter asset and font usage is declared through `pubspec.yaml`; raw source search undercounts it.
- Android resource duplicates are selected by density/night/API qualifiers; identical hashes do not make them removable.
- Both `bun.lock` and `package-lock.json` exist, but package-manager ownership was not inferred.
- No dependency installation, build, test, formatter, cleanup, or remote Supabase operation was run for this audit.
- Generated directories were measured but not fully enumerated file-by-file because they are reproducible outputs and would overwhelm the application inventory.
- The report itself was created at the requested path because it did not exist. Existing `myapp/docs/AUDIT_REPORT.md` was not overwritten.
- The tagged editor snapshot of `edit_plan_modal.dart` was treated as read-only context; no snapshot or application file was edited.

## 17. Audit integrity confirmation

- [x] Git status inspected before analysis.
- [x] Root web application and Flutter application distinguished.
- [x] Supabase migrations/configuration identified and left untouched.
- [x] Existing modified, deleted, and untracked work preserved.
- [x] Secrets and environment values not printed.
- [x] No delete, move, rename, clean, reset, install, upgrade, migration, or remote mutation command was run.
- [x] Only `myapp/docs/UNNECESSARY_FILES_AUDIT.md` was created by this audit.
- [x] No existing project file was modified by this audit.
