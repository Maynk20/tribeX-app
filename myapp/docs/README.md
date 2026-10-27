# TribeX App — Complete Technical Architecture & System Documentation

> **Target Platform:** Flutter (Android & iOS) — `/myapp`  
> **Backend:** Supabase (PostgreSQL 15+, PostGIS, Realtime Engine, Storage, Auth)  
> **Repository Path:** `/myapp/docs/README.md`  
> **Status:** Production-Ready & Verified (216/216 Tests Passing)

---

## Table of Contents

1. [Executive Overview & Tech Stack](#1-executive-overview--tech-stack)
2. [API Keys, Environment Variables & Service Credentials](#2-api-keys-environment-variables--service-credentials)
   - [2.1 Key Inventory & Configuration Parameters](#21-key-inventory--configuration-parameters)
   - [2.2 Detailed Usage & Integration Points](#22-detailed-usage--integration-points)
   - [2.3 Security Boundaries & Client Protection Rules](#23-security-boundaries--client-protection-rules)
3. [End-to-End System Architecture](#3-end-to-end-system-architecture)
4. [User Flow & Lifecycle Journeys](#4-user-flow--lifecycle-journeys)
   - [4.1 User Authentication & Profile Onboarding](#41-user-authentication--profile-onboarding)
   - [4.2 Plan Discovery & Spatial Feed Engine](#42-plan-discovery--spatial-feed-engine)
   - [4.3 3-Step Plan Creation Flow](#43-3-step-plan-creation-flow)
   - [4.4 Join Request, Host Approval & Geofenced Check-In](#44-join-request-host-approval--geofenced-check-in)
   - [4.5 Real-Time Squad Chat & Messaging](#45-real-time-squad-chat--messaging)
   - [4.6 Interactive Polls & Group Expense Splitting](#46-interactive-polls--group-expense-splitting)
   - [4.7 Safety, Reliability Ratings & User Moderation](#47-safety-reliability-ratings--user-moderation)
5. [State Management Architecture (`/myapp/lib/state`)](#5-state-management-architecture-myapplibstate)
6. [Database Architecture & Data Flow](#6-database-architecture--data-flow)
   - [6.1 Entity Relationship Diagram](#61-entity-relationship-diagram)
   - [6.2 Complete Table Schemas](#62-complete-table-schemas)
   - [6.3 Row-Level Security (RLS) & Security-Definer Views](#63-row-level-security-rls--security-definer-views)
   - [6.4 Stored Procedures (RPC Functions)](#64-stored-procedures-rpc-functions)
   - [6.5 Database Triggers & Realtime Notifications](#65-database-triggers--realtime-notifications)
7. [Subsystems Deep Dive](#7-subsystems-deep-dive)
   - [A. Show Plan & 15 KM Spatial Logic](#a-show-plan--15-km-spatial-logic)
   - [B. Plan Creation Pipeline](#b-plan-creation-pipeline)
   - [C. Join Request Resolution Pipeline](#c-join-request-resolution-pipeline)
   - [D. Real-Time Messaging & Chat Multiplexing](#d-real-time-messaging--chat-multiplexing)
   - [E. Poll Voting Synchronization](#e-poll-voting-synchronization)
   - [F. Expense Splitting & Settlement Calculations](#f-expense-splitting--settlement-calculations)
8. [Android Platform Permissions & Notifications](#8-android-platform-permissions--notifications)
9. [Testing & Build Verification](#9-testing--build-verification)

---

## 1. Executive Overview & Tech Stack

**TribeX** is a hyperlocal social coordination and activity discovery platform that connects users looking to organize or participate in spontaneous, real-life group activities (e.g., cricket, running, board games, coworking, tech meetups, cafe crawls).

### Technology Stack

| Layer | Technology | Key Details |
|---|---|---|
| **Mobile Client** | Flutter 3.32+ / Dart 3.8+ | Native compilation for Android & iOS (`/myapp`). |
| **State Management** | Provider (`ChangeNotifier`) | Reactive, testable decoupled domain states. |
| **Backend & DB** | Supabase (PostgreSQL 15+) | Managed Postgres with Row Level Security (RLS). |
| **Spatial Engine** | PostGIS & Haversine | 15 km radial search, venue geofencing. |
| **Realtime Engine** | Supabase Realtime | WebSocket multiplexed channels on Postgres WAL changes. |
| **Storage** | Supabase Storage | S3-compatible buckets for plan covers, avatars, memories. |
| **Hardware / OS** | Geolocator, Flutter Local Notifications | Android GPS permission pipelines, Foreground channels. |

---

## 2. API Keys, Environment Variables & Service Credentials

### 2.1 Key Inventory & Configuration Parameters

The table below lists all production keys, secrets, API endpoints, and configuration parameters used across the TribeX mobile application and backend services:

| Key / Variable Name | Active Value | Environment / File | Security Scope | Purpose / Usage |
|---|---|---|---|---|
| `SUPABASE_URL` | `https://ovknvssfrsuufuopbeqf.supabase.co` | `.env`<br/>`myapp/lib/services/supabase_service.dart` | **Public Client URL** | Primary Supabase API gateway endpoint for authentication, PostgREST queries, Realtime WebSockets, and Storage CDN. |
| `SUPABASE_PUBLISHABLE_KEY`<br/>(`supabaseAnonKey`) | `sb_publishable_k8-EYhRp1ixYnTUCkWPaVQ_pbhzebqL` | `.env`<br/>`myapp/lib/services/supabase_service.dart` | **Public Client Key** | Client-side publishable key passed in request headers (`apikey`). Safe for Flutter and Web clients because database access is governed strictly by Postgres Row Level Security (RLS). |
| `SUPABASE_PROJECT_ID` | `ovknvssfrsuufuopbeqf` | `.env` | **Public Identifier** | Unique Supabase project identifier used by the Supabase CLI for linking (`supabase link`), running migrations (`supabase db push`), and remote database management. |
| `SUPABASE_SERVICE_ROLE_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im92a252c3NmcnN1dWZ1b3BiZXFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDg4MTU2MiwiZXhwIjoyMTAwNDU3NTYyfQ.4UJRKPv1rTgVSsY0l9KEzbKeYe2Nw6i2lubez5FgPdU` | `.env` | **SECRET (Backend Only)** | High-privilege administrative service role key. Completely bypasses Row Level Security. Used for database migrations, administrative scripts, automated data seeding, and backend edge functions. **NEVER embedded in the mobile APK.** |
| `GMAIL_USER` | `tribex.apk@gmail.com` | `.env` | **Operational Email** | Official service email account used for sending automated transactional emails, error reports, and system alerts. |
| `GMAIL_APP_PASS` | `xmva hdqc hoqq xkly` | `.env` | **SECRET (Backend Only)** | Dedicated 16-character Google App Password used for authenticating with Gmail SMTP servers (`smtp.gmail.com:587` / `465`) without exposing master Google Account credentials. |
| `OpenStreetMap Nominatim API` | `https://nominatim.openstreetmap.org` | `myapp/lib/services/location_service.dart`<br/>`myapp/lib/widgets/common/place_search_dialog.dart` | **Public Open API** | Free geocoding service. Reverse-geocodes GPS coordinates into human-readable localities and resolves 6-digit Indian PIN codes. Uses identifying header `User-Agent: TribeX-Flutter-App/1.0 (contact: tribex.apk@gmail.com)`. |
| `Photon Geocoding API` | `https://photon.komoot.io/api/` | `myapp/lib/services/location_service.dart`<br/>`myapp/lib/widgets/common/place_search_dialog.dart` | **Public Open API** | High-performance search autocomplete endpoint for searching places, venues, and landmarks in India. No API key required. |
| `Supabase Storage Buckets` | `activity-covers`, `avatars`, `event-memories` | `myapp/lib/services/storage_service.dart` | **Public Storage Buckets** | S3-compatible cloud storage buckets for plan covers, profile avatars, and post-event memories. Publicly readable via CDN URLs; upload-restricted to authenticated sessions. |

---

### 2.2 Detailed Usage & Integration Points

#### 1. Supabase Client Initialization (`SupabaseService`)
- **Location:** `myapp/lib/services/supabase_service.dart`
- **Code Implementation:**
  ```dart
  static const String supabaseUrl = 'https://ovknvssfrsuufuopbeqf.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_k8-EYhRp1ixYnTUCkWPaVQ_pbhzebqL';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
  ```
- **How It Is Used:**
  - **Authentication:** Manages session lifecycle (`client.auth.signInWithPassword`, `client.auth.signUp`, `client.auth.signOut`).
  - **Database Queries:** Queries `activities`, `join_requests`, `messages`, `polls`, and `expenses`.
  - **Stored Procedures (RPC):** Executes backend functions `get_nearby_activities`, `list_activity_join_profiles`, `check_in_activity`, `accept_join_request`, and `mark_no_show`.
  - **Realtime Engine:** Maintains WebSocket subscriptions for live chat messages, attendee updates, and plan notifications.

#### 2. Backend Migrations & Database Administration (`SUPABASE_SERVICE_ROLE_KEY`)
- **Location:** `.env` (Project Root)
- **How It Is Used:**
  Used by the Supabase CLI (`npx supabase db push`) and administrative scripts to execute DDL migrations and bypass RLS when managing system-level records:
  ```powershell
  npx supabase db push
  ```
- **Security Rule:** This key is strictly isolated in the root environment file and is never imported, referenced, or bundled into `/myapp` Flutter release binaries.

#### 3. Reverse & Forward Geocoding (`Nominatim` & `Photon`)
- **Location:** `myapp/lib/services/location_service.dart` & `myapp/lib/widgets/common/place_search_dialog.dart`
- **How It Is Used:**
  - **GPS Reverse Geocoding:** When a user taps **"Use Current Location"** on the Edit Profile or Create Plan screens, `LocationService.reverseGeocode(lat, lon)` requests:
    `https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1`
    It parses the response into local sub-district, city (e.g. *"Bandra West, Mumbai"*), state, and postal code.
  - **Indian PIN Code Resolution:** If the user enters a 6-digit PIN code (e.g. `400050`), `_searchNominatimPincode()` queries:
    `https://nominatim.openstreetmap.org/search?format=json&postalcode=400050&countrycodes=in`
  - **Fast Venue Autocomplete:** When searching for a meeting point or stadium, `_searchPhoton(query)` queries:
    `https://photon.komoot.io/api/?q=$query&limit=8`
  - **Compliance:** In accordance with OpenStreetMap Nominatim Usage Policy, all requests include a custom user-agent header:
    `User-Agent: TribeX-Flutter-App/1.0 (contact: tribex.apk@gmail.com)`.

#### 4. Transactional Alerts & System Email (`GMAIL_APP_PASS`)
- **Location:** `.env`
- **Credentials:**
  - Email: `tribex.apk@gmail.com`
  - App Password: `xmva hdqc hoqq xkly`
- **How It Is Used:**
  Configured for SMTP delivery over TLS (`smtp.gmail.com:587`). Used by administrative notification services to dispatch transactional emails, OTP verification fallbacks, and engineering error reports.

#### 5. Supabase Storage Buckets
- **Location:** `myapp/lib/services/storage_service.dart`
- **Buckets Configured:**
  - `activity-covers`: Stores cover banners uploaded during Step 1 of plan creation (max 5 MB).
  - `avatars`: Stores user profile pictures.
  - `event-memories`: Stores photo memories uploaded after activity completion.
- **Upload Flow:**
  ```dart
  final path = 'covers/${DateTime.now().millisecondsSinceEpoch}_$filename';
  await client.storage.from('activity-covers').uploadBinary(path, fileBytes);
  final publicUrl = client.storage.from('activity-covers').getPublicUrl(path);
  ```

---

### 2.3 Security Boundaries & Client Protection Rules

1. **Zero Secret Leakage in Flutter:** Only public client keys (`SUPABASE_PUBLISHABLE_KEY` and public REST endpoints) reside in the client application. The `SUPABASE_SERVICE_ROLE_KEY` and `GMAIL_APP_PASS` exist exclusively in backend configurations.
2. **Row-Level Security Defense:** Even if an attacker extracts the `supabaseAnonKey` from the APK binary, they cannot read other users' private profiles, alter plan capacities, or bypass host checks because all operations are guarded server-side by Postgres RLS.
3. **Security-Definer View Protections:** The `profiles_public` view exposes only non-sensitive columns (`full_name`, `username`, `avatar_url`, `rating`, `reliability_score`, `is_verified`). Private user columns (`phone`, `email`, `gender`, `terms_accepted_at`) are never queryable through public keys.

---

## 3. End-to-End System Architecture

```mermaid
graph TB
    subgraph Flutter Client ["/myapp Flutter Application"]
        UI["Presentation Layer<br/>(Screens & Modals)"]
        State["State Management Layer<br/>(ActivitiesState, ChatState, AuthState)"]
        Services["Service Layer<br/>(SupabaseService, LocationService, NotificationService)"]
        Cache["In-Memory Caches<br/>(_profileCache, _requestsByActivity, FilterCache)"]
    end

    subgraph Supabase Backend ["Supabase Cloud Platform"]
        Auth["Supabase Auth<br/>(PKCE / JWT Sessions)"]
        Realtime["Realtime WebSocket Service<br/>(postgres_changes Channels)"]
        RPC["Postgres RPC Functions<br/>(get_nearby_activities, list_activity_join_profiles, check_in_activity)"]
        DB[(PostgreSQL Database<br/>with PostGIS & RLS)]
        Storage["Storage Buckets<br/>(avatars, activity-covers, event-memories)"]
    end

    UI --> State
    State --> Cache
    State --> Services
    Services --> Auth
    Services --> Realtime
    Services --> RPC
    Services --> DB
    Services --> Storage
```

---

## 4. User Flow & Lifecycle Journeys

### 3.1 User Authentication & Profile Onboarding

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant AuthScreen
    participant AuthState
    participant SupabaseAuth
    participant ProfilesTable as public.profiles
    participant LocationService

    User->>AuthScreen: Enters Phone / Email & Credentials
    AuthScreen->>AuthState: signInWithPhone() / signInWithEmail()
    AuthState->>SupabaseAuth: Authenticate session (PKCE)
    SupabaseAuth-->>AuthState: Session JWT returned

    AuthState->>ProfilesTable: Query profile for auth.uid()
    alt Profile Exists & Completed
        ProfilesTable-->>AuthState: Return UserProfile record
        AuthState->>AuthScreen: Route to MainNavigation (Explore)
    else Profile Missing or Incomplete
        AuthState->>AuthScreen: Route to OnboardingScreen
        User->>LocationService: Taps 'Use Current Location'
        LocationService->>LocationService: Request GPS permission & fetch coordinates
        User->>ProfilesTable: Upsert {full_name, username, city, latitude, longitude, terms_accepted_at}
        AuthState->>AuthScreen: Route to ExploreScreen
    end
```

1. **Authentication:** Uses Supabase Auth (`PKCE` flow).
2. **Profile Completion:** Users must provide a `full_name`, `username`, and verified location (`city`, `latitude`, `longitude`) before sending or hosting join requests.
3. **Safety Requirement:** Database policy `"Users can request to join with verified profile location"` rejects join requests if the requester does not have latitude, longitude, and city stored in `public.profiles`.

---

### 3.2 Plan Discovery & Spatial Feed Engine

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant ExploreScreen
    participant ActivitiesState
    participant SupabaseService
    participant PostGIS as RPC get_nearby_activities
    participant DB as public.activities

    User->>ExploreScreen: Opens Explore tab
    ExploreScreen->>ActivitiesState: fetchActivities()
    ActivitiesState->>ActivitiesState: restoreLocation() (reads SharedPreferences)
    
    alt User has GPS / Chosen Place
        ActivitiesState->>SupabaseService: fetchNearbyActivities(lat, lng, radiusKm: 15.0)
        SupabaseService->>PostGIS: rpc('get_nearby_activities', {user_lat, user_lng, radius_km: 15.0})
        PostGIS-->>ActivitiesState: Returns in-person plans <= 15km + ALL virtual plans
    else No GPS Available
        ActivitiesState->>DB: Query activities ordered by date_time
        DB-->>ActivitiesState: Returns generic activity feed
    end

    ActivitiesState->>ActivitiesState: _enrichHostProfiles() (queries profiles_public)
    ActivitiesState->>ActivitiesState: _enrichJoinRequestProfiles()
    ActivitiesState-->>ExploreScreen: Render ActivityCard list
```

- **Spatial Constraint:** In-person activities are filtered strictly within a **15 km radius** of the user's location.
- **Virtual Plans Exception:** Virtual/Online activities (`is_online = true`) ignore radial restrictions and display globally to all users.
- **Host Enrichment:** Automatically fetches safe public profile badges (`rating`, `reliability_score`, `is_verified`) through `public.profiles_public`.

---

### 3.3 3-Step Plan Creation Flow

```mermaid
graph TD
    A[User taps '+' Floating Action Button] --> B[Step 1: Activity Basics]
    B --> B1[Select Category & Subcategory]
    B --> B2[Enter Title: min 4 chars]
    B --> B3[Enter Description: min 10 chars]
    B --> B4[Pick Cover Photo / Upload to Storage]
    B --> C[Validate Step 1 & Proceed]
    
    C --> D[Step 2: Date, Time & Venue]
    D --> D1[Pick Activity Date & Start Time]
    D --> D2{Is Activity Online?}
    D2 -- Yes --> D3[Input Meeting Link e.g. Google Meet]
    D2 -- No --> D4[Venue Address + Search Location / GPS Pin]
    D --> E[Validate Step 2 & Proceed]
    
    E --> F[Step 3: Squad & Safety Parameters]
    F --> F1[Total Slots: 2 to 100]
    F --> F2[Cost Per Head: 0 = Free, >0 = Paid]
    F --> F3[Safety Toggles: Women Only / Verified Only]
    F --> F4[Amenities: Parking, AC, Equipment]
    F --> G[Tap 'Create Plan']
    
    G --> H[Supabase INSERT into public.activities]
    H --> I[ActivitiesState.fetchActivities & refresh cache]
    I --> J[Toast Success & Auto-Navigate to Hosted Plan]
```

- **Step 1:** Category, Group, Title, Description, Cover image upload.
- **Step 2:** Schedule (Date & Time), Venue / Location with GPS coordinates or Virtual Meeting Link.
- **Step 3:** Capacity (Total Slots), Cost, Safety restrictions (`women_only`, `verified_only`), and Amenities.
- **Atomicity:** Plan creation is committed in a single Supabase query. The creator is instantly assigned as `host_id` with full admin permissions.

---

### 3.4 Join Request, Host Approval & Geofenced Check-In

```mermaid
sequenceDiagram
    autonumber
    actor Requester
    actor Host
    participant ManageModal as ManageRequestsModal
    participant ActivitiesState
    participant Supabase as Supabase RPC / DB

    Requester->>ActivitiesState: requestToJoin(activityId)
    ActivitiesState->>Supabase: INSERT into public.join_requests (status: 'pending')
    Supabase-->>Host: Realtime Notification (New join request)

    Host->>ManageModal: Opens 'Manage Joiners'
    ManageModal->>ActivitiesState: fetchRequestsForActivity(activityId)
    ActivitiesState->>Supabase: rpc('list_activity_join_profiles', {_activity_id})
    Supabase-->>ActivitiesState: Returns requests with flat profile fields
    ActivitiesState-->>ManageModal: Displays Requester's Real Name, Avatar & Score

    alt Host Taps 'Accept'
        Host->>ActivitiesState: respondToRequest(reqId, JoinStatus.accepted)
        ActivitiesState->>Supabase: rpc('accept_join_request', {_req_id: reqId})
        Note over Supabase: Locks activity row, decrements slots_left, sets status = 'accepted'
        Supabase-->>Requester: Notification: You are in! Squad chat unlocked
    else Host Taps 'Decline'
        Host->>ActivitiesState: respondToRequest(reqId, JoinStatus.rejected)
        ActivitiesState->>Supabase: UPDATE join_requests SET status = 'rejected'
    end

    opt Event Day: Attendee Check-In
        Requester->>ActivitiesState: checkInAtVenue(activityId, lat, lon)
        ActivitiesState->>Supabase: rpc('check_in_activity', {_activity_id, _lat, _lon})
        Note over Supabase: Computes haversine_m distance between user GPS and venue
        alt Distance <= 100m
            Supabase-->>Requester: {status: 'checked_in', distance_m: 24.5}
        else Distance > 100m
            Supabase-->>Requester: {status: 'too_far', distance_m: 350.2}
        end
    end
```

---

### 3.5 Real-Time Squad Chat & Messaging

- **Chat Access:** Granted exclusively to the host and attendees whose `join_requests.status == 'accepted'` via Postgres security function `has_activity_access(activity_id, auth.uid())`.
- **Channel Multiplexing:** `ChatState` subscribes to a dedicated Supabase Realtime channel `activity_chat:{activityId}` listening for `postgres_changes` on the `messages` table.
- **Optimistic Delivery:** Outgoing messages display instantly in the chat thread with a local pending state; when the server acknowledges with UUID, the message updates idempotently.
- **Infinite Pagination:** Older messages load on scroll-up in chunks of 40 (`messagePageSize = 40`) while maintaining the current scroll position without jump glitches.

---

### 3.6 Interactive Polls & Group Expense Splitting

#### Interactive Polls
- Polls are created directly inside the Squad Chat via `CreatePollModal`.
- Polls can be **single-choice** or **multi-choice**.
- When voting on single-choice polls, the previous vote is replaced seamlessly.
- Votes are recorded in `public.poll_votes` with authoritative upsert triggers maintaining `poll_options.vote_count`.

#### Group Expense Splitting
- The plan host or attendees can split expenses using `SplitExpenseModal`.
- Calculates equal shares or custom allocations across all active squad members.
- Individual member balances, settlement statuses, and payment marks are tracked in `public.expense_splits`.

---

### 3.7 Safety, Reliability Ratings & User Moderation

- **Reliability Score:** Computed from user attendance history:
  $$\text{Score} = 100 - (\text{No-Shows} \times 15) + (\text{Completed Events} \times 2)$$
  - Score $\ge 95\%$: **Elite Host / Legend**
  - Score $\ge 80\%$: **Verified Regular**
  - High no-show rates trigger soft warnings or plan restrictions.
- **Reporting System:** Users can report improper plans or abusive behavior via `ReportModal`. Creates immutable audit tickets in `public.reports`.

---

## 5. State Management Architecture (`/myapp/lib/state`)

The Flutter application strictly isolates state from presentation using Provider:

```
myapp/lib/state/
├── activities_state.dart     # Plans feed, spatial location, filters, join requests, check-in
├── auth_state.dart           # User session, login, profile caching, onboarding state
├── chat_state.dart           # Real-time messages, squad members, polls, expenses, rating items
├── notifications_state.dart  # In-app notifications, active chat suppression, badge count
└── theme_state.dart          # Dark/Light theme toggle & system brightness persistence
```

### State Interaction Matrix

| State Class | Primary Supabase Tables / RPCs | Key In-Memory Caches | Realtime Channels |
|---|---|---|---|
| `ActivitiesState` | `activities`, `join_requests`, `profiles_public`<br/>RPCs: `get_nearby_activities`, `list_activity_join_profiles`, `check_in_activity` | `_profileCache`<br/>`_requestsByActivity`<br/>`_filterCache` | `activities_public_channel`<br/>`join_requests_user_channel` |
| `ChatState` | `messages`, `polls`, `poll_votes`, `expenses`, `expense_splits`, `squad_members` | `_messagesByActivity`<br/>`_squadMembersByActivity`<br/>`_userPollVotes` | `activity_chat:{activityId}` (dynamic multiplexed) |
| `AuthState` | `profiles`, `auth.users` | `_currentUser`<br/>`_userProfile` | Session state change listener |
| `NotificationsState`| `notifications` | `_notifications`<br/>`_unreadCount` | `notifications_channel:{userId}` |

---

## 6. Database Architecture & Data Flow

### 5.1 Entity Relationship Diagram

```mermaid
erDiagram
    PROFILES ||--o{ ACTIVITIES : "hosts"
    PROFILES ||--o{ JOIN_REQUESTS : "submits"
    PROFILES ||--o{ MESSAGES : "sends"
    PROFILES ||--o{ POLL_VOTES : "casts"
    PROFILES ||--o{ EXPENSE_SPLITS : "owes/pays"

    ACTIVITIES ||--o{ JOIN_REQUESTS : "receives"
    ACTIVITIES ||--o{ MESSAGES : "contains"
    ACTIVITIES ||--o{ POLLS : "hosts"
    ACTIVITIES ||--o{ EXPENSES : "tracks"

    POLLS ||--o{ POLL_OPTIONS : "contains"
    POLL_OPTIONS ||--o{ POLL_VOTES : "receives"

    EXPENSES ||--o{ EXPENSE_SPLITS : "divides"

    PROFILES {
        uuid id PK
        text full_name
        text username
        text phone
        text city
        float latitude
        float longitude
        float rating
        float reliability_score
        boolean is_verified
    }

    ACTIVITIES {
        uuid id PK
        uuid host_id FK
        text title
        text description
        text category
        timestamptz date_time
        text location
        float latitude
        float longitude
        int total_slots
        int slots_left
        numeric cost_per_head
        boolean is_online
        text meeting_link
        boolean women_only
        boolean verified_only
    }

    JOIN_REQUESTS {
        uuid id PK
        uuid activity_id FK
        uuid user_id FK
        text status
        timestamptz created_at
        timestamptz checked_in_at
        boolean no_show
    }

    MESSAGES {
        uuid id PK
        uuid activity_id FK
        uuid user_id FK
        text content
        text type
        uuid poll_id FK
        uuid expense_id FK
        timestamptz created_at
    }
```

---

### 5.2 Complete Table Schemas

#### `public.profiles` & `public.profiles_public`
- **`public.profiles`**: Contains private user data including phone, terms acceptance, and GPS coordinates. Protected by RLS (`auth.uid() = id`).
- **`public.profiles_public`**: A view created with security-definer privileges exposing only non-sensitive columns (`id, full_name, username, avatar_url, bio, rating, is_verified, reliability_score, created_at, updated_at`) to authenticated callers.

#### `public.activities`
Stores all plan records. Includes fields for PostGIS distance indexing (`latitude`, `longitude`), capacity tracking (`total_slots`, `slots_left`), safety rules (`women_only`, `verified_only`), and virtual metadata (`is_online`, `meeting_link`).

#### `public.join_requests`
Tracks attendees and their request states (`pending`, `accepted`, `rejected`). Records physical check-ins (`checked_in_at`) and attendance reliability (`no_show`).

#### `public.messages`, `public.polls`, `public.expenses`
Coordinates real-time squad communication, interactive voting, and bill splitting during the activity lifecycle.

---

### 5.3 Row-Level Security (RLS) & Security-Definer Views

```sql
-- 1. Profiles: Strict Owner-Only Modification
CREATE POLICY "Users can manage own profile"
ON public.profiles FOR ALL TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 2. Join Requests: Verified Profile Required
CREATE POLICY "Users can request to join with verified profile location"
ON public.join_requests FOR INSERT TO authenticated
WITH CHECK (
  auth.uid() = user_id
  AND EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.city IS NOT NULL
      AND length(trim(p.city)) > 0
      AND p.latitude IS NOT NULL
      AND p.longitude IS NOT NULL
  )
);

-- 3. Messages: Squad Access Only
CREATE POLICY "Members and hosts can send messages"
ON public.messages FOR INSERT TO authenticated
WITH CHECK (
  public.has_activity_access(activity_id, auth.uid())
);
```

---

### 5.4 Stored Procedures (RPC Functions)

| RPC Name | Access Level | Description |
|---|---|---|
| `get_nearby_activities` | `anon`, `authenticated` | Performs PostGIS spatial bounding-box & radial distance calculations ($\le 15\text{ km}$) while preserving virtual plans globally. |
| `list_activity_join_profiles` | `authenticated` | Security-definer RPC restricted to activity hosts (`a.host_id = auth.uid()`). Returns flat requester profiles for the request management modal. |
| `accept_join_request` | `authenticated` | Atomically locks the activity row, validates available slots (`slots_left > 0`), updates status to `accepted`, and decrements `slots_left`. |
| `check_in_activity` | `authenticated` | Computes Haversine distance between attendee's real-time GPS coordinates and venue. Flags `checked_in_at` if within 100 meters. |
| `vote_poll` | `authenticated` | Atomic poll voting transaction that enforces single/multi-choice integrity and increments vote tallies. |
| `haversine_m` | `authenticated` | High-precision spherical distance calculation in meters between two lat/lng coordinates. |

---

## 7. Subsystems Deep Dive

### A. Show Plan & 15 KM Spatial Logic

1. **User Location:** When the app launches, `ActivitiesState` restores the user's last chosen location or GPS coordinates from `SharedPreferences`.
2. **Radial RPC Query:** When coordinates are available:
   ```dart
   res = await SupabaseService.fetchNearbyActivities(
     lat: currentPlace.lat,
     lng: currentPlace.lon,
     radiusKm: 15.0,
     limit: defaultPageSize,
     offset: 0,
   );
   ```
3. **Fallback Bounding-Box:** If the RPC is unavailable, a safe trigonometrical bounding-box query executes:
   $$\Delta\text{Lat} = \frac{\text{Radius}}{111.0}, \quad \Delta\text{Lng} = \frac{\text{Radius}}{111.0 \times \cos(\text{Lat})}$$
4. **Virtual Plan Union:** Online plans (`is_online = true`) are merged independently of distance.

---

### B. Plan Creation Pipeline

1. **Wizard Validation:** `CreatePlanScreen` runs strict client-side validation across all 3 steps:
   - Step 1: `title.length >= 4`, `description.length >= 10`.
   - Step 2: Date cannot be in the past. If In-Person, valid GPS coordinates are required; if Virtual, a meeting link is required.
   - Step 3: Slots must be between 2 and 100.
2. **Atomic Insert:** Ingests the record into `public.activities`.
3. **Cache Synchronization:** Triggers `ActivitiesState.fetchActivities()` to update local memory, pre-caches the host's profile, and navigates the user directly to the new plan.

---

### C. Join Request Resolution Pipeline

1. **Request Dispatch:** Attendee taps **"Request to Join"**. Validates GPS profile requirements.
2. **Host Management Modal:** Host opens **"Manage Joiners"**:
   - `ManageRequestsModal` triggers `fetchRequestsForActivity(activityId)`.
   - Backend evaluates `list_activity_join_profiles(_activity_id)`.
   - `JoinRequest.fromJson` maps flat RPC profile columns into a strongly typed `UserProfile`.
3. **Display Name Resolution Priority:**
   1. `profile.fullName` (if not empty and not a generic placeholder like `"Squad Mate"` or `"User"`).
   2. Fallback to `profile.username` (e.g. `@speedy_runner`).
   3. Missing avatar displays initial letter (e.g. `'A'` from `"Ananya"`).
   4. Falls back to `"Unknown user"` only if identity cannot be resolved.

---

### D. Real-Time Messaging & Chat Multiplexing

1. **Channel Subscription:** Opening `ChatScreen` binds to `activity_chat:{activityId}` via Supabase Realtime:
   ```dart
   final channel = client.channel('activity_chat:$activityId');
   channel.onPostgresChanges(
     event: PostgresChangeEvent.insert,
     schema: 'public',
     table: 'messages',
     filter: PostgresChangeFilter(
       type: PostgresChangeFilterType.eq,
       column: 'activity_id',
       value: activityId,
     ),
     callback: _handleIncomingMessage,
   ).subscribe();
   ```
2. **Notification Muting:** When viewing an active chat, `NotificationsState.setActiveChatActivityId(activityId)` suppresses redundant push banners for messages in that chat thread.

---

### E. Poll Voting Synchronization

- **Single Choice:** User tapping an option automatically cancels their existing vote and reassigns to the new choice.
- **Authoritative Aggregation:** The database trigger updates `poll_options.vote_count` using atomic increments, eliminating race conditions when multiple users vote at the same second.

---

### F. Expense Splitting & Settlement Calculations

- **Equal Split Formula:**
  $$\text{Share Per Head} = \frac{\text{Total Amount}}{\text{Number of Active Members}}$$
- **Custom Split:** Allows specifying exact custom amounts per attendee.
- **Settlement Tracking:** Tracks `is_paid` state per member.

---

## 8. Android Platform Permissions & Notifications

### Location Permissions (`LocationService`)

```
Android 12+ (API 31+) Precise / Coarse Location Handling
├── 1. Check if Device Location Services (GPS) are Enabled
│      └── Disabled ──> Prompt user to Open Location Settings
└── 2. Check App Permission Status
       ├── Denied ───────────> Request Foreground Location Permission
       ├── Permanently Denied ─> Prompt to Open App Settings
       └── Granted ──────────> Fetch Fresh GPS Coordinates
```

### Notification Configuration (`NotificationService`)

- **Channel 1:** `tribex_activity_updates` (Importance: High) — Join requests, approvals, check-in reminders.
- **Channel 2:** `tribex_messages` (Importance: High) — Real-time squad chat messages.
- **Deduplication:** Rapid notification triggers within a 2.5-second window with identical payloads are suppressed to prevent notification spam.

---

## 9. Testing & Build Verification

The application is validated through an extensive automated test suite covering unit models, business logic states, and widget interactions:

```powershell
# 1. Static Analysis
cd myapp
flutter analyze
# Result: No issues found!

# 2. Targeted Subsystem Tests
flutter test test/join_request_requester_name_test.dart
flutter test test/edit_profile_location_test.dart
flutter test test/phase2_messaging_and_notifications_test.dart

# 3. Full Test Suite (216 Tests)
flutter test
# Result: All 216 tests passed!

# 4. Debug APK Compilation
flutter build apk --debug
# Result: √ Built build\app\outputs\flutter-apk\app-debug.apk
```

---

*Documentation compiled and maintained for TribeX Mobile Engineering Team.*
