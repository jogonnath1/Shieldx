# ShieldX — Full Project Documentation
## Part 13: Testing, Quality & Deployment

---

## 13.1 Code Quality

### Static Analysis

```bash
dart analyze lib/
# Target: 0 errors, 0 warnings, 0 hints
```

The project achieved **0 errors, 0 warnings** from `dart analyze` after the pre-defense cleanup.

### Formatter

```bash
dart format --line-length 120 lib/
# Applied to all 86 Dart files
```

Line length is set to 120 (not the default 80) to better accommodate Flutter's often-nested widget trees.

### Automatic Fixes

```bash
dart fix --apply
```

Applied to fix:
- Unused imports (19 files)
- `const` constructor opportunities (multiple files)
- `.withOpacity()` → `.withValues(alpha:)` migration (32 files)

---

## 13.2 Refactoring Summary (Pre-Defense)

| Change | Files Affected |
|--------|----------------|
| `dart format --line-length 120` | 86 files |
| `dart fix --apply` (unused imports, const fixes) | 19 files |
| `.withOpacity()` → `.withValues(alpha:)` deprecations | 32 files |
| `print()` → `debugPrint()` | 3 files |
| Empty `catch {}` → `catch (e) { debugPrint(...) }` | 6 locations |
| Duplicate `_buildStatusStats` loop → shared private helper | `complaint_service.dart` |
| Unused methods removed (`_buildSectionHeader`, `_buildDetailRow`) | `admin_users_screen.dart` |
| Unused class removed (`_HotspotCluster`) | `police_stations_screen.dart` |
| Unused import removed | `police_stations_screen.dart` |
| Unused variable removed | `change_email_screen.dart` |
| Doc comments added to complex logic | `auth_provider`, `app_router`, `complaint_service`, `preferences_service` |

---

## 13.3 Unit Tests

**File**: `test/widget_test.dart`

The project has a basic test scaffold. The following areas are candidates for unit tests:

### `ComplaintClassifier`

```dart
// Test: Classification with clear keyword match
test('classifies theft correctly', () {
  final result = ComplaintClassifier.classify('my wallet was stolen from my pocket');
  expect(result?.category, 'Theft');
  expect(result?.confidence, isIn([ConfidenceLevel.high, ConfidenceLevel.medium]));
});

// Test: Returns null for short descriptions
test('returns null for short text', () {
  final result = ComplaintClassifier.classify('help');
  expect(result, null);
});
```

### `AppValidators`

```dart
test('phone validator accepts valid BD number', () {
  expect(AppValidators.phone('01712345678'), null);
});

test('phone validator rejects invalid number', () {
  expect(AppValidators.phone('12345'), isNotNull);
});

test('NID validator accepts 10 digits', () {
  expect(AppValidators.nid('1234567890'), null);
});
```

### `ProfileModel`

```dart
test('initials from full name', () {
  final profile = ProfileModel(id: '1', name: 'John Doe', role: 'user');
  expect(profile.initials, 'JD');
});

test('isAdmin returns true for admin role', () {
  final profile = ProfileModel(id: '1', role: 'admin');
  expect(profile.isAdmin, true);
});
```

---

## 13.4 Testing Strategy

### Manual Testing Checklist

#### Auth Flow
- [ ] New user registration (all 3 steps)
- [ ] OTP verification (mock + real Supabase email OTP)
- [ ] Duplicate email/NID rejected on Step 1
- [ ] Login with saved credentials (auto-login on restart)
- [ ] Forgot password full flow
- [ ] Blocked user is redirected to `/blocked` immediately

#### Complaint Flow
- [ ] Submit with GPS location and evidence photos
- [ ] Submit anonymously
- [ ] Auto-classification suggestion appears and is correct
- [ ] Status update flow (admin side)
- [ ] Citizen receives notification after status update
- [ ] Edit complaint (only when status = 'submitted')
- [ ] Soft-delete and restore

#### SOS Flow
- [ ] SOS button requires verified status
- [ ] 3-second countdown with cancel
- [ ] Live GPS coordinates update on admin panel
- [ ] Admin can resolve; citizen's SOS resets to idle
- [ ] Citizen can mark safe

#### Offline Mode
- [ ] Submit complaint while offline → queued in outbox
- [ ] Outbox count shows in offline banner
- [ ] Reconnect → outbox auto-syncs

#### Admin Operations
- [ ] Verify/block user → citizen's app reacts immediately
- [ ] Assign officer to complaint
- [ ] Station switcher filters dashboard and complaint list
- [ ] SOS alert panel shows when active emergency exists

---

## 13.5 Build & Deployment

### Debug Build

```bash
flutter run --debug
```

### Release Build (Android APK)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Release Build (Android App Bundle)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Release Build (iOS)

```bash
flutter build ipa --release
# Requires: Xcode + Apple Developer account
```

### Web Build

```bash
flutter build web --release
# Output: build/web/
```

---

## 13.6 Android Configuration

The Android manifest requires the following permissions:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**Minimum SDK**: 21 (Android 5.0)  
**Target SDK**: 34 (Android 14)

---

## 13.7 Known Limitations & Production Considerations

| Issue | Current Approach | Production Solution |
|-------|-----------------|---------------------|
| Credentials stored in plaintext | `SharedPreferences` for demo auto-login | Flutter Secure Storage or remove auto-login |
| SMS OTP via mock table | `phone_verifications` table with 6-digit demo code | Real SMS provider (Twilio, AWS SNS) |
| Supabase anon key in source | Hardcoded in `app_constants.dart` | Load from environment/build config |
| No push notifications | In-app only (Supabase Realtime) | Firebase Cloud Messaging (FCM) |
| Offline sync is fire-and-forget | Simple retry on reconnect | Exponential backoff + conflict resolution |
| No complaint evidence encryption | Photos stored as-is in Supabase Storage | Client-side encryption before upload |

---

## 13.8 Performance Notes

- **Realtime streams**: All `flutter_map` streams filter data client-side after receiving the full list from Supabase. For large datasets, server-side filtering via PostgREST query params should be added.
- **Stats computation**: Dashboard stats re-compute from the full complaint stream on every emission. For high-volume deployments, replace with materialized views or scheduled PostgreSQL aggregates.
- **Image upload**: Evidence photos are uploaded sequentially before complaint submission. Parallel uploads with `Future.wait()` would improve submit time.
- **Admin users list**: Loads all user profiles in a single query. Pagination should be added as user count grows.

---

*Next: [Index — Table of Contents](INDEX.md)*
