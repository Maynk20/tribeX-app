
## Goal

Fix three user-reported bugs:
1. Hosted plans not appearing (Explore "Hosting" tab + Profile "Hosted" list stays 0), so Edit / Update / Delete are unreachable.
2. On the Create / Edit plan form, clicking **Replace** on the cover photo wipes the rest of the form / previous image state.
3. Activity cards collapse and overflow on narrow widths (badges, host row, and 5 action buttons squish together).

## Investigation notes (already gathered)

- DB has hosted rows for the current user (`activities.host_id`), `deleted_at IS NULL`. RLS SELECT includes `auth.uid() = host_id` branch, so the host is always allowed to read their own row.
- `getUserActivities` returns `{ hosted, joined }`. Profile derives counts from `hosted.length`. Explore "Hosting" scope filters `activities` (public feed) by `host_id === user.id || mineIds.has(a.id)` — this depends on `listActivities()` returning the host's own row, which the safety-filter RLS branch does allow, BUT the past-date filter at `index.tsx:277` drops it from Discover, and if the row isn't in the public list at all (e.g. filtered) we only fall back to `mineIds` (from `user-activities`). If `user-activities` is failing silently, Hosting tab and Profile both go empty.
- `getUserActivities` throws when `uid !== userId`; also `attachHosts` calls `profiles_public` — if that view SELECT returns an error it throws and the whole hook errors, leaving `acts` undefined and hosted = 0. Needs a targeted repro + guard.
- Card footer uses `flex-wrap` for stats with a host name that can't shrink inside `flex-wrap`, and the action row packs up to 5 buttons (`Urgent + Chat + Manage + Edit + Delete`) with `flex-1 whitespace-nowrap`, guaranteeing overflow at `sm` grid width.
- Replace button in `create.tsx` and `edit-plan-modal.tsx` opens the file picker. If the user picks a file, state updates correctly. Needs a live repro to confirm what "data chala jata hai" means — most likely candidates: (a) picker cancel path revoking preview, (b) `useEffect([activity])` in EditPlanModal re-running and resetting form when the query refetches mid-edit, (c) `existingImage` cleared when new file chosen but upload later fails and both are gone.

## Plan

### 1. Fix hosted plan visibility + CRUD reachability
- Add a `console.error`-plus-toast fallback in the `useQuery` for `user-activities` on Profile and Explore so a silent failure surfaces instead of showing 0.
- In `getUserActivities`:
  - Wrap `attachHosts(hostedRows)` failure so hosts still see their own rows (host profile is the current user — fetch from `profiles` directly if `profiles_public` lookup fails).
  - Return hosted rows even if the joined-side query errors (already done for joined; ensure hosted has the same isolation).
- On Explore "Hosting" tab, source the list from `getUserActivities().hosted` directly instead of filtering the public `listActivities()` feed. This guarantees the host sees every plan they own (including safety-filtered / past ones) with full Edit / Delete / Manage actions.
- Verify `updateActivity` / `deleteActivity` cache invalidation keys match `["user-activities", user.id]` in every mutation site (Create, Edit modal, Profile delete, Manage). Add a `refetchQueries` on the same key after edits.

### 2. Fix photo Replace losing data
- Repro in the browser with Playwright: open Edit modal, change title, click **Replace**, pick a new image, submit — confirm which fields reset.
- Likely fixes:
  - In `EditPlanModal`, change the `useEffect` dependency from `[activity]` to `[activity?.id]` so a background refetch of the same activity doesn't overwrite the user's in-progress edits.
  - Preserve `existingImage` alongside `imageFile` so if the upload later fails we don't leave the plan with no cover.
  - In `create.tsx` and `edit-plan-modal.tsx` `onPickImage`, only `URL.revokeObjectURL` the *previous preview* after successfully creating the new one (already done in edit; verify create).
  - Guarantee both Replace buttons have `type="button"` (Create already does; re-verify).

### 3. Fix card collapse / overflow
- ActivityCard footer:
  - Remove `flex-wrap` from the meta row; use a single line with `min-w-0` + `truncate` on the host name so nothing wraps into a second line.
  - Split action row into two lines on small screens: primary CTA (Join / Manage / Chat) on one row, host-only icon actions (Urgent, Edit, Delete) collapsed into an overflow menu or a smaller icon-only row so nothing squishes below usable width.
  - Cap Chat + Manage + primary CTA to `flex-1` and move Edit/Delete to fixed 32px icon buttons after them, never `flex-1`.
- Profile hosted-list row: keep single line but let the action cluster wrap under the title on `<= 360px` width so Manage/Edit/Delete stay tappable.

### 4. Verify
- Playwright: sign in as the seed user, create a plan, then check
  - Explore → Hosting tab shows the new plan with Edit / Delete / Manage.
  - Profile → Hosted tab count increments and the row shows Manage / Edit / Delete.
  - Edit the plan, click Replace, choose a new photo, save — title, description, category, tags, safety toggles all persist.
  - Resize viewport to 360px — cards render without horizontal scroll and buttons stay tappable.

## Out of scope
- No changes to auth, DB schema, or RLS policies unless investigation proves an RLS gap for the host's own rows (host SELECT branch already exists, so unlikely).
