# ShieldX — Full Project Documentation
## Part 6: Providers (State Management)

All Riverpod providers live in `lib/providers/`. Every provider has a single responsibility and communicates only downward (never laterally between providers except via `ref.read/watch`).

---

## 6.1 `auth_provider.dart`

The most critical provider file. Manages authentication state for the entire app.

### Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `authServiceProvider` | `Provider<AuthService>` | Singleton `AuthService` instance |
| `authStateProvider` | `StreamProvider<AuthState>` | Raw Supabase auth event stream |
| `currentUserProvider` | `Provider<User?>` | Currently authenticated Supabase `User` (or null) |
| `currentProfileProvider` | `FutureProvider<ProfileModel?>` | One-time fetch of the current user's profile |
| `authNotifierProvider` | `StateNotifierProvider<AuthNotifier, AsyncValue<ProfileModel?>>` | **Primary auth state** — reactive profile with real-time updates |

### `AuthNotifier` (StateNotifier)

State: `AsyncValue<ProfileModel?>`
- `AsyncValue.loading()` — auth check in progress
- `AsyncValue.data(profile)` — authenticated (profile can be null if signed out)
- `AsyncValue.error(e, st)` — unexpected error

#### Startup Sequence (`_init()`)

```
1. Try Supabase.currentUser → fetch profile
2. If no session → check SharedPreferences for saved email/password
3. If credentials found → check if user is blocked → auto sign-in
4. If profile is blocked → sign out + clear credentials
5. If authenticated → subscribe to real-time profile updates
6. Set state to AsyncValue.data(profile)
```

#### Key Methods

| Method | Description |
|--------|-------------|
| `signIn(email, password)` | Checks block status → signs in → fetches profile → sets up realtime |
| `signUp({...})` | Creates account → fetches profile → sets state |
| `signOut()` | Cancels realtime → signs out → clears stored route and credentials |
| `refresh()` | Re-fetches profile from DB; signs out if blocked |
| `updateProfileDetails({...})` | Updates profile + refreshes state |
| `checkContactExists({email, phone})` | Delegates to AuthService |
| `checkNidExists(nid)` | Delegates to AuthService |
| `sendPhoneOtp(phone)` / `verifyPhoneOtp(phone, token)` | OTP flow delegates |
| `sendEmailOtp(email)` / `verifyEmailOtp(email, token)` | OTP flow delegates |
| `saveMockOtp(phone, otp)` / `verifyMockOtp(phone, otp)` | Demo phone OTP delegates |
| `deleteIncompleteRegistration()` | Cleans up half-finished registration |
| `_setupProfileSubscription(profile)` | Opens Supabase Realtime channel for the user's profile row |
| `_cancelProfileSubscription()` | Closes the realtime channel |

---

## 6.2 `complaint_provider.dart`

Manages citizen complaint state with offline support.

### Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `complaintServiceProvider` | `Provider<ComplaintService>` | Singleton `ComplaintService` |
| `syncServiceProvider` | `Provider<SyncService>` | Singleton `SyncService` |
| `complaintProvider` | `StateNotifierProvider<ComplaintNotifier, AsyncValue<List<ComplaintModel>>>` | Citizen's complaint list (with offline cache) |
| `allComplaintsStreamProvider` | `StreamProvider<List<ComplaintModel>>` | Real-time stream of ALL complaints (admin) |
| `filteredComplaintsStreamProvider` | `StreamProvider.family<List<ComplaintModel>, String?>` | All complaints filtered by thana (admin station view) |

### `ComplaintNotifier`

State: `AsyncValue<List<ComplaintModel>>`

| Method | Description |
|--------|-------------|
| `loadUserComplaints(userId)` | Loads from Supabase; falls back to cache if offline; caches on success |
| `submitComplaint(data)` | Submits online; falls back to `SyncService.addToOutbox()` if offline |
| `updateComplaintStatus({...})` | Delegates to `ComplaintService.updateComplaintStatus()` |
| `deleteComplaint(id)` | Soft-deletes and removes from local state |
| `watchUserComplaints(userId)` | Subscribes to the real-time stream and updates state on each emission |

---

## 6.3 `sos_provider.dart`

Manages the full SOS alert lifecycle.

### State: `SOSState`

```dart
class SOSState {
  final SOSStatus status;         // idle | countingDown | active | error
  final int countdown;            // 3, 2, 1 (during countingDown)
  final String? activeEmergencyId;
  final String? errorMessage;
  final double? currentLatitude;  // updated live during active SOS
  final double? currentLongitude;
}
```

### `SOSStatus` enum

| Value | Meaning |
|-------|---------|
| `idle` | No SOS active |
| `countingDown` | 3-second countdown before alert is sent |
| `active` | Alert sent; live GPS tracking running |
| `error` | Something went wrong (message in `errorMessage`) |

### Key Methods on `SOSNotifier`

| Method | Description |
|--------|-------------|
| `startSOS()` | Checks permissions → checks if user is verified → starts 3-second countdown timer |
| `cancelSOSCountdown()` | Cancels during countdown window; resets to idle |
| `markSafe()` | Calls `EmergencyService.cancelEmergency()`; stops GPS tracking; resets to idle |
| `resetToIdle()` | Force-resets state |

### Internal Flow

```
startSOS()
  → validate (verified user + GPS permission)
  → state = countingDown (3 → 2 → 1)
  → _triggerSOSAlert()
      → get GPS (simulation or real device or last known or default)
      → EmergencyService.triggerSOS(lat, lng)
      → state = active
      → _startLiveLocationTracking(emergencyId)
      → _listenToEmergencyStatus(emergencyId)
            → if status == 'resolved' → reset to idle
```

### Additional Provider

| Provider | Type | Description |
|----------|------|-------------|
| `currentEmergencyStreamProvider` | `StreamProvider.family<EmergencyModel?, String>` | Watches a specific emergency by ID |

---

## 6.4 `station_map_provider.dart`

Manages the interactive police stations map state.

### State: `StationMapState`

```dart
class StationMapState {
  final List<PoliceStationModel> stations;
  final PoliceStationModel? selectedStation;
  final double? userLatitude;
  final double? userLongitude;
  final bool isLoadingLocation;
  final String? locationError;
}
```

### Key Operations

| Method | Description |
|--------|-------------|
| `loadUserLocation()` | GPS fallback chain → updates `userLatitude/userLongitude` |
| `selectStation(station)` | Sets `selectedStation` |
| `findNearestStation()` | Calculates Haversine distance to each station; selects closest |

---

## 6.5 `notification_provider.dart`

Manages the real-time notification inbox.

| Provider | Type | Purpose |
|----------|------|---------|
| `notificationServiceProvider` | `Provider<NotificationService>` | Singleton |
| `notificationProvider` | `StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>` | Reactive notification list |

### `NotificationNotifier`

| Method | Description |
|--------|-------------|
| `watchNotifications(userId)` | Subscribes to real-time stream |
| `markRead(id)` | Marks notification read + updates local state |
| `markAllRead(userId)` | Marks all read |
| `deleteNotification(id)` | Soft-deletes + removes from local list |

---

## 6.6 `connectivity_provider.dart`

| Provider | Type | Purpose |
|----------|------|---------|
| `connectivityProvider` | `StateNotifierProvider<ConnectivityNotifier, bool>` | `true` = online, `false` = offline |

### `ConnectivityNotifier`

Periodically checks internet connectivity by attempting to reach `8.8.8.8:53` (Google DNS). When transitioning from offline → online, it triggers `SyncService.syncOfflineOutbox()`.

---

## 6.7 `gps_simulation_provider.dart`

Developer/demo tool for testing GPS-dependent features without a real device outdoors.

### State: `GpsSimulationState`

```dart
class GpsSimulationState {
  final bool isSimulationActive;
  final double latitude;
  final double longitude;
}
```

When `isSimulationActive = true`, all GPS-consuming providers (`SOSNotifier`, `StationMapProvider`) use the simulated coordinates instead of the real device GPS.

---

## 6.8 Other Providers

| File | Provider | Type | Purpose |
|------|----------|------|---------|
| `admin_sos_provider.dart` | `adminSosProvider` | `StreamProvider` | Real-time stream of active SOS alerts for the admin panel |
| `officer_provider.dart` | `officerProvider` | `FutureProvider.family` | Loads officers for a given station |
| `selected_station_provider.dart` | `selectedStationProvider` | `StateProvider<String?>` | Currently selected thana in the admin station switcher |
| `navigation_trigger_provider.dart` | `navigationTriggerProvider` | `StateNotifierProvider` | Fires an event on every route change (used to refresh data on tab switch) |
| `time_provider.dart` | `timeProvider` | `StreamProvider<DateTime>` | Emits the current time every minute (for live clocks/age displays) |
| `location_cache_provider.dart` | `locationCacheProvider` | `StateNotifierProvider` | Caches reverse-geocoded addresses to avoid repeated API calls |
| `chat_provider.dart` | `chatProvider` | `StreamProvider.family` | Real-time message stream for a specific complaint |

---

*Next: [Part 7 — Presentation: Auth Screens](PART_7_Auth_Screens.md)*
