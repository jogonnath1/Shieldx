# ShieldX — Full Project Documentation
## Part 2: Project Structure & Architecture

---

## 2.1 High-Level Architecture

ShieldX follows a strict **4-layer architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│              Presentation Layer              │
│  (Screens + Widgets — no business logic)    │
└───────────────────┬─────────────────────────┘
                    │ watches / reads
┌───────────────────▼─────────────────────────┐
│               Provider Layer                 │
│  (Riverpod StateNotifiers — app state)      │
└───────────────────┬─────────────────────────┘
                    │ calls
┌───────────────────▼─────────────────────────┐
│                 Data Layer                   │
│  (Services — Supabase API calls only)       │
└───────────────────┬─────────────────────────┘
                    │ communicates with
┌───────────────────▼─────────────────────────┐
│              Supabase Backend                │
│  (PostgreSQL + RLS + Realtime + Storage)    │
└─────────────────────────────────────────────┘
```

**Key rule**: Screens only call providers. Providers call services. Services call Supabase. This keeps every layer testable in isolation.

---

## 2.2 Directory Map

```text
f:/Shieldx/
├── lib/
│   ├── main.dart                   ← App entry point (Supabase init, Riverpod scope)
│   ├── app.dart                    ← MaterialApp.router setup, theme injection
│   │
│   ├── admin/                      ← Admin module
│   │   ├── presentation/           ← Admin-only screens
│   │   │   ├── admin_complaints_screen.dart
│   │   │   ├── admin_complaint_detail_screen.dart
│   │   │   ├── admin_dashboard_screen.dart
│   │   │   ├── admin_officers_screen.dart
│   │   │   ├── admin_profile_screen.dart
│   │   │   ├── admin_shell.dart
│   │   │   ├── admin_sos_alert_widget.dart
│   │   │   ├── admin_stations_screen.dart
│   │   │   └── admin_users_screen.dart
│   │   └── providers/              ← Admin-specific state
│   │       └── admin_sos_provider.dart
│   │
│   ├── common/                     ← Shared core, data, UI, and state
│   │   ├── core/                   ← Cross-cutting concerns
│   │   │   ├── constants/          ← app_constants.dart, app_colors.dart
│   │   │   ├── router/             ← app_router.dart
│   │   │   ├── services/           ← preferences_service.dart
│   │   │   ├── theme/              ← app_theme.dart
│   │   │   └── utils/              ← validators, dialogs, classifiers
│   │   ├── data/                   ← Data access layer
│   │   │   ├── models/             ← Data classes
│   │   │   │   ├── complaint_model.dart
│   │   │   │   ├── emergency_model.dart
│   │   │   │   ├── message_model.dart
│   │   │   │   ├── notification_model.dart
│   │   │   │   ├── officer_model.dart
│   │   │   │   ├── police_station_model.dart
│   │   │   │   ├── profile_model.dart
│   │   │   │   └── status_history_model.dart
│   │   │   └── services/           ← All Supabase communication
│   │   │       ├── auth_service.dart
│   │   │       ├── complaint_service.dart
│   │   │       ├── emergency_service.dart
│   │   │       ├── map_service.dart
│   │   │       ├── message_service.dart
│   │   │       ├── notification_service.dart
│   │   │       ├── officer_service.dart
│   │   │       ├── profile_service.dart
│   │   │       ├── storage_service.dart
│   │   │       └── sync_service.dart
│   │   ├── presentation/           ← Shared UI
│   │   │   ├── auth/               ← splash, login, register, blocked
│   │   │   ├── common/             ← notifications_screen.dart
│   │   │   └── widgets/            ← admin, user, and common components
│   │   └── providers/              ← Global/Shared Riverpod state
│   │       ├── auth_provider.dart
│   │       ├── chat_provider.dart
│   │       ├── complaint_provider.dart
│   │       ├── connectivity_provider.dart
│   │       ├── gps_simulation_provider.dart
│   │       ├── location_cache_provider.dart
│   │       ├── navigation_trigger_provider.dart
│   │       ├── notification_provider.dart
│   │       ├── officer_provider.dart
│   │       ├── selected_station_provider.dart
│   │       ├── station_map_provider.dart
│   │       └── time_provider.dart
│   │
│   └── user/                       ← Citizen module
│       ├── presentation/           ← Citizen-only screens
│       │   ├── change_email_screen.dart
│       │   ├── change_password_screen.dart
│       │   ├── chat_screen.dart
│       │   ├── complaint_detail_screen.dart
│       │   ├── edit_complaint_screen.dart
│       │   ├── edit_profile_screen.dart
│       │   ├── home_screen.dart
│       │   ├── my_complaints_screen.dart
│       │   ├── police_stations_screen.dart
│       │   ├── profile_screen.dart
│       │   └── submit_complaint_screen.dart
│       └── providers/              ← Citizen-specific state
│           └── sos_provider.dart
│
├── assets/
│   ├── images/
│   ├── animations/
│   └── icons/
├── android/
├── ios/
├── web/
├── pubspec.yaml
├── README.md
└── ARCHITECTURE.md
```

---

## 2.3 Data Flow Example — Submit Complaint

This illustrates how data flows from a user action down to the database and back up:

```
1. User fills 3-step complaint form (SubmitComplaintScreen)
        │
        ▼
2. Widget calls: ref.read(complaintProvider.notifier).submitComplaint(data)
        │
        ▼
3. ComplaintNotifier calls: ComplaintService.submitComplaint(data)
        │
        ▼
4. ComplaintService does: supabase.from('complaints').insert(data).select()
        │
        ▼
5. Supabase inserts the row → fires Postgres Realtime change event
        │
        ▼
6. watchAllComplaints() stream emits updated complaint list
        │
        ▼
7. allComplaintsStreamProvider rebuilds with new data
        │
        ▼
8. AdminComplaintsScreen rebuilds automatically (no manual refresh)
```

---

## 2.4 Navigation Architecture (GoRouter)

All routes are defined in `app_router.dart` with a `redirect()` function that runs on every navigation event.

### Redirect Logic Flow

```
Every navigation event triggers redirect():
│
├── If authState.isLoading → stay on /splash (or stay on current auth route)
│
├── If user is logged in AND profile.isBlocked → force /blocked
│
├── If on /blocked AND user is not blocked → redirect to role-appropriate home
│
├── If not logged in → redirect to /login (unless already on auth route)
│
├── If profile is incomplete (missing phone/NID) → redirect to /register
│
└── If on an auth route while logged in → restore last route or go to role home
        ├── Admin → /admin/dashboard
        └── User  → /home
```

### Route Table

| Route                        | Screen                      | Auth Required | Role    |
|------------------------------|-----------------------------|---------------|---------|
| `/splash`                    | SplashScreen                | No            | Any     |
| `/login`                     | LoginScreen                 | No            | Any     |
| `/register`                  | RegisterScreen              | No            | Any     |
| `/forgot-password`           | ForgotPasswordScreen        | No            | Any     |
| `/blocked`                   | BlockedScreen               | Yes           | Any     |
| `/home`                      | HomeScreen                  | Yes           | User    |
| `/submit-complaint`          | SubmitComplaintScreen       | Yes           | User    |
| `/my-complaints`             | MyComplaintsScreen          | Yes           | User    |
| `/complaint/:id`             | ComplaintDetailScreen       | Yes           | User    |
| `/complaint/:id/edit`        | EditComplaintScreen         | Yes           | User    |
| `/police-stations`           | PoliceStationsScreen        | Yes           | User    |
| `/profile`                   | ProfileScreen               | Yes           | User    |
| `/edit-profile`              | EditProfileScreen           | Yes           | User    |
| `/change-password`           | ChangePasswordScreen        | Yes           | User    |
| `/change-email`              | ChangeEmailScreen           | Yes           | User    |
| `/notifications`             | NotificationsScreen         | Yes           | Any     |
| `/chat/:complaintId`         | ChatScreen                  | Yes           | User    |
| `/admin/dashboard`           | AdminDashboardScreen        | Yes           | Admin   |
| `/admin/complaints`          | AdminComplaintsScreen       | Yes           | Admin   |
| `/admin/complaints/:id`      | AdminComplaintDetailScreen  | Yes           | Admin   |
| `/admin/users`               | AdminUsersScreen            | Yes           | Admin   |
| `/admin/officers`            | AdminOfficersScreen         | Yes           | Admin   |
| `/admin/stations`            | AdminStationsScreen         | Yes           | Admin   |
| `/admin/profile`             | AdminProfileScreen          | Yes           | Admin   |

### Admin Shell Route

All `/admin/*` routes (except `/admin/complaints/:id`) are wrapped in a `ShellRoute` backed by `AdminShell`. This provides the persistent bottom navigation bar across all admin tabs without rebuilding it on every navigation.

---

## 2.5 Key Design Decisions

### 1. DRY — Shared `_buildStatusStats()` Helper
`getStats()`, `getStatsForStation()`, and `getAllStationsStats()` in `ComplaintService` share a single private `_buildStatusStats()` helper. Adding a new complaint status requires a one-line change in exactly one place.

### 2. GPS Fallback Chain
Both SOS and Station Map use a 4-step fallback:
```
1. GPS Simulation mode (if demo active)
2. Real device GPS (with 6–8 second timeout)
3. Last known position (fallback)
4. Default: Sylhet city centre (24.89996, 91.87030)
```

### 3. Real-time Profile Updates
When an admin blocks or verifies a citizen, `_setupProfileSubscription()` in `AuthNotifier` picks up the Supabase Realtime Postgres change event instantly — no polling required. The blocked citizen is immediately redirected to `/blocked`.

### 4. Offline Complaint Queue
`SyncService` stores pending complaints as JSON in `SharedPreferences` under the key `offline_complaint_outbox`. When `ConnectivityProvider` detects restored connectivity, the outbox is drained by calling `ComplaintService.submitComplaint()` for each item.

### 5. Route Persistence
`PreferencesService.saveLastRoute()` saves every non-auth route to `SharedPreferences`. On app restart, `AuthNotifier._init()` auto-logs in (if saved credentials exist), then `app_router.dart` restores the last route — so users land exactly where they left off.

---

*Next: [Part 3 — Core Module](PART_3_Core.md)*
