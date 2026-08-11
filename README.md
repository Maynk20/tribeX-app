# tribeX — Find your crew, join the plan

**tribeX** is a hyper-local activity discovery and social networking web application designed to help people find activities happening nearby and join squads in seconds. Whether it's box cricket, treks, jamming sessions, or pickup games, tribeX connects you to matching events in your area.

---

## 🚀 Key Features

*   **Explore Feed**: Discover local activities filtering by category groups, days (Today, Weekend), pricing, and safety parameters (Women-only plans, Verified Hosts).
*   **Onboarding & Interests**: Tailored interest selector (Cricket, Trek, Jams, Food, etc.) to match users with plans that fit their interests.
*   **Squad Group Chats**: Real-time group chats for each activity plan with integrated micro-features:
    *   **Expense Splitter**: Create and split activity costs directly within the chat.
    *   **Interactive Polls**: Create polls to align on timings or venue choices.
    *   **GPS Check-Ins**: Attendance tracking and GPS-verified checks.
*   **Account Settings & Privacy**: Edit profile details, change avatars, verify GPS location, toggle push notifications, and manage block lists.
*   **Premium Visual Experience**: Smooth page transition loaders (`PageLoader`) and custom structural skeletal fallbacks (`ListSkeleton`) to completely eliminate layout shifting.

---

## 🛠️ Technology Stack

*   **Framework**: [TanStack Start](https://tanstack.com/router/v1/docs/start/overview) (Server-Side Rendering + React Router)
*   **Language**: TypeScript
*   **Styling**: Tailwind CSS & Vanilla CSS custom design systems
*   **Database & Auth**: [Supabase](https://supabase.com) (PostgreSQL database, real-time channels, auth session management)
*   **State Management**: TanStack React Query (SWR fetching, cache invalidation, query client context)
*   **Icons**: Lucide React
*   **Build Tool**: Vite

---

## 💻 Getting Started

Follow these steps to run the project locally.

### Prerequisites

Make sure you have Node.js (v18+) and npm (or bun) installed.

### Installation

1. Install project dependencies:
   ```bash
   npm install
   ```

2. Configure environment variables. Set up your Supabase credentials in the `.env` file at the root:
   ```env
   VITE_SUPABASE_URL=your_supabase_project_url
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

### Running Locally

To start the local development server:
```bash
npm run dev
```
The server runs on [http://localhost:8080](http://localhost:8080).

### Building for Production

To build production SSR bundles and web assets:
```bash
npm run build
```
Production assets are generated in the `.output/` and `dist/` directories.

---

## 📁 Directory Structure

```
├── .output/                 # Compiled production assets
├── src/
│   ├── components/          # Reusable UI elements (cards, loaders, modals)
│   ├── hooks/               # Custom React hooks (useAuth, useLocation)
│   ├── integrations/        # External clients (Supabase, OneSignal)
│   ├── lib/                 # Service helpers, categories, error handlers
│   ├── routes/              # TanStack Start pages and layout routes
│   ├── entry-client.tsx     # Client mount entrypoint
│   ├── router.tsx           # Router instance definition
│   └── styles.css           # Global custom style design systems
├── supabase/                # Database migrations and configuration schemas
├── capacitor.config.ts      # Capacitor web asset setup
└── package.json             # Build configurations & packages
```
## Team

1. Mayank Thakkar
2. Himanshu Singh Rajput
3. Manish Yadav

### This Project Was Under Development.