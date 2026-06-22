# ShieldX — Crime Reporting Management System

A mobile application for citizens to report crimes and for police administrators to manage, track, and respond to those reports in real time.

Built with **Flutter**, powered by **Supabase**, and designed for the Sylhet Metropolitan Police (SMP) jurisdiction.

---

## Features

### Citizen (User) Side
- **Register & Login** — Multi-step registration with email/phone OTP verification and NID validation
- **Submit Complaint** — 3-step complaint form with auto crime classification, location picker, and evidence photo upload
- **Track Complaints** — Real-time status updates (`submitted → in progress → investigating → resolved`)
- **SOS Emergency** — One-tap emergency alert with live GPS location tracking and 3-second cancellation window
- **Police Station Map** — Interactive map showing nearest Sylhet police station based on GPS location
- **Notifications** — Real-time push notifications for every status change
- **Profile Management** — Edit profile, change email/password with OTP verification

### Admin Side
- **Dashboard** — Live statistics with pie chart, bar charts, monthly trends, and location heatmap
- **Complaint Management** — Filter, sort, bulk-delete, assign officers, update statuses
- **User Management** — Verify, block/unblock, promote to admin, delete citizens
- **Officer Management** — Add and manage field officers linked to specific stations
- **SOS Alert Panel** — Real-time panel showing active emergency alerts with citizen GPS coordinates
- **Station Switcher** — View statistics filtered per police station (Kotwali, Moglabazar, etc.)

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter (Dart) |
| State Management | Riverpod (`StateNotifier`, `StreamProvider`) |
| Navigation | GoRouter (declarative, redirect-based) |
| Backend / Auth | Supabase (PostgreSQL + Row Level Security) |
| Real-time | Supabase Realtime (Postgres Change Events) |
| Maps | flutter_map + OpenStreetMap tiles |
| Charts | fl_chart |
| Local Storage | SharedPreferences |
| Animations | flutter_animate |

---

## Project Structure

```
lib/
├── admin/            # Admin-specific modules
│   ├── data/         # Admin data models and services
│   ├── presentation/ # Admin screens (dashboard, complaints, users, etc.)
│   └── providers/    # Admin state management (Riverpod)
│
├── common/           # Shared modules and core configurations
│   ├── core/         # Constants, routing, theme, utils
│   ├── data/         # Shared data models and services (Auth)
│   ├── presentation/ # Shared screens (splash, notifications) and widgets
│   └── providers/    # Shared state management
│
└── user/             # Citizen/User-specific modules
    ├── data/         # User data models and services
    ├── presentation/ # Citizen screens (submit, map, profile, etc.)
    └── providers/    # User state management (Riverpod)
```

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0
- Dart SDK ≥ 3.0
- A Supabase project with the required tables and RPC functions

### Run the App
```bash
flutter pub get
flutter run
```

### Code Quality
```bash
dart format --line-length 120 lib/   # Format all files
dart analyze lib/                     # Static analysis (0 errors, 0 warnings)
```

---

## Database Tables

| Table | Purpose |
|---|---|
| `profiles` | Extended user info (name, phone, NID, role, verification status) |
| `complaints` | Crime reports with status, coordinates, evidence URLs |
| `status_history` | Audit log of every complaint status change |
| `emergencies` | Active SOS alerts with live GPS coordinates |
| `notifications` | Per-user notification inbox |
| `phone_verifications` | OTP records for demo phone verification |

---

## Security Notes

- **Row Level Security (RLS)** is enabled on all Supabase tables — citizens can only read/write their own data.
- The Supabase **anon key** in `app_constants.dart` is intentionally public; it grants no privileged access without a valid JWT.
- Admin routes are protected both at the router level (redirect) and at the database level (RLS policies check the `role` field).
