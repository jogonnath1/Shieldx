<div align="center">
  <img src="assets/icons/app_icon_1024.png" alt="ShieldX Logo" width="150"/>
  <h1>🛡️ ShieldX</h1>
  <p><strong>Crime Reporting & Emergency Management System</strong></p>
  
  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" />
    <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License" />
    <img src="https://img.shields.io/badge/Docs-19_Parts-blue?style=for-the-badge" alt="Documentation" />
  </p>
</div>

---

## 📖 Overview

**ShieldX** is a comprehensive mobile application designed to bridge the gap between citizens and law enforcement. Tailored for the **Sylhet Metropolitan Police (SMP)** jurisdiction, it empowers citizens to report crimes, track complaints in real-time, and trigger SOS alerts during emergencies. Simultaneously, it provides police administrators with a powerful dashboard to manage reports, dispatch officers, and monitor active emergencies.

<div align="center">
  <img src="diagrams/rendered/screenshot_citizen_home.png" alt="Citizen Home" width="250"/>
  &nbsp;&nbsp;
  <img src="diagrams/rendered/screenshot_complaint_form.png" alt="Complaint Form" width="250"/>
  &nbsp;&nbsp;
  <img src="diagrams/rendered/screenshot_admin_dashboard.png" alt="Admin Dashboard" width="250"/>
</div>

---

## ✨ Key Features

### 👤 Citizen (User) Portal
- 🔐 **Secure Onboarding:** Multi-step registration with email/phone OTP verification and NID validation.
- 📝 **Smart Complaint Submission:** 3-step intuitive form with auto crime classification, live location picker, and multimedia evidence upload.
- 📡 **Real-time Tracking:** Live status updates tracking the journey of a complaint (`Submitted` ➡️ `In Progress` ➡️ `Investigating` ➡️ `Resolved`).
- 🚨 **SOS Emergency:** Instant one-tap panic button broadcasting live GPS coordinates, equipped with a 3-second cancellation window.
- 🗺️ **Interactive Police Map:** Integrated maps highlighting the nearest SMP stations based on the user's live geolocation.
- 🔔 **Instant Notifications:** Real-time push notifications keeping users informed of every status change.

### 👮 Admin & Officer Portal
- 📊 **Command Dashboard:** Live analytics featuring pie charts, trend graphs, and geographical location heatmaps.
- 📋 **Complaint Management:** Advanced filtering, sorting, officer assignment, and status updates for efficient case handling.
- 👥 **Access Control:** Manage citizen profiles, block/unblock malicious users, and assign admin privileges.
- 🚓 **Officer Dispatch:** Add and deploy field officers linked to specific regional stations.
- 🔴 **Live SOS Panel:** Real-time monitoring of active emergency alerts with precise citizen GPS coordinates.
- 🏢 **Station Switcher:** Dedicated views to analyze statistics for specific stations (e.g., Kotwali, Moglabazar).

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **UI Framework** | [Flutter](https://flutter.dev/) (Dart) |
| **State Management** | [Riverpod](https://riverpod.dev/) (`StateNotifier`, `StreamProvider`) |
| **Routing** | [GoRouter](https://pub.dev/packages/go_router) (Declarative, Redirect-based) |
| **Backend & Database**| [Supabase](https://supabase.com/) (PostgreSQL + Row Level Security) |
| **Real-time Sync** | Supabase Realtime (Postgres Change Events) |
| **Mapping Services** | `flutter_map` + OpenStreetMap Tiles |
| **Data Visualization** | `fl_chart` |
| **Animations** | `flutter_animate` |

---

## 🏗️ Architecture & System Design

The project follows a clean, modular architecture separating the Admin and User environments.

<details>
<summary><b>Click to expand Directory Structure</b></summary>

```text
lib/
├── admin/            # 👮 Admin-specific features and modules
│   ├── data/         # Models, repositories, and backend services
│   ├── presentation/ # Dashboards, complaint management, user control screens
│   └── providers/    # Admin-specific state management (Riverpod)
│
├── common/           # 📦 Shared modules and core infrastructure
│   ├── core/         # Theming, routing, constants, and utilities
│   ├── data/         # Shared data models and Authentication services
│   ├── presentation/ # Splash screens, notification panels, reusable widgets
│   └── providers/    # Global state management
│
└── user/             # 👤 Citizen-specific features and modules
    ├── data/         # User-focused data handling
    ├── presentation/ # Complaint submission, SOS, interactive maps, profiles
    └── providers/    # Citizen state management
```
</details>

### System Architecture
<div align="center">
  <img src="diagrams/rendered/component_system_architecture.png" alt="System Architecture Diagram" width="600"/>
</div>

---

## 🗄️ Database Schema

The backend relies on a robust PostgreSQL database hosted on Supabase:

| Table | Purpose |
|---|---|
| `profiles` | Extended user data including name, phone, NID, role, and verification status. |
| `complaints` | Core table for crime reports containing status, geospatial data, and evidence URLs. |
| `status_history` | Audit trail logging every status change of a complaint for transparency. |
| `emergencies` | Live SOS alerts storing real-time GPS coordinates of users in distress. |
| `notifications` | Isolated notification inboxes for individual users. |
| `phone_verifications` | Temporary records handling OTP logic for phone verification. |

### Entity-Relationship Diagram
<div align="center">
  <img src="diagrams/rendered/er_diagram_database.png" alt="ER Diagram" width="600"/>
</div>

---

## 📚 Comprehensive Documentation

ShieldX has a comprehensive 19-part documentation suite. You can explore all details regarding the project setup, architectural decisions, and use cases inside the `Project Documentation/` folder.

👉 **[Start with the Documentation Index (Project Documentation/INDEX.md)](Project%20Documentation/INDEX.md)**

---

## 🚀 Getting Started

Follow these steps to set up the project locally.

### Prerequisites
- **Flutter SDK** `>= 3.0`
- **Dart SDK** `>= 3.0`
- A **Supabase** project configured with the required schema and RPC functions.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jogonnath1/Shieldx.git
   cd Shieldx
   ```

2. **Environment Configuration:**
   If the project requires environment variables (e.g. Supabase keys), configure them according to `.env.example` or the documentation.

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

### Code Quality & Formatting
Ensure the codebase remains clean and consistent:
```bash
dart format --line-length 120 lib/   # Auto-format code
dart analyze lib/                     # Run static analysis
```

---

## 🔒 Security & Privacy

Security is a foundational element of ShieldX:
- **Row Level Security (RLS):** Strictly enforced on all Supabase tables ensuring citizens can only access their own data.
- **Authentication:** JWT-based access. The Supabase *anon key* is public by design and grants zero privileged access without a validated token.
- **Route Protection:** Admin pages are fortified at both the application level (GoRouter redirects) and database level (RLS policy `role` validation).

---

## 🤝 Contributing

We welcome contributions to ShieldX! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on how to submit pull requests, report issues, and suggest enhancements.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <sub>Built with ❤️ for a safer tomorrow.</sub>
</div>
