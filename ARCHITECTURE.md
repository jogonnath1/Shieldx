# ShieldX — Architecture Overview

## High-Level Architecture

ShieldX follows a **layered architecture** with clear separation between UI, state, and data:

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

---

## State Management (Riverpod)

All state lives in `lib/{module}/providers/`. Each provider has a single responsibility:

| Provider | State Type | Purpose |
|---|---|---|
| `authNotifierProvider` | `AsyncValue<ProfileModel?>` | Current user session and profile |
| `complaintProvider` | `AsyncValue<List<Complaint>>` | Stream of user's complaints |
| `allComplaintsStreamProvider` | `AsyncValue<List<Complaint>>` | Stream of all complaints (admin) |
| `sosNotifierProvider` | `SOSState` | SOS countdown, active alert, GPS tracking |
| `stationMapProvider` | `StationMapState` | Map selection, GPS location, station list |
| `notificationProvider` | `AsyncValue<List<Notification>>` | Real-time notification inbox |
| `connectivityProvider` | `bool` | Online/offline status |
| `gpsSimulationProvider` | `GpsSimulationState` | Demo GPS override for testing |

### Data Flow Example (Submit Complaint)

```
User fills form (SubmitComplaintScreen)
  → calls ComplaintService.submitComplaint()
  → Supabase inserts row into complaints table
  → Supabase Realtime fires Postgres change event
  → watchAllComplaints() stream emits updated list
  → allComplaintsStreamProvider rebuilds
  → AdminComplaintsScreen rebuilds automatically
```

---

## Navigation (GoRouter)

Defined in `lib/common/core/router/app_router.dart`. Uses a `redirect` function that runs on every navigation event:

```
redirect logic:
  if loading      → stay on /splash
  if blocked      → /blocked
  if not logged in → /login
  if admin        → /admin/dashboard (default)
  if user         → /home (default)
  if last route saved → restore it
```

Admin screens are wrapped in a `ShellRoute` (`AdminShell`) that provides the persistent bottom navigation bar shared across all admin tabs.

---

## Data Layer (Services)

All Supabase communication is isolated in `lib/{module}/data/services/`:

| Service | Responsibility |
|---|---|
| `AuthService` | Sign up, sign in, OTP flows, profile CRUD, Realtime subscription |
| `ComplaintService` | Complaint CRUD, status updates, statistics, thana filtering |
| `EmergencyService` | SOS trigger, live location updates, admin notifications |
| `NotificationService` | Fetch notifications, mark read/delete |
| `ProfileService` | Admin user management (verify, block, promote, delete) |
| `MapService` | OpenStreetMap / Overpass API calls for jurisdiction polygons |
| `StorageService` | Supabase Storage uploads (complaint evidence photos) |
| `SyncService` | Offline pending complaint sync on reconnect |

---

## Key Design Decisions

### 1. DRY — Shared `_buildStatusStats()` Helper
Three methods (`getStats`, `getStatsForStation`, `getAllStationsStats`) in `ComplaintService` previously duplicated the same 12-line stats-counting loop. This was extracted into a single private helper, reducing duplication and making future status additions a one-line change.

### 2. GPS Fallback Chain
The station map and SOS features use a 4-step GPS fallback:
```
1. GPS Simulation mode (if demo active)
2. Real device GPS (with 6s timeout)
3. Last known position (with 2s timeout)
4. Default: Sylhet city centre (24.89996, 91.87030)
```

### 3. Real-time Profile Updates
When an admin blocks or verifies a user, the change is picked up instantly by the citizen's app via a Supabase Realtime Postgres channel — no polling required. The `_setupProfileSubscription()` method in `AuthNotifier` handles this.

### 4. Offline Support
`SyncService` detects offline complaints (status `offline_pending`) and retries them when `ConnectivityProvider` detects the connection is restored.

### 5. Role-Based Access
- **Router level**: `redirect()` sends admins to `/admin/*` and users to `/home`
- **Database level**: Supabase Row Level Security policies enforce that users can only read/write their own rows

---

## Refactoring Summary (Pre-Defense Cleanup)

| Change | Files Affected |
|---|---|
| `dart format --line-length 120` applied | 86 files |
| `dart fix --apply` (unused imports, const fixes) | 19 files |
| `.withOpacity()` → `.withValues(alpha:)` deprecations fixed | 32 files |
| `print()` → `debugPrint()` | 3 files |
| Empty `catch {}` → `catch (e) { debugPrint(...) }` | 6 locations |
| Duplicate `_buildStatusStats` loop extracted to helper | `complaint_service.dart` |
| Unused methods removed (`_buildSectionHeader`, `_buildDetailRow`) | `admin_users_screen.dart` |
| Unused class removed (`_HotspotCluster`) | `police_stations_screen.dart` |
| Unused import removed | `police_stations_screen.dart` |
| Unused variable removed | `change_email_screen.dart` |
| Comments added to complex logic | `auth_provider`, `app_router`, `complaint_service`, `preferences_service` |

**Final result: 0 errors, 0 warnings from `dart analyze`**
