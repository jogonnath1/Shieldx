# ShieldX — Full Project Documentation
## Part 14: Local Setup & Installation Guide

---

## 14.1 Prerequisites

Before setting up ShieldX locally, ensure you have the following installed:

1. **Flutter SDK**: Version 3.19.0 or higher
2. **Dart SDK**: Version 3.3.0 or higher
3. **IDE**: VS Code (recommended) or Android Studio
4. **Git**: For version control
5. **Supabase Account**: A free project on Supabase.com
6. **Android Emulator / Physical Device**: For testing

---

## 14.2 Supabase Backend Setup

ShieldX relies on Supabase for Auth, Database, and Storage.

1. **Create Project**: Create a new project on [Supabase](https://supabase.com).
2. **Execute SQL Setup**:
   - Go to the **SQL Editor** in your Supabase dashboard.
   - Run the provided schema files (which define `profiles`, `complaints`, `status_history`, `emergencies`, `notifications`, `phone_verifications`, and `officers`).
   - Enable **Row Level Security (RLS)** and apply the necessary policies.
3. **Storage Buckets**:
   - Go to **Storage** and create two public buckets:
     - `evidence` (for complaint photos)
     - `avatars` (for user profiles)
4. **Realtime**:
   - Go to **Database > Replication** and enable Realtime for the `complaints`, `profiles`, `emergencies`, and `messages` tables.

---

## 14.3 Environment Configuration

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ShieldX.git
   cd ShieldX
   ```

2. Open `lib/common/core/constants/app_constants.dart`.

3. Update the Supabase credentials with your project's keys:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

---

## 14.4 Running the Application

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Run the code generator for Riverpod (if necessary/applicable in the future):
   ```bash
   dart run build_runner build -d
   ```

3. Run the app on an attached device or emulator:
   ```bash
   flutter run
   ```

---

## 14.5 Generating Release Builds

**For Android (APK):**
```bash
flutter build apk --release
```
*Output: `build/app/outputs/flutter-apk/app-release.apk`*

**For Android (App Bundle for Play Store):**
```bash
flutter build appbundle --release
```

**For Web:**
```bash
flutter build web --release
```

---

*Next: [Part 15 — User Manual](PART_15_User_Manual.md)*
