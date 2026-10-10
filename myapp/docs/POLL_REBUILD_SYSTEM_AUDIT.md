# TribeX — Poll System Rebuild: Phase A System Audit & Architecture Plan

**Date:** 10 October 2026  
**Scope:** `/myapp` (Flutter), Supabase schema, Realtime channels, and Legacy compatibility.

---

## 1. Existing System Audit

### 1.1 Database Schema & Tables
- **`public.polls`**:
  - Columns:
    - `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
    - `activity_id UUID NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE`
    - `created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
    - `question TEXT NOT NULL`
    - `options JSONB NOT NULL` (array of option string labels)
    - `closed_at TIMESTAMPTZ` (null = open, non-null = closed)
    - `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`
  - Index: `idx_polls_activity ON public.polls(activity_id, created_at DESC)`
  - RLS Policies:
    - SELECT: `created_by = auth.uid() OR public.has_activity_access(activity_id, auth.uid())`
    - INSERT: `auth.uid() = created_by AND public.has_activity_access(activity_id, auth.uid())`
    - UPDATE: `auth.uid() = created_by`
    - DELETE: `auth.uid() = created_by`
  - Realtime: `REPLICA IDENTITY FULL`, registered in `supabase_realtime` publication.

- **`public.poll_votes`**:
  - Columns:
    - `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
    - `poll_id UUID NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE`
    - `user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
    - `option_index INT NOT NULL CHECK (option_index >= 0 AND option_index < 20)`
    - `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`
  - Unique Constraint: `UNIQUE (poll_id, user_id)` — strictly enforces 1 active vote per user per poll at the database level.
  - Index: `idx_poll_votes_poll ON public.poll_votes(poll_id)`
  - RLS Policies:
    - SELECT: Plan members (creator or has_activity_access).
    - INSERT: `auth.uid() = user_id AND has_activity_access`.
    - UPDATE: `auth.uid() = user_id`.
    - DELETE: `auth.uid() = user_id`.
  - Realtime: `REPLICA IDENTITY FULL`, registered in `supabase_realtime` publication.

### 1.2 Message Representation & Legacy Token Compatibility
- Standard format: `[[poll:<uuid>]] <question>` (matches TanStack Start / React web).
- Legacy format: `POLL:<uuid> ...`.
- Token extraction via `Message.pollId` regex `RegExp(r'\[\[poll:([a-zA-Z0-9_-]+)\]\]')` and `POLL:<id>` prefix.
- `ChatScreen` renders `PollCardWidget(pollId: m.pollId, currentUserId: me?.id)`. The internal token is hidden from raw message bubbles.

### 1.3 Identified Deficiencies
1. **Lack of CRUD Completeness**:
   - Update: No mechanism for poll creators to edit question, edit options (when no votes exist), or toggle poll closure (`closed_at`).
   - Delete: No UI or workflow for authorized poll deletion. If deleted, messages had no tombstone handling.
2. **Architecture Monolith**:
   - `chat_state.dart` previously mixed poll REST queries, vote counting, optimistic updates, and fallback paths directly inside a 1700-line class.
3. **Existing Poll Management in Chat**:
   - Users viewing an existing poll in chat had no way to see creator actions, poll status (open/closed), or manage the poll in-place.
4. **Concurrency & Safe Synchronization**:
   - When multiple users vote or retract simultaneously, optimistic state must reliably reconcile against Supabase Realtime without clobbering in-flight user taps.

---

## 2. Rebuild Architecture Overview

- **Repository Layer (`myapp/lib/repositories/poll_repository.dart`)**:
  - Encapsulates all Supabase queries, RLS error handling, validation, single-choice voting, retraction, and CRUD operations.
- **Model Layer (`myapp/lib/models/poll.dart`)**:
  - Fully typed, immutable `Poll` and `PollOption` models with vote-casing normalization, single-choice enforcement, deadline/closure checking, and serialization.
- **State Management Layer (`myapp/lib/state/chat_state.dart`)**:
  - Cleanly coordinates `PollRepository`, manages in-memory `_polls`, dispatches optimistic updates, handles Realtime events, and notifies UI listeners.
- **UI Components**:
  - `CreatePollModal`: Robust validation (2–6 unique options, non-empty question), double-submission prevention.
  - `EditPollModal`: Safe editing for creators (question edit, option management if unvoted, deadline/status adjustment).
  - `PollCardWidget`: Displays live percentages, animated progress bars, user vote checkmark, creator action menu (Edit, Close/Reopen, Delete), and closed status banner.
