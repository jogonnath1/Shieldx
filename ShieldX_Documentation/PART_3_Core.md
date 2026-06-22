# ShieldX — Full Project Documentation
## Part 3: Core Module

The `lib/core/` directory contains app-wide, framework-agnostic utilities that do not belong to any single feature. It is subdivided into five sub-packages.

---

## 3.1 `core/constants/app_constants.dart`

**Class**: `AppConstants` (private constructor — all members `static`)

Central registry of all magic strings used across the app. Changing a table name here propagates automatically to every service that imports this file.

| Constant / Method | Value / Behavior |
|-------------------|-----------------|
| `supabaseUrl` | `https://thucigugoxevxwrqpxjm.supabase.co` |
| `supabaseAnonKey` | Supabase anon JWT (public, safe) |
| `profilesTable` | `'profiles'` |
| `complaintsTable` | `'complaints'` |
| `officersTable` | `'officers'` |
| `statusHistoryTable` | `'status_history'` |
| `messagesTable` | `'messages'` |
| `notificationsTable` | `'notifications'` |
| `evidenceBucket` | `'evidence'` (Supabase Storage bucket for complaint photos) |
| `avatarBucket` | `'avatars'` (Supabase Storage bucket for profile photos) |
| `roleUser` | `'user'` |
| `roleAdmin` | `'admin'` |
| `complaintStatuses` | `['submitted', 'in_progress', 'under_investigation', 'resolved', 'closed', 'rejected']` |
| `crimeCategories` | List of 14 crime categories |
| `statusLabel(status)` | Returns a human-readable label for a status string |

---

## 3.2 `core/constants/app_colors.dart`

**Class**: `AppColors` (private constructor — all members `static const`)

Defines the entire visual design palette. The app uses a **dark theme** based on deep navy blues with a teal accent.

### Base Palette

| Name | Hex | Usage |
|------|-----|-------|
| `primary` | `#1565C0` | Primary buttons, active elements |
| `primaryLight` | `#1E88E5` | Lighter interactive states |
| `primaryDark` | `#0D47A1` | Pressed/dark states |
| `accent` | `#00BFA5` | Secondary CTAs, highlights |
| `accentLight` | `#1DE9B6` | Shimmer, glow effects |
| `background` | `#0A0E1A` | App background (deepest dark) |
| `surface` | `#111827` | Card/panel surface color |
| `surfaceLight` | `#1F2937` | Elevated surfaces |
| `card` | `#1C2333` | Card background |
| `cardBorder` | `#2D3748` | Card border/divider lines |
| `textPrimary` | `#F9FAFB` | Primary body text |
| `textSecondary` | `#9CA3AF` | Secondary / muted text |
| `textHint` | `#6B7280` | Placeholder / hint text |

### Status Colors

| Status | Color | Hex |
|--------|-------|-----|
| `submitted` | Blue | `#3B82F6` |
| `in_progress` | Amber | `#F59E0B` |
| `under_investigation` | Purple | `#8B5CF6` |
| `resolved` | Green | `#10B981` |
| `closed` | Gray | `#6B7280` |
| `rejected` | Red | `#EF4444` |

### Semantic Colors

| Name | Hex | Usage |
|------|-----|-------|
| `error` | `#EF4444` | Error states |
| `success` | `#10B981` | Success states |
| `warning` | `#F59E0B` | Warning states |
| `info` | `#3B82F6` | Info states |

### Gradients

| Name | Direction | Colors |
|------|-----------|--------|
| `primaryGradient` | top-left → bottom-right | `#1565C0` → `#0D47A1` |
| `backgroundGradient` | top → bottom | `#0A0E1A` → `#111827` |
| `cardGradient` | top-left → bottom-right | `#1C2333` → `#1A2540` |
| `accentGradient` | top-left → bottom-right | `#00BFA5` → `#1565C0` |

### Methods

```dart
static Color statusColor(String status)
// Returns the matching status color, or textSecondary for unknowns.
// Also handles 'offline_pending' → Colors.orangeAccent
```

---

## 3.3 `core/router/app_router.dart`

Defines the full GoRouter navigation tree and redirect logic.

### Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `_routerNotifierProvider` | `Provider<_RouterNotifier>` | Bridges Riverpod auth state changes to GoRouter's `refreshListenable` |
| `routerProvider` | `Provider<GoRouter>` | The configured GoRouter instance |

### `_RouterNotifier`

An internal `ChangeNotifier` that listens to `authNotifierProvider` and calls `notifyListeners()` on every auth state change. This causes GoRouter to re-run the `redirect()` function.

```dart
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AsyncValue<dynamic>>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }
}
```

### Route persistence

After each navigation, the delegate listener saves the new route via `prefsService.saveLastRoute(location)` and fires `navigationTriggerProvider` to notify any watching widgets.

---

## 3.4 `core/services/preferences_service.dart`

**Class**: `PreferencesService`

Wraps `SharedPreferences` to provide typed access to all locally-persisted data.

| Provider | Purpose |
|----------|---------|
| `sharedPreferencesProvider` | Exposes the `SharedPreferences` instance (injected at startup via `ProviderScope.overrides`) |
| `preferencesServiceProvider` | Exposes the `PreferencesService` wrapper |

### Methods

| Method | Description |
|--------|-------------|
| `saveComplaintDraft(Map)` | Saves the in-progress complaint form as JSON |
| `getComplaintDraft()` | Retrieves the saved draft (or null) |
| `clearComplaintDraft()` | Removes the draft |
| `saveLastRoute(String)` | Persists the current route (skips auth routes) |
| `getLastRoute()` | Returns the last saved non-auth route |
| `clearLastRoute()` | Clears the saved route on sign-out |
| `saveCredentials(email, password)` | Stores login credentials for auto-login |
| `getSavedEmail()` | Returns saved email (or null) |
| `getSavedPassword()` | Returns saved password (or null) |
| `clearCredentials()` | Clears saved credentials (called on sign-out or block) |

> **Security Note**: Credentials are stored in plaintext for demo/development convenience. In production, replace with a secure keychain/keystore solution.

---

## 3.5 `core/utils/app_validators.dart`

**Class**: `AppValidators` (private constructor — all members `static`)

Centralized form validators used across all form screens.

| Validator | Signature | Rules |
|-----------|-----------|-------|
| `required(fieldName)` | `String? Function(String?)` | Rejects null or blank |
| `email` | `String? email(String?)` | Regex: `[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}` |
| `phone` | `String? phone(String?)` | Bangladeshi: `01[3-9]\d{8}` (11 digits) |
| `password` | `String? password(String?)` | Minimum 8 characters |
| `confirmPassword(original)` | `String? Function(String?)` | Checks equality with `original` |
| `otp` | `String? otp(String?)` | Exactly 6 digits |
| `nid` | `String? nid(String?)` | Optional; 10 or 17 digits only |
| `minLength(length, {fieldName})` | `String? Function(String?)` | Generic min-length check |

---

## 3.6 `core/utils/complaint_classifier.dart`

**Class**: `ComplaintClassifier` (private constructor — all members `static`)

Auto-classifies a crime description text into one of the 14 supported categories by keyword matching.

### Algorithm

1. Normalize input to lowercase.
2. For each category, count how many of its keywords appear in the text.
3. Select the category with the highest keyword hit count.
4. Compute confidence = `hits / total_keywords_in_category`.
5. Map confidence to `ConfidenceLevel`:
   - ≥ 0.30 → **High**
   - ≥ 0.10 → **Medium**
   - < 0.10 → **Low**

### Return Type: `ClassificationResult?`

```dart
class ClassificationResult {
  final String category;        // e.g. 'Theft'
  final ConfidenceLevel confidence; // high | medium | low
  final int score;              // raw keyword hit count
  String get confidenceLabel;  // 'High confidence', etc.
}
```

Returns `null` if the description is shorter than 10 characters or no keywords match.

---

## 3.7 `core/utils/app_dialog.dart` and `app_snackbar.dart`

Reusable static helpers for consistent dialogs and snackbars throughout the app.

**`app_dialog.dart`** provides:
- `AppDialog.confirm(...)` — shows a confirmation dialog with cancel/confirm buttons
- `AppDialog.error(...)` — shows an error dialog
- `AppDialog.info(...)` — shows an info dialog

**`app_snackbar.dart`** provides:
- `AppSnackbar.success(...)` — shows a green success snackbar
- `AppSnackbar.error(...)` — shows a red error snackbar
- `AppSnackbar.info(...)` — shows a blue info snackbar

---

## 3.8 `core/theme/app_theme.dart`

Defines the `MaterialThemeData` for the app (dark mode):

- Uses `AppColors.background` for scaffold background
- Uses `AppColors.primary` for color scheme seed
- Applies `Google Fonts` for typography (via `google_fonts` package)
- Sets up `AppBar`, `Card`, `InputDecoration`, `ElevatedButton`, and `BottomNavigationBar` themes

---

*Next: [Part 4 — Data Models](PART_4_Models.md)*
