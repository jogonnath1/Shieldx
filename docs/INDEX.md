# ShieldX — Full Project Documentation Index

**Project**: ShieldX — Crime Reporting Portal Management System  
**Framework**: Flutter (Dart)  
**Backend**: Supabase (PostgreSQL + Realtime)  
**Jurisdiction**: Sylhet Metropolitan Police (SMP), Bangladesh  
**Version**: 1.0.0  

---

## Table of Contents

| Part | Title | Key Topics |
|------|-------|-----------|
| [Part 1](PART_1_Overview.md) | **Project Overview** | Features, tech stack, database tables, security design |
| [Part 2](PART_2_Architecture.md) | **Architecture** | Layered architecture, directory map, data flow, navigation, design decisions |
| [Part 3](PART_3_Core.md) | **Core Module** | Constants, colors, router, validators, complaint classifier, theme |
| [Part 4](PART_4_Models.md) | **Data Models** | ComplaintModel, ProfileModel, EmergencyModel, NotificationModel, and all others |
| [Part 5](PART_5_Services.md) | **Data Services** | AuthService, ComplaintService, EmergencyService, SyncService, and all others |
| [Part 6](PART_6_Providers.md) | **Providers (State)** | AuthNotifier, SOSNotifier, ComplaintNotifier, ConnectivityProvider, and all others |
| [Part 7](PART_7_Auth_Screens.md) | **Auth Screens** | Splash, Login, Register (3-step), ForgotPassword, Blocked |
| [Part 8](PART_8_User_Screens.md) | **User Screens** | Home, SubmitComplaint, MyComplaints, PoliceStations, Profile, Chat |
| [Part 9](PART_9_Admin_Screens.md) | **Admin Screens** | Dashboard, Complaints, Users, Officers, Stations, SOS Panel, AdminShell |
| [Part 10](PART_10_Widgets.md) | **Widgets** | SOSButton, OfflineBanner, form steps, map markers, common UI components |
| [Part 11](PART_11_Startup.md) | **Startup & Dependencies** | main.dart, app.dart, pubspec.yaml, Supabase RPCs, environment config |
| [Part 12](PART_12_Database.md) | **Database & Security** | All 8 table schemas, RLS policies, Realtime config, security layers |
| [Part 13](PART_13_Testing.md) | **Testing & Deployment** | Unit tests, manual checklist, build commands, production considerations |
| [Part 14](PART_14_Setup_Guide.md) | **Setup & Installation** | Prerequisites, Supabase setup, environment configuration |
| [Part 15](PART_15_User_Manual.md) | **User Manual** | Non-technical guide for Citizen and Admin app usage |
| [Part 16](PART_16_Academic_Context.md)| **Academic Context** | Abstract, problem statement, objectives, future scope, conclusion |
| [Part 17](PART_17_SRS_and_Use_Cases.md)| **SRS & Use Cases** | Functional requirements, NFRs, use case specifications |
| [Part 18](PART_18_System_Diagrams.md)| **System Diagrams** | System Architecture, Data Flow Diagram, Sequence Diagrams, State Machine |
| [Part 19](PART_19_Methodology_and_Feasibility.md)| **Methodology & Feasibility** | Existing system vs proposed, Agile SDLC, Feasibility Study |

---

## Quick Reference

### Key Files

| File | Purpose |
|------|---------|
| [lib/main.dart](file:///f:/Shieldx/lib/main.dart) | App entry point |
| [lib/app.dart](file:///f:/Shieldx/lib/app.dart) | Root MaterialApp.router |
| [lib/common/core/router/app_router.dart](file:///f:/Shieldx/lib/common/core/router/app_router.dart) | All routes + redirect logic |
| [lib/common/core/constants/app_constants.dart](file:///f:/Shieldx/lib/common/core/constants/app_constants.dart) | Supabase URL, table names |
| [lib/common/core/constants/app_colors.dart](file:///f:/Shieldx/lib/common/core/constants/app_colors.dart) | Full color palette |
| [lib/common/providers/auth_provider.dart](file:///f:/Shieldx/lib/common/providers/auth_provider.dart) | Auth state + AuthNotifier |
| [lib/user/providers/sos_provider.dart](file:///f:/Shieldx/lib/user/providers/sos_provider.dart) | SOS lifecycle |
| [lib/common/providers/complaint_provider.dart](file:///f:/Shieldx/lib/common/providers/complaint_provider.dart) | Complaint state + offline |
| [lib/common/data/services/auth_service.dart](file:///f:/Shieldx/lib/common/data/services/auth_service.dart) | Supabase Auth calls |
| [lib/common/data/services/complaint_service.dart](file:///f:/Shieldx/lib/common/data/services/complaint_service.dart) | Complaint CRUD + stats |
| [lib/common/data/services/emergency_service.dart](file:///f:/Shieldx/lib/common/data/services/emergency_service.dart) | SOS CRUD + admin notify |
| [lib/common/data/services/sync_service.dart](file:///f:/Shieldx/lib/common/data/services/sync_service.dart) | Offline queue + sync |
| [lib/common/core/utils/complaint_classifier.dart](file:///f:/Shieldx/lib/common/core/utils/complaint_classifier.dart) | Keyword-based auto-classify |
| [lib/common/core/utils/app_validators.dart](file:///f:/Shieldx/lib/common/core/utils/app_validators.dart) | Form validation rules |
| [lib/common/core/services/preferences_service.dart](file:///f:/Shieldx/lib/common/core/services/preferences_service.dart) | SharedPreferences wrapper |

### Key Providers

| Provider | File | State Type |
|----------|------|-----------|
| `authNotifierProvider` | auth_provider.dart | `AsyncValue<ProfileModel?>` |
| `routerProvider` | app_router.dart | `GoRouter` |
| `complaintProvider` | complaint_provider.dart | `AsyncValue<List<ComplaintModel>>` |
| `allComplaintsStreamProvider` | complaint_provider.dart | `AsyncValue<List<ComplaintModel>>` |
| `sosNotifierProvider` | sos_provider.dart | `SOSState` |
| `notificationProvider` | notification_provider.dart | `AsyncValue<List<NotificationModel>>` |
| `connectivityProvider` | connectivity_provider.dart | `bool` |
| `selectedStationProvider` | selected_station_provider.dart | `String?` |
| `gpsSimulationProvider` | gps_simulation_provider.dart | `GpsSimulationState` |

### Complaint Status Flow

```
submitted → in_progress → under_investigation → resolved
                                              → closed
                                              → rejected
```

### GPS Fallback Chain

```
1. GPS Simulation (if demo mode active)
2. Device GPS with timeout (6–8s)
3. Last known position
4. Default: Sylhet city centre (24.89996, 91.87030)
```

---

*Documentation generated: 2026-06-01*  
*All 19 parts cover the complete ShieldX codebase and project context.*
