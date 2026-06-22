# ShieldX — Full Project Documentation
## Part 11: App Entry Point, Startup & Dependencies

---

## 11.1 `main.dart` — App Entry Point

**File**: `lib/main.dart`

The `main()` function is `async` and performs 4 initialization steps before `runApp()`:

```dart
void main() async {
  // Step 1: Ensure Flutter engine is initialized before any platform call
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2: Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Step 3: Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Step 4: Set system UI colors (transparent status bar, dark nav bar)
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0E1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Step 5: Initialize Supabase with PKCE auth flow
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      localStorage: SharedPreferencesLocalStorage(
        persistSessionKey: 'supabase.auth.token',
      ),
    ),
  );

  // Step 6: Run app inside Riverpod ProviderScope
  // SharedPreferences injected via override (the only sync provider)
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const ShieldXApp(),
    ),
  );
}
```

### Key Design Points

- **PKCE Auth Flow** (`AuthFlowType.pkce`) is used instead of the implicit flow for better security on mobile.
- **SharedPreferences session storage** ensures the Supabase JWT is persisted to disk so users remain logged in across app restarts.
- `sharedPreferencesProvider` is the only provider that requires a `ProviderScope.overrides` injection — all others are lazy-initialized.

---

## 11.2 `app.dart` — Root Widget

**File**: `lib/app.dart`

```dart
class ShieldXApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'ShieldX',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- Uses `MaterialApp.router` (not `MaterialApp`) to integrate GoRouter.
- `routerProvider` is watched — if the provider is ever re-created (e.g., hot reload), the router updates automatically.
- `AppTheme.darkTheme` provides the complete Material 3 theme.

---

## 11.3 `pubspec.yaml` — Dependencies

### Runtime Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `supabase_flutter` | ^2.5.6 | Backend: Auth, DB, Realtime, Storage |
| `go_router` | ^13.2.0 | Declarative navigation with redirect |
| `flutter_riverpod` | ^2.5.1 | State management |
| `google_fonts` | ^6.2.1 | Typography (Inter / Roboto) |
| `flutter_animate` | ^4.5.0 | Micro-animations and transitions |
| `shimmer` | ^3.0.0 | Skeleton loading placeholders |
| `fl_chart` | ^0.68.0 | Charts (pie, bar, line) |
| `image_picker` | ^1.0.7 | Camera and gallery photo selection |
| `intl` | ^0.19.0 | Date/time formatting and localization |
| `uuid` | ^4.3.3 | UUID v4 generation (for outbox items) |
| `shared_preferences` | ^2.5.5 | Local key-value storage |
| `flutter_map` | ^8.3.0 | OpenStreetMap interactive map tiles |
| `latlong2` | ^0.9.1 | LatLng coordinate type for flutter_map |
| `url_launcher` | ^6.3.2 | Open external URLs (Google Maps, email) |
| `geolocator` | ^14.0.2 | Device GPS access |
| `http` | ^1.6.0 | OSM Nominatim API calls |
| `file_picker` | ^11.0.2 | File system document picker |

### Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | SDK | Unit and widget testing |
| `flutter_lints` | ^3.0.0 | Lint rules for code quality |

### Assets

```yaml
flutter:
  assets:
    - assets/images/
    - assets/animations/
    - assets/icons/
```

---

## 11.4 Supabase Database Functions (RPCs)

The app relies on several PostgreSQL functions called via `supabase.rpc()`:

| Function | Parameters | Returns | Purpose |
|----------|-----------|---------|---------|
| `check_contact_exists` | `email_to_check`, `phone_to_check` | `{email_exists: bool, phone_exists: bool}` | Pre-registration duplicate check |
| `check_nid_exists` | `nid_to_check` | `bool` | Pre-registration NID uniqueness check |
| `delete_incomplete_registration` | `user_id_to_delete` | `bool` | Removes a half-completed auth user + profile |
| `is_user_blocked` | `email_to_check` | `bool` | Check if user is blocked before login |
| `delete_user_account` | `user_id` | `void` | Admin-triggered full account deletion |

---

## 11.5 Supabase Storage Buckets

| Bucket | Access | Content |
|--------|--------|---------|
| `evidence` | Authenticated read, user write | Complaint evidence photos |
| `avatars` | Public read, user write | Profile avatar images |

---

## 11.6 Code Quality Standards

All code conforms to:

```bash
dart format --line-length 120 lib/   # Applied to all 86 .dart files
dart analyze lib/                     # Result: 0 errors, 0 warnings
dart fix --apply                      # Applied: const fixes, unused imports
```

**Conventions enforced**:
- No `print()` → replaced with `debugPrint()` (only active in debug builds)
- No empty `catch {}` → all catch blocks log with `debugPrint()`
- No `.withOpacity()` (deprecated) → replaced with `.withValues(alpha:)`
- All complex logic sections are commented
- Private helper methods documented with `///` doc comments

---

## 11.7 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android SDK or Xcode (for iOS)
- A Supabase project with the required tables and RPC functions

### Run the App

```bash
flutter pub get
flutter run
```

### Run on Specific Platform

```bash
flutter run -d android
flutter run -d ios
flutter run -d chrome   # Web mode
```

### Lint & Format

```bash
dart format --line-length 120 lib/   # Format all Dart files
dart analyze lib/                     # Run static analysis
dart fix --apply                      # Auto-fix common issues
flutter test                          # Run unit + widget tests
```

---

## 11.8 Environment Configuration

The only environment-specific values are in `AppConstants`:

```dart
// lib/core/constants/app_constants.dart
static const String supabaseUrl = 'https://thucigugoxevxwrqpxjm.supabase.co';
static const String supabaseAnonKey = '<anon_jwt_here>';
```

For a production deployment, these should be moved to environment variables or a `.env` file loaded at build time (e.g., using the `flutter_dotenv` package).

---

*Next: [Part 12 — Database Schema & Security](PART_12_Database.md)*
