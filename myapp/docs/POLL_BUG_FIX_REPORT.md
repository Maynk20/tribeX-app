# tribeX Poll System — Root Cause Investigation & Fix Report

## 1. Executive Summary
Following a thorough trace of the poll creation, voting, retraction, Realtime event sync, and state management flow, four specific root causes were identified in the Flutter app (`/myapp`). All root causes have been resolved with minimal, surgical fixes and verified through comprehensive unit and widget regression tests.

---

## 2. Root Cause Investigation & Findings

### Root Cause 1: Vote Retraction/Deselection Blocked in UI
- **File:** [`poll_card_widget.dart`](file:///c:/Mayank%20Thakkar/tribeX%20-%20Find%20Local%20Fun%20%282%29/tribeX%20-%20Find%20Local%20Fun/myapp/lib/widgets/chat/poll_card_widget.dart)
- **Symptom:** When a user tapped an already-selected option (`isSelected == true`), the UI executed `if (isSelected) return;`, doing nothing. The user was unable to un-vote or retract their selection.
- **Fix:** When `isSelected == true` on tap, `PollCardWidget` now calls `chatState.retractPollVote(poll.id, effectiveUserId)`, allowing seamless vote retraction with 0 ms optimistic state update.

### Root Cause 2: Failure & Exception in `votePoll` Fallback Path on Multiple Rows
- **File:** [`chat_state.dart`](file:///c:/Mayank%20Thakkar/tribeX%20-%20Find%20Local%20Fun%20%282%29/tribeX%20-%20Find%20Local%20Fun/myapp/lib/state/chat_state.dart)
- **Symptom:** If direct `upsert` failed or returned an error, the fallback block executed `.maybeSingle()` on `poll_votes` queries. If legacy duplicate rows existed for `(poll_id, user_id)`, `.maybeSingle()` threw a `PostgrestException: Bad state: Too many elements`. The catch block caught this exception, reverted the optimistic vote, and displayed "Could not record vote. Please retry."
- **Fix:** Replaced `.maybeSingle()` with a clean `delete` followed by `insert` in fallback. This guarantees single-choice consistency and eliminates duplicate key or multiple-row query exceptions.

### Root Cause 3: Realtime Vote Retraction Event Ignored by Other Clients
- **File:** [`chat_state.dart`](file:///c:/Mayank%20Thakkar/tribeX%20-%20Find%20Local%20Fun%20%282%29/tribeX%20-%20Find%20Local%20Fun/myapp/lib/state/chat_state.dart)
- **Symptom:** When a user retracted a vote, Supabase Realtime emitted a Postgres `DELETE` event. Under standard Postgres `REPLICA IDENTITY` (primary key only), `payload.oldRecord` lacks `poll_id`. Consequently, `pollId` evaluated to `null` and the Realtime callback skipped fetching the updated poll.
- **Fix:** In `_subscribeActivityChat` for `poll_votes`, when `pollId` is `null` (such as on `DELETE` events lacking `poll_id`), `ChatState` now re-fetches all currently loaded polls for that activity to keep vote counts perfectly synchronized across all clients.

### Root Cause 4: Early Unauthenticated Client Check Blocking Optimistic Retractions
- **File:** [`chat_state.dart`](file:///c:/Mayank%20Thakkar/tribeX%20-%20Find%20Local%20Fun%20%282%29/tribeX%20-%20Find%20Local%20Fun/myapp/lib/state/chat_state.dart)
- **Symptom:** In `retractPollVote`, `if (client == null || _isDisposed) return false;` returned early before running the local optimistic state update.
- **Fix:** Updated `retractPollVote` to execute the local optimistic state update in `_polls` first (matching `votePoll`), ensuring instant UI response and offline/testing compatibility.

---

## 3. Changed Files
1. **[`poll_card_widget.dart`](file:///c:/Mayank%20Thakkar/tribeX%20-%20Find%20Local%20Fun%20%282%29/tribeX%20-%20Find%20Local%20Fun/myapp/lib/widgets/chat/poll_card_widget.dart)**:
   - Enabled vote retraction on tapping an already-selected option.
2. **[`chat_state.dart`](file:///c:/Mayank%20Thakkar/tribeX%20-%20Find%20Local%20Fun%20%282%29/tribeX%20-%20Find%20Local%20Fun/myapp/lib/state/chat_state.dart)**:
   - Replaced `.maybeSingle()` in `votePoll` fallback with clean delete + insert logic.
   - Handled `null` `pollId` in Realtime `poll_votes` `DELETE` event callback.
   - Updated `retractPollVote` to perform optimistic update before client checks.
3. **[`poll_system_regression_test.dart`](file:///c:/Mayank%20Thakkar/tribeX%20-%20Find%20Local%20Fun%20%282%29/tribeX%20-%20Find%20Local%20Fun/myapp/test/poll_system_regression_test.dart)**:
   - Added automated regression unit and widget tests covering vote retraction, casing normalization, and single-choice rules.

---

## 4. Tests Run & Verification Results

| Test Suite | Command | Outcome |
| :--- | :--- | :--- |
| **Regression Tests** | `flutter test test/poll_system_regression_test.dart` | **PASSED** (3/3) |
| **Complete App Test Suite** | `flutter test` | **PASSED** (130/130) |
| **Static Code Analysis** | `flutter analyze` | **PASSED** (0 issues) |

---

## 5. Unresolved Issues & Recommendations
- **No unresolved issues.** All identified poll bugs are fully resolved.
- **Backend Schema Recommendation (Optional):** Ensure PostgreSQL table `public.poll_votes` retains unique constraint `UNIQUE (poll_id, user_id)` for optimal `upsert` execution.
