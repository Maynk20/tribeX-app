# tribeX UI/UX Audit Report

**Audit date:** 10 October 2026  
**Scope:** Flutter application UI only  
**Requested outcome:** Make the product feel intentional, human, local and premium; avoid a generic AI/template-generated appearance.  
**Code changes:** None. This document is the only deliverable from this audit.

## 1. Executive Summary

The application has a coherent visual base: Plus Jakarta Sans, an indigo/emerald palette, dark-mode tokens, reusable cards, bottom navigation, loading states, error states and several useful safety affordances. The product is not visually broken at a structural level.

However, the current UI feels more like a well-assembled design system demo than a distinctive local-community product. The strongest reasons are:

1. Almost every surface uses the same large rounded card treatment.
2. Uppercase micro-headings, pills, emoji category markers and indigo accents are repeated too frequently.
3. Several screens are very large, form-heavy and vertically dense.
4. Important actions compete with secondary actions because hierarchy is mostly expressed through color and rounded containers.
5. Accessibility and responsive behavior are not consistently treated as first-class requirements.
6. The app has many bespoke styles in screens instead of relying on the central theme, so visual drift will increase as features are added.

### Overall assessment

| Area | Rating | Assessment |
|---|---:|---|
| Visual foundation | 7/10 | Good tokens, font and light/dark structure |
| Brand distinctiveness | 4/10 | Feels generic; needs a stronger local/social identity |
| Information hierarchy | 6/10 | Understandable, but too many equal-weight containers |
| Interaction clarity | 6/10 | Core flows are discoverable; secondary states need clearer feedback |
| Accessibility | 4/10 | Small text, gesture-only controls and inconsistent semantics |
| Responsive resilience | 5/10 | Mobile-first, but several fixed rows and dense forms are fragile |
| Maintainability of UI | 4/10 | Very large screen files and duplicated styling patterns |

## 2. Audit Method and Limitation

Inspected all primary screens under `myapp/lib/screens`, shared widgets under `myapp/lib/widgets`, the theme/color tokens, navigation and common loading components.

The local prebuilt web shell was opened for a visual smoke check. The browser reported `403 Forbidden` for local JavaScript/preloaded resources and rendered only a dark blank shell. Therefore:

- The report is based primarily on source-level UI inspection.
- The report does not claim pixel-perfect findings from a fully interactive runtime session.
- Before implementation, the app should be run on a real Android/iOS device or a working Flutter web dev server at narrow, standard and large widths.

## 3. What Is Already Good

### 3.1 Consistent base design language

- `Plus Jakarta Sans` is defined centrally.
- Light and dark color tokens are present.
- `Card`, `Dialog`, `BottomSheet`, input and button themes are configured centrally.
- The app has consistent use of loading, retry and empty states in discovery and messaging surfaces.

### 3.2 Good product-specific affordances

- Explore has GPS/location context and a visible 15 km discovery concept.
- Activity cards expose virtual, safety, urgency and join status.
- Chat supports polls, expense splitting, check-in and memories.
- Profile and settings include safety, reporting, feedback and account controls.
- Auth is a two-step email/OTP flow with resend cooldown and contextual notices.

### 3.3 Good failure-state intent

The code includes skeletons, retry controls, `RefreshIndicator`, failed-message retry and location feedback. These are valuable foundations; the next step is to make the states more visually differentiated and less generic.

## 4. Cross-App Findings

### P1 — The UI is over-rounded and over-cardified

**Evidence:** The theme uses 24–28 px card/dialog radii, 18 px inputs/buttons, and screens repeatedly wrap content in bordered rounded containers. Activity cards, profile sections, settings groups, modals and empty states all use similar treatments.

**Why it matters:** When every element is a floating card, nothing feels primary. This is a common “AI-generated app” signal: the same radius, border, shadow and padding are applied everywhere.

**Recommendation:**

- Use three surface levels only: page background, grouped section, primary feature card.
- Reduce default card radius to 16–20 px; reserve 24–28 px for hero/feature surfaces.
- Use dividers and whitespace for settings lists instead of putting every group inside a floating card.
- Remove most borders from low-priority surfaces and let spacing create hierarchy.
- Keep one signature shape for brand moments rather than applying rounded corners universally.

### P1 — Brand identity is currently a color palette, not a product identity

**Evidence:** The visual system is primarily indigo, emerald, rounded cards, emoji category markers and Lucide/Material icons.

**Why it matters:** The UI can be mistaken for a generic social/planning dashboard. Local fun/community products need recognizable editorial cues: place, people, time and energy.

**Recommendation:**

- Establish a clear brand motif around local discovery: map contours, neighborhood labels, venue photography, distance and time.
- Use real activity imagery as the visual anchor on Explore rather than treating images as optional card decoration.
- Define a small icon strategy: Lucide for navigation/actions, Material only where platform semantics require it.
- Replace decorative emoji dependence with category color/illustration plus optional emoji.
- Add one distinctive brand element to headers, empty states and splash; do not add gradients merely to look modern.

### P1 — Typography hierarchy is too dependent on uppercase micro-labels

**Evidence:** Explore, Messages, Profile, Complete Profile and Settings repeatedly use labels such as `INBOX`, `PROFILE`, `PREFERENCES`, `STEP 1 OF 1` with tracking around 1.5–1.8.

**Why it matters:** Repeated uppercase labels make the app feel like a template and reduce natural reading flow. Important content competes with decorative metadata.

**Recommendation:**

- Use sentence-case section headings by default.
- Keep uppercase labels only for compact metadata such as category, distance or status.
- Define a clear title/subtitle/body scale and use theme text styles instead of local `TextStyle` values.
- Avoid 10–11 px text for essential instructions; use at least 12–13 px with adequate contrast.

### P1 — Too much styling is duplicated inside screens

**Evidence:** Large screens contain many direct `TextStyle`, padding, radius and color values. `create_plan_screen.dart`, `profile_screen.dart`, `settings_screen.dart` and `explore_screen.dart` are each very large.

**Why it matters:** Visual consistency will degrade with every feature. A later change to spacing, button height or typography will require many manual edits.

**Recommendation:**

- Introduce reusable UI primitives: `SectionHeader`, `AppField`, `PrimaryActionButton`, `StatusPill`, `EmptyState`, `Avatar`, `SurfaceCard`.
- Move repeated measurements into spacing/radius tokens.
- Make screen-level code describe content and state, not draw every border and shadow.
- Use `Theme.of(context).textTheme` for standard text and override only when the component is intentionally special.

### P1 — Accessibility is inconsistent

**Evidence:**

- Navigation items use `GestureDetector` rather than semantic buttons.
- Interest/category chips use `GestureDetector`.
- Several icon-only controls have no tooltip or semantic label.
- Essential supporting text often uses 10–12 px.
- Muted foreground colors are used extensively for instructions and metadata.

**Risk:** Screen readers may not announce controls correctly; touch targets and contrast may be insufficient for users with low vision or motor limitations.

**Recommendation:**

- Prefer `InkWell`, `IconButton`, `FilterChip`, `ChoiceChip` or `Semantics(button: true, ...)` for interactive controls.
- Add labels/tooltips to every icon-only action.
- Keep interactive targets at least 44×44 logical pixels.
- Test text scaling at 200% and verify no clipped labels.
- Add automated contrast and semantics checks to the UI test suite.

### P1 — Network-image fallback is not uniform

**Evidence:** Several avatar surfaces use `NetworkImage` directly, while some larger `Image.network` surfaces have an `errorBuilder`.

**Risk:** A broken avatar URL can produce a blank or visually broken identity surface instead of a consistent initial/fallback avatar.

**Recommendation:**

- Create one `UserAvatar` component with loading, error and initials states.
- Create one `RemoteImage` component with placeholder, error state and crop policy.
- Never render a bare `NetworkImage` for a user identity surface.

### P2 — Dark mode is tokenized but not fully audited for semantic contrast

**Evidence:** Theme tokens exist, but many screen-level styles use `AppColors.mutedForegroundLight` directly in shared-looking controls and loading indicators.

**Recommendation:**

- Audit every screen in dark mode, especially search fields, secondary labels, empty states, bottom navigation and modal subtitles.
- Do not use light-mode muted colors in dark-mode input decorations or supporting text.
- Add screenshot/contrast checks for both themes.

## 5. Page-by-Page Findings

## 5.1 Explore / Home

**File:** `myapp/lib/screens/explore_screen.dart`

### Strengths

- Clear discovery purpose.
- Search, filters, location selection, pull-to-refresh and scroll-to-top are useful.
- Loading, connection-error, signed-out and empty-list states are present.
- Activity cards expose safety and join context.

### Issues

1. **Header density is high.** Location, notification, avatar/sign-in, search, filter state and distance context compete above the list.
2. **15 km behavior is not obvious enough.** The timer-based active state can feel arbitrary unless the UI clearly explains whether the radius is automatic, user-selected or temporary.
3. **Search and filter are visually similar to other bordered cards.** The primary discovery action does not stand out enough.
4. **Empty/error states are generic.** `wifiOff` and connection copy are functional but do not help the user discover the first local activity.
5. **Activity cards are visually heavy.** Large radius, border, shadow, emoji box, badges and actions create a lot of decoration before the user reaches the core decision: “Do I want to join?”
6. **Location permission failure needs a more direct recovery path.** The current copy sends users to Settings but does not always explain why location is needed or offer city selection in the same state.
7. **Avatar/image fallbacks are inconsistent.**

### Recommended changes

- Make the top area a compact “near you” header with one location control and one notification control.
- Put radius/filter state in a compact filter row below search.
- Give the first recommended activity a stronger editorial/hero treatment; make subsequent cards simpler.
- Show distance, date/time and slots as the first information row.
- Add a clear “Browse all” mode when location is unavailable.
- Improve empty state with category shortcuts and “Create the first plan” CTA.

## 5.2 Create Plan

**File:** `myapp/lib/screens/create_plan_screen.dart`

### Strengths

- Validation covers title, description, location, online event URL and upload state.
- Date/time, cover, amenities, capacity, cost, tags and safety options are meaningful product fields.
- GPS pinning and online-event branching are useful.

### Issues

1. **The form is too long for one screen.** The file is approximately 1,640 lines and the form contains many decisions before publish.
2. **The user is not given a clear progress model.** There is no stepper or “Basics → Place & time → Rules → Preview” structure.
3. **Online and physical plan fields are mixed conditionally.** This increases cognitive load and makes it easy to miss required venue/meeting information.
4. **The publish action is far away.** Users can lose context while scrolling through a long form.
5. **Validation is mostly toast-driven.** Inline field-level errors would reduce repeated scrolling and guesswork.
6. **The cover image is treated as an upload task, but there is no strong content guidance.**
7. **The form has many optional controls before the user has confirmed the core plan.**

### Recommended changes

- Convert to a 3-step flow:
  1. What/when
  2. Where/who
  3. Details/preview
- Keep a sticky bottom action with `Continue`/`Publish`.
- Show inline errors under fields.
- Add a final preview card exactly as it will appear in Explore.
- Default optional controls closed under “More settings”.
- Separate “Online event” mode into a clear segmented choice at the top.

## 5.3 Messages / Inbox

**File:** `myapp/lib/screens/messages_screen.dart`

### Strengths

- Search is present.
- Chats sort by latest message with event fallback.
- Signed-out and empty states are handled.
- Pull-to-refresh is appropriate.

### Issues

1. **The screen is called “Messages” but the list is activity-centric.** This is valid, but the UI should explicitly explain that each row represents a squad/event chat.
2. **No unread visual system is evident at the page level.** Notifications exist, but chat recency/unread priority should be immediately visible.
3. **Empty state lacks a discovery CTA.** A user with no chats should be directed to Explore or Create Plan.
4. **Search likely matches title/location/category but not participant or latest message.** This limits expected inbox behavior.
5. **The `INBOX` label is template-like and does not add much information.**

### Recommended changes

- Use activity thumbnail/category, latest message preview, time and unread count in each row.
- Add “Explore plans” and “Create a plan” actions in the empty state.
- Search by activity title, location, participant name and latest message.
- Use swipe/archive or a clear chat action only if the product supports it; avoid adding decorative controls.

## 5.4 Profile

**File:** `myapp/lib/screens/profile_screen.dart`

### Strengths

- Signed-out state is clear.
- Hosted/joined plan separation is useful.
- Settings access is prominent.
- Profile, ratings, squad plans and safety actions are product-relevant.

### Issues

1. **The profile page is very long and combines identity, stats, plans, safety, ratings and account actions.**
2. **“You” is a weak page title.** It is friendly but does not communicate the profile surface as clearly as “Profile”.
3. **Hosted/joined tabs need stronger active-state clarity and counts.**
4. **Identity area is visually similar to settings section cards, so the profile hero lacks emphasis.**
5. **Plan cards and account controls have competing visual weight.**
6. **The user’s trust/reliability story is not surfaced as a clear summary.**

### Recommended changes

- Create a compact profile hero: avatar, name, city, reliability, verification and edit action.
- Use summary stats before long lists.
- Add counts to Hosted and Joined.
- Separate “Your activity” from “Safety & account”.
- Make ratings/reliability explainable with an info affordance.
- Keep emergency SOS prominent but visually distinct from ordinary profile actions.

## 5.5 Chat

**File:** `myapp/lib/screens/chat_screen.dart`

### Strengths

- Core squad chat has polls, expenses, check-in, memories, report/block and virtual meeting support.
- Older-message loading and realtime reconnect behavior exist.
- Poll and expense cards make the chat product-specific.
- Failed messages have retry affordances.

### Issues

1. **The composer has many attachment capabilities.** Expense, poll, memory and check-in actions can overwhelm a first-time user.
2. **Special cards are visually more prominent than ordinary conversation.** This can make the timeline feel like a dashboard rather than a chat.
3. **Message failure/retry states should be clearer and more compact.**
4. **The top context/header should make activity title, date, member count and safety state immediately visible.**
5. **A long chat with polls and expenses needs stronger grouping and timestamps.**
6. **Meeting-link and safety actions need predictable placement rather than being discovered through secondary controls.**

### Recommended changes

- Keep one attachment button and present a labeled action sheet with clear hierarchy.
- Group poll/expense/check-in cards as “Squad tools” while preserving chronological placement.
- Add a compact activity header with title and member count.
- Use a clear “sending / failed / retry” pattern with icon + text + timestamp.
- Add a pinned event summary for date, venue and meeting link.

## 5.6 Authentication

**File:** `myapp/lib/screens/auth_screen.dart`

### Strengths

- Signup/login mode handling is explicit.
- OTP resend cooldown is implemented.
- Account-exists/no-account notices provide useful recovery.
- Email and username validation are present.

### Issues

1. **The default mode is signup.** Returning users may land on a registration-looking screen instead of a neutral sign-in entry.
2. **The auth screen appears form-heavy for a simple OTP action.**
3. **The OTP step needs a strong “change email” action and clearer expiry/resend hierarchy.**
4. **Terms/policy consent should be visually explicit at signup, not only reachable elsewhere.**
5. **Error notices and toasts may duplicate one another.**

### Recommended changes

- Start with a neutral “Continue with email” entry or remember the last mode.
- Make `Change email`, resend timer and code expiry visibly distinct.
- Put policy consent directly under the signup action.
- Keep one inline error plus one toast only for transient network failures.

## 5.7 Complete Profile

**File:** `myapp/lib/screens/complete_profile_screen.dart`

### Strengths

- Clear profile completion goal.
- City picker and coordinates are product-relevant.
- Optional phone and bio reduce friction.

### Issues

1. **The page does not show the onboarding journey clearly.** It transitions to interests, but there is no progress indicator.
2. **City/location is required but the reason is not explained near the field.**
3. **The gender field is visually equal to the location field even though location enables discovery/safety behavior.**
4. **The save button spinner uses a hardcoded black indicator, which can be low-contrast on dark or colored button states.**

### Recommended changes

- Add `Step 1 of 2` / `Step 2 of 2` consistently.
- Explain location use: discovery radius, plan safety and check-in.
- Prioritize city/location before optional profile metadata.
- Use theme-aware loading indicators.

## 5.8 Onboarding

**File:** `myapp/lib/screens/onboarding_screen.dart`

### Strengths

- Minimum three interests is explicit.
- Selected/unselected states are easy to understand.
- The grid is compact and familiar.

### Issues

1. **“STEP 1 OF 1” is confusing.** It implies a multi-step flow but says there is only one step.
2. **Emoji-only category treatment can feel playful but generic and inconsistent with the rest of the product.**
3. **There is no “skip/change later” explanation.**
4. **A large list of chips may be visually dense on small screens.**
5. **Selection is color-dependent; selected state should include a check icon or stronger shape change.**

### Recommended changes

- Change copy to “Choose your interests” unless more steps are planned.
- Add a short privacy/value explanation: how interests improve recommendations.
- Add a selected check icon and retain readable text contrast.
- Consider grouped categories or a search field if the list grows.

## 5.9 Settings

**File:** `myapp/lib/screens/settings_screen.dart`

### Strengths

- Settings includes appearance, push notifications, profile editing, FAQs, report, feedback, policies and delete account.
- Destructive action confirmation is present.
- FAQ accordion is a sensible choice.

### Issues

1. **Settings is overloaded.** Profile editing, support, legal, safety and account deletion are all on one long page.
2. **Some sections are visually indistinguishable from one another.**
3. **The edit-profile bottom sheet is very large and itself contains many controls.**
4. **Avatar URL presets are implementation-oriented rather than user-oriented.**
5. **Delete-account flow is high-risk and should have stronger irreversible-action language and final confirmation.**
6. **The page has many local styles and long conditional sections, increasing visual drift.**

### Recommended changes

- Split into:
  - Profile
  - Preferences
  - Safety & privacy
  - Help & feedback
  - Account
- Use list rows with dividers for ordinary settings; reserve cards for warnings and featured actions.
- Replace avatar URL editing with image selection/upload and a reliable fallback.
- Add a dedicated privacy/location explanation screen.
- Make delete-account confirmation explicitly state what is deleted and what cannot be recovered.

## 5.10 Terms & Policies

**File:** `myapp/lib/screens/terms_and_policies_screen.dart`

### Strengths

- Content is readable and divided into sections.
- Cards provide clear grouping.

### Issues

1. **“Last updated: October 2025” is stale for a 2026 product build.** This undermines trust.
2. **Legal content is presented as a long stack of rounded cards without table-of-contents navigation.**
3. **There is no acknowledgement/version state shown to the user.**
4. **The text is small and dense for a legal/safety surface.**

### Recommended changes

- Make the version and effective date authoritative and data-driven.
- Add a compact contents list with anchor navigation.
- Add “I understand”/acceptance state only where legally required.
- Separate Community Guidelines, Privacy, Safety and Payments into navigable sections.

## 6. Components and Modal Findings

### Activity card

**File:** `myapp/lib/widgets/activity/activity_card.dart`

- Strong product information density, but too many badges can make the card noisy.
- The category emoji box and multiple pills compete with the title.
- Join/manage/chat actions should have one primary CTA and visually quieter secondary actions.
- Long titles, venue names and host names need explicit overflow handling at narrow widths.
- Safety blocks are important; make them explanatory and actionable instead of only a badge.

### Poll card

**File:** `myapp/lib/widgets/chat/poll_card_widget.dart`

- Functional visual model with progress fills and selected state.
- Percentage plus vote count is useful.
- The card should clearly distinguish “not voted”, “your vote”, “closed” and “saving” without relying only on color.
- Consider a compact question header and more breathing room around long option text.

### Expense/check-in/memory cards

- These are valuable differentiators but should share a common “squad tool card” primitive.
- Current repeated borders, large radius and shadows make the chat timeline visually busy.
- Define a common header, status row and action footer.

### Bottom navigation

**File:** `myapp/lib/widgets/common/custom_bottom_nav.dart`

- Four destinations are understandable.
- The 56 px bar and top active pill are clean.
- The Create tab is not visually distinguished as the primary creation action; consider a central raised action only if it improves usability, not as decoration.
- Add semantic labels and verify safe-area behavior with keyboard and small-height devices.

### Loaders and empty states

**File:** `myapp/lib/widgets/common/loaders.dart`

- Skeleton exists but is a plain fixed-height rectangle and does not reflect the actual activity-card structure.
- Use content-shaped skeletons for image, title, metadata and action rows.
- Standardize empty state icon, title, explanation and primary action.

## 7. “AI-Like” Visual Signals to Remove

These are not functional bugs, but they materially affect perceived authenticity:

1. Repeating `rounded-3xl`-style surfaces everywhere.
2. Repeating uppercase tracking labels on almost every page.
3. Too many pills, badges and emoji markers.
4. Generic phrases such as “Find Local Fun”, “Your squad chats”, “What are you into?” without local context.
5. Equal visual treatment for primary, secondary and destructive actions.
6. Long screens that expose every possible capability at once.
7. Generic indigo UI without a recognizable photography, map or neighborhood language.
8. Inconsistent mix of Material icons, Lucide icons and emoji without a documented rule.

### Human/product direction

The desired visual direction should feel like a trusted local host, not an AI dashboard:

- Lead with place, time, people and activity energy.
- Use real imagery and short human copy.
- Show fewer, stronger actions.
- Let whitespace and typography create hierarchy.
- Use safety language plainly and respectfully.
- Keep the system slightly imperfect and warm; avoid over-polishing every block into a pill.

## 8. Priority Roadmap

### P0 — Before visual polish

1. Run the complete app on a real device and validate every route at 320 px, 375 px, 414 px and tablet width.
2. Fix any overflow, clipped text, keyboard inset and dark-mode contrast issues found in that pass.
3. Add reliable image/avatar fallback components.
4. Verify screen-reader labels and minimum touch targets.
5. Update the stale legal “last updated” date through an authoritative source.

### P1 — Highest UX impact

1. Redesign Create Plan as a multi-step flow with sticky actions and preview.
2. Simplify Explore header and activity-card hierarchy.
3. Restructure Settings into separate sections/screens.
4. Create a clear Profile hero and trust summary.
5. Simplify Chat attachments and unify squad-tool cards.
6. Reduce radius/border/shadow repetition and remove decorative uppercase labels.

### P2 — Brand and refinement

1. Establish a visual identity around local places, venue imagery and neighborhood context.
2. Standardize iconography and category representation.
3. Improve skeletons and empty states with task-oriented actions.
4. Add motion only for state transitions that communicate progress or completion.
5. Add visual regression screenshots for light/dark and major breakpoints.

## 9. Suggested Acceptance Checklist

Before calling the redesign complete:

- [ ] Every screen has one obvious primary action.
- [ ] No page requires excessive scrolling for its primary task.
- [ ] No essential text is below 12 px.
- [ ] All icon-only actions have labels/tooltips.
- [ ] All avatar and remote-image surfaces have fallback states.
- [ ] All forms show inline validation and preserve entered values after an error.
- [ ] Empty states include a relevant next action.
- [ ] Dark mode has equivalent contrast and no light-token leakage.
- [ ] Text scaling at 200% does not clip or overflow.
- [ ] 320 px width does not produce horizontal overflow.
- [ ] The UI uses a consistent radius, spacing and icon system.
- [ ] The app feels recognizable without relying only on the indigo color.

## 10. Final Recommendation

Do not start by adding more visual effects, gradients or AI-style decorative components. The highest-value work is hierarchy:

1. Simplify the number of simultaneous controls.
2. Reduce repeated cards/pills.
3. Make Explore and Create Plan more task-focused.
4. Make Profile and Settings easier to scan.
5. Add accessibility and responsive validation.
6. Then introduce a distinctive local-community brand layer using real places, people and activity imagery.

The existing implementation is a good functional foundation, but it needs a deliberate product-design pass rather than more isolated styling tweaks.
