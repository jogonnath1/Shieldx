# ShieldX — Full Project Documentation
## Part 1: Project Overview

---

## 1.1 Introduction

**ShieldX** is a mobile application built for the **Sylhet Metropolitan Police (SMP)** that allows citizens to report crimes and enables police administrators to manage, track, and respond to those reports in real time.

The app has two distinct user roles:
- **Citizen (User)** — can register, submit crime reports, track complaint status, trigger SOS alerts, and find nearby police stations on a map.
- **Admin (Police Officer/Supervisor)** — can manage all complaints, users, officers, and stations from a dedicated admin dashboard.

---

## 1.2 Tech Stack

| Layer              | Technology                                          |
|--------------------|-----------------------------------------------------|
| UI Framework       | Flutter 3.x (Dart)                                  |
| State Management   | Riverpod (`StateNotifier`, `StreamProvider`)         |
| Navigation         | GoRouter (declarative, redirect-based)              |
| Backend / Auth     | Supabase (PostgreSQL + Row Level Security)          |
| Real-time          | Supabase Realtime (Postgres Change Events)          |
| Maps               | flutter_map + OpenStreetMap tiles                   |
| Charts             | fl_chart                                            |
| Local Storage      | SharedPreferences                                   |
| Animations         | flutter_animate                                     |
| Image Upload       | image_picker + Supabase Storage                    |
| Geolocation        | geolocator                                          |
| HTTP               | http (for OpenStreetMap / Overpass API)             |

---

## 1.3 Feature Summary

### Citizen (User) Side
| Feature                 | Description |
|-------------------------|-------------|
| Register & Login        | Multi-step registration with email + phone OTP verification and NID validation |
| Submit Complaint        | 3-step complaint form with auto crime classification, location picker, and evidence photo upload |
| Track Complaints        | Real-time status updates: `submitted → in progress → investigating → resolved` |
| SOS Emergency           | One-tap emergency alert with live GPS location tracking and 3-second cancellation window |
| Police Station Map      | Interactive map showing nearest Sylhet police stations based on GPS location |
| Notifications           | Real-time push notifications for every status change |
| Profile Management      | Edit profile, change email/password with OTP verification |
| Offline Support         | Complaints queued locally when offline and auto-synced on reconnect |

### Admin Side
| Feature                 | Description |
|-------------------------|-------------|
| Dashboard               | Live stats with pie chart, bar charts, monthly trends, and location heatmap |
| Complaint Management    | Filter, sort, bulk-delete, assign officers, update statuses |
| User Management         | Verify, block/unblock, promote to admin, delete citizens |
| Officer Management      | Add and manage field officers linked to specific stations |
| SOS Alert Panel         | Real-time panel showing active emergency alerts with citizen GPS coordinates |
| Station Switcher        | View statistics filtered per police station (Kotwali, Moglabazar, etc.) |

---

## 1.4 Supported Crime Categories

The system supports 14 crime categories with automatic keyword-based classification:

1. Theft
2. Robbery
3. Assault
4. Fraud
5. Cybercrime
6. Drug Offense
7. Murder
8. Kidnapping
9. Sexual Harassment
10. Domestic Violence
11. Vandalism
12. Corruption
13. Traffic Violation
14. Other

---

## 1.5 Complaint Status Lifecycle

```
submitted  →  in_progress  →  under_investigation  →  resolved
                                                    ↘  closed
                                                    ↘  rejected
```

Each status transition is recorded in the `status_history` table with a timestamp, admin note, and the ID of who made the change.

---

## 1.6 Jurisdiction

The app is designed for **Sylhet Metropolitan Police** with 6 supported thanas:

| Thana Name            | Key Areas |
|-----------------------|-----------|
| Kotwali Model Thana   | Zindabazar, Dargah, Bandar Bazar, Mirabazar |
| Moglabazar Thana      | Daudpur, Jalalpur, Kuchai, Silam |
| South Surma Thana     | Kadamtali, Boroikandi, Mominkhola |
| Shahporan Thana       | Tilagor, Baluchar, Khadimnagar, Uposhohor |
| Jalalabad Thana       | Akhalia, SUST, Kumargaon, Housing Estate |
| Airport Thana         | Lakkatura, Osmani International, Dhopagul |

---

## 1.7 Database Tables

| Table                | Purpose |
|----------------------|---------|
| `profiles`           | Extended user info: name, phone, NID, role, verification status, block status |
| `complaints`         | Crime reports with status, GPS coordinates, evidence URLs, officer assignment |
| `status_history`     | Audit log of every complaint status change |
| `emergencies`        | Active SOS alerts with live GPS coordinates |
| `notifications`      | Per-user notification inbox |
| `phone_verifications`| OTP records for demo phone verification |
| `officers`           | Field officer records linked to stations |
| `messages`           | Per-complaint chat messages between admin and citizen |

---

## 1.8 Security Design

- **Row Level Security (RLS)**: Enabled on all Supabase tables — citizens can only read/write their own data.
- **Router-level guards**: `redirect()` in GoRouter sends blocked users to `/blocked` and directs admins vs. users to their respective dashboards.
- **Database-level enforcement**: Supabase RLS policies check the `role` field in `profiles` for all sensitive operations.
- **Supabase anon key**: Intentionally public. It grants no privileged access without a valid JWT from successful authentication.

---

*Next: [Part 2 — Project Structure & Architecture](PART_2_Architecture.md)*
