# ShieldX — Full Project Documentation
## Part 5: Data Services

All Supabase communication is isolated in `lib/common/data/services/`. No widget or provider ever imports `supabase_flutter` directly — they always go through a service class. This keeps the data layer easily mockable and testable.

---

## 5.1 `AuthService`

**File**: `lib/common/data/services/auth_service.dart`

Handles all Supabase Auth operations and profile CRUD.

| Property | Type | Description |
|----------|------|-------------|
| `currentUser` | `User?` | Currently authenticated Supabase user (or null) |
| `isLoggedIn` | `bool` | Whether a session exists |
| `authStateChanges` | `Stream<AuthState>` | Supabase auth event stream |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `checkContactExists({email, phone})` | `Future<Map<String, bool>>` | Calls `check_contact_exists` RPC — checks if email/phone are already registered |
| `checkNidExists(nid)` | `Future<bool>` | Calls `check_nid_exists` RPC — ensures NID uniqueness |
| `signUp({email, password, name, phone, nid, ...})` | `Future<AuthResponse>` | Creates Supabase Auth user + upserts profile row |
| `sendPhoneOtp(phone)` | `Future<void>` | Sends OTP via Supabase phone auth |
| `verifyPhoneOtp(phone, token)` | `Future<AuthResponse>` | Verifies the phone OTP |
| `sendEmailOtp(email)` | `Future<void>` | Sends OTP via Supabase email auth |
| `verifyEmailOtp(email, token)` | `Future<AuthResponse>` | Verifies the email OTP |
| `sendPasswordResetOtp(email)` | `Future<void>` | Sends password reset email |
| `verifyPasswordResetOtp(email, token)` | `Future<AuthResponse>` | Verifies the recovery OTP |
| `saveMockOtp(phone, otp)` | `Future<void>` | Saves a demo OTP to `phone_verifications` table |
| `verifyMockOtp(phone, otp)` | `Future<bool>` | Verifies a demo OTP from `phone_verifications` |
| `deleteIncompleteRegistration()` | `Future<bool>` | Calls `delete_incomplete_registration` RPC — cleans up half-finished registrations |
| `isEmailBlocked(email)` | `Future<bool>` | Calls `is_user_blocked` RPC |
| `signIn({email, password})` | `Future<AuthResponse>` | Signs in with email/password |
| `signOut()` | `Future<void>` | Signs out the current session |
| `resetPassword(email)` | `Future<void>` | Sends password reset email with deep-link redirect |
| `updatePassword(newPassword)` | `Future<UserResponse>` | Updates auth password |
| `updateEmail(newEmail)` | `Future<UserResponse>` | Initiates email change (requires OTP) |
| `verifyEmailChangeOtp(email, token)` | `Future<AuthResponse>` | Confirms the email change OTP |
| `getCurrentProfile()` | `Future<ProfileModel?>` | Fetches profile from DB; merges `email` from auth |
| `updateProfile(userId, data)` | `Future<void>` | Updates profile fields |
| `subscribeToProfile(userId, onUpdate)` | `RealtimeChannel` | Opens a Supabase Realtime subscription on the user's profile row |
| `removeChannel(channel)` | `Future<void>` | Closes a Realtime channel |

### Real-time Profile Subscription

```dart
_client
  .channel('public:profiles:id=eq.$userId')
  .onPostgresChanges(
    event: PostgresChangeEvent.update,
    table: 'profiles',
    filter: PostgresChangeFilter(type: eq, column: 'id', value: userId),
    callback: (payload) => onUpdate(ProfileModel.fromMap(payload.newRecord)),
  )
  .subscribe();
```

---

## 5.2 `ComplaintService`

**File**: `lib/common/data/services/complaint_service.dart`

Handles all CRUD, streaming, statistics, and soft-delete operations for the `complaints` table.

### Write Operations

| Method | Description |
|--------|-------------|
| `submitComplaint(data)` | Inserts a new complaint row; returns the created `ComplaintModel` |
| `updateComplaint(id, data)` | Updates an editable complaint (only if status == `'submitted'`) |
| `updateComplaintStatus({complaintId, status, note, assignedOfficerId, changedBy})` | Updates status + inserts `status_history` row |
| `deleteComplaint(id)` | Soft-deletes by setting `deleted_at` |
| `deleteComplaints(ids)` | Bulk soft-deletes |
| `restoreComplaint(id)` | Restores a soft-deleted complaint |
| `restoreComplaints(ids)` | Bulk restore |
| `hardDeleteComplaints(ids)` | Permanently deletes (admin only) |
| `hardDeleteAllUserComplaints(userId)` | Permanently deletes all soft-deleted complaints for a user |
| `hardDeleteAllComplaints()` | Permanently deletes all soft-deleted complaints (admin cleanup) |

### Read Operations

| Method | Returns | Description |
|--------|---------|-------------|
| `getUserComplaints(userId)` | `Future<List<ComplaintModel>>` | All active complaints for a user |
| `getAllComplaints({status, limit, offset})` | `Future<List<ComplaintModel>>` | Paginated list with optional status filter |
| `getComplaint(id)` | `Future<ComplaintModel?>` | Single complaint by ID |
| `getStatusHistory(complaintId)` | `Future<List<StatusHistoryModel>>` | Full audit trail for a complaint |
| `getDeletedUserComplaints(userId)` | `Future<List<ComplaintModel>>` | Soft-deleted complaints for a user |
| `getDeletedAllComplaints()` | `Future<List<ComplaintModel>>` | All soft-deleted complaints |
| `getHistoricalCrimeCoordinates()` | `Future<List<ComplaintModel>>` | All complaints with GPS coords (for heatmap) |

### Real-time Streams

| Method | Returns | Description |
|--------|---------|-------------|
| `watchUserComplaints(userId)` | `Stream<List<ComplaintModel>>` | Live stream of a citizen's complaints |
| `watchAllComplaints({stationThana})` | `Stream<List<ComplaintModel>>` | Live stream of all complaints; optionally filtered by thana |

### Statistics

| Method | Returns | Description |
|--------|---------|-------------|
| `getStats()` | `Future<Map<String, int>>` | Overall counts grouped by status |
| `getCategoryStats()` | `Future<Map<String, int>>` | Top 7 crime categories by complaint count |
| `getStatsForStation({stationThana})` | `Future<Map<String, int>>` | Status counts for a specific thana |
| `getCategoryStatsForStation({stationThana})` | `Future<Map<String, int>>` | Category stats for a specific thana |
| `getAllStationsStats(thanas)` | `Future<Map<String, Map<String, int>>>` | Stats for all thanas in one query |

### Private Helpers

| Method | Description |
|--------|-------------|
| `_buildStatusStats(items)` | Counts items by status — shared by all three stats methods |
| `_filterByThana(list, stationThana)` | Filters complaint rows by thana keyword matching |
| `_thanaKeywords(thana)` | Maps thana name → list of known locality keywords |

---

## 5.3 `EmergencyService`

**File**: `lib/common/data/services/emergency_service.dart`

Handles SOS alert lifecycle and admin notifications.

| Method | Returns | Description |
|--------|---------|-------------|
| `triggerSOS(lat, lng)` | `Future<EmergencyModel>` | Cancels any existing active SOS, creates a new one, notifies all admins |
| `updateEmergencyLocation(emergencyId, lat, lng)` | `Future<void>` | Updates GPS coordinates for a live SOS |
| `cancelEmergency(emergencyId)` | `Future<void>` | Marks SOS as cancelled, removes the 🚨 notification, sends a ✅ safe notification |
| `resolveEmergency(emergencyId, adminId)` | `Future<void>` | Admin marks the emergency as resolved |
| `watchActiveEmergencies()` | `Stream<List<EmergencyModel>>` | Real-time stream of all active SOS alerts with de-duplicated user profiles |
| `watchEmergency(emergencyId)` | `Stream<EmergencyModel?>` | Real-time stream of a single emergency with its citizen profile |

### Admin Notification Logic

`_notifyAdmins()` is a private helper that:
1. Fetches all profiles where `role == 'admin'`
2. Creates a `notifications` row for each admin with the given `title`, `message`, and `type`
3. Inserts all in a single batch for efficiency

---

## 5.4 `NotificationService`

**File**: `lib/common/data/services/notification_service.dart`

| Method | Returns | Description |
|--------|---------|-------------|
| `watchNotifications(userId)` | `Stream<List<NotificationModel>>` | Real-time stream of undeleted notifications for a user |
| `markRead(notificationId)` | `Future<void>` | Sets `is_read = true` |
| `markAllRead(userId)` | `Future<void>` | Marks all unread notifications read for a user |
| `deleteNotification(notificationId)` | `Future<void>` | Soft-deletes a notification |
| `getDeletedNotifications(userId)` | `Future<List<NotificationModel>>` | Fetches soft-deleted notifications (trash) |
| `restoreNotification(id)` | `Future<void>` | Restores from trash |
| `hardDeleteNotification(id)` | `Future<void>` | Permanently deletes |

---

## 5.5 `ProfileService`

**File**: `lib/common/data/services/profile_service.dart`

Admin-only user management operations.

| Method | Returns | Description |
|--------|---------|-------------|
| `getAllUsers()` | `Future<List<ProfileModel>>` | Fetches all user-role profiles |
| `verifyUser(userId)` | `Future<void>` | Sets `is_verified = true` |
| `unverifyUser(userId)` | `Future<void>` | Sets `is_verified = false` |
| `blockUser(userId)` | `Future<void>` | Sets `is_blocked = true` |
| `unblockUser(userId)` | `Future<void>` | Sets `is_blocked = false` |
| `promoteToAdmin(userId)` | `Future<void>` | Sets `role = 'admin'` |
| `deleteUser(userId)` | `Future<void>` | Calls `delete_user_account` RPC (removes auth + profile) |

---

## 5.6 `StorageService`

**File**: `lib/common/data/services/storage_service.dart`

Manages file uploads to Supabase Storage.

| Method | Returns | Description |
|--------|---------|-------------|
| `uploadEvidence(file, userId)` | `Future<String>` | Uploads a complaint evidence photo to the `evidence` bucket; returns the public URL |
| `uploadAvatar(file, userId)` | `Future<String>` | Uploads a profile photo to the `avatars` bucket; returns the public URL |
| `deleteFile(bucket, path)` | `Future<void>` | Deletes a file from the given bucket |

---

## 5.7 `MapService`

**File**: `lib/common/data/services/map_service.dart`

Handles external HTTP calls to the OpenStreetMap Nominatim API.

| Method | Returns | Description |
|--------|---------|-------------|
| `reverseGeocode(lat, lng)` | `Future<String?>` | Converts GPS coordinates to a human-readable address via Nominatim |
| `geocode(query)` | `Future<Map?>` | Converts an address query to coordinates via Nominatim |

---

## 5.8 `OfficerService`

**File**: `lib/common/data/services/officer_service.dart`

| Method | Returns | Description |
|--------|---------|-------------|
| `getOfficers({station})` | `Future<List<OfficerModel>>` | Fetches officers, optionally filtered by station |
| `addOfficer(data)` | `Future<void>` | Inserts a new officer record |
| `deleteOfficer(id)` | `Future<void>` | Deletes an officer record |

---

## 5.9 `MessageService`

**File**: `lib/common/data/services/message_service.dart`

Per-complaint chat between citizen and admin.

| Method | Returns | Description |
|--------|---------|-------------|
| `watchMessages(complaintId)` | `Stream<List<MessageModel>>` | Real-time chat stream for a complaint |
| `sendMessage({complaintId, content, isAdmin})` | `Future<void>` | Inserts a new message |

---

## 5.10 `SyncService`

**File**: `lib/common/data/services/sync_service.dart`

Singleton service for offline complaint queuing and cache management.

### Architecture

`SyncService` is a **singleton** (`SyncService._instance`). All reads/writes go through `SharedPreferences`.

### Storage Keys

| Key | Content |
|-----|---------|
| `offline_complaint_outbox` | `List<String>` — JSON-encoded pending complaint maps |
| `cached_user_complaints_<userId>` | `List<String>` — JSON-encoded cached complaint models |
| `cached_admin_complaints` | `List<String>` — JSON-encoded cached complaint models (admin) |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `cacheUserComplaints(userId, complaints)` | `Future<void>` | Saves the citizen's complaint list to local storage |
| `getCachedUserComplaints(userId)` | `Future<List<ComplaintModel>>` | Loads cached complaints (used when offline) |
| `cacheAdminComplaints(complaints)` | `Future<void>` | Saves the admin complaint list to local storage |
| `getCachedAdminComplaints()` | `Future<List<ComplaintModel>>` | Loads cached admin complaints |
| `addToOutbox(data)` | `Future<void>` | Adds an offline-pending complaint to the outbox and immediately adds it to the user cache with status `'offline_pending'` |
| `getOutboxCount()` | `Future<int>` | Returns how many complaints are awaiting sync |
| `syncOfflineOutbox()` | `Future<void>` | Tries to submit each outbox item to Supabase; keeps failures in the outbox |
| `filterComplaintsByThana(list, thana)` | `List<ComplaintModel>` | Locally filters a cached complaint list by thana keywords |

### Sync Flow

```
ConnectivityProvider detects internet restored
        │
        ▼
SyncService.syncOfflineOutbox() is called
        │
        ├── For each item in outbox:
        │       └── ComplaintService.submitComplaint(data)
        │               ├── SUCCESS → remove from outbox
        │               └── FAILURE → keep in outbox for next retry
        │
        └── Log result counts with debugPrint
```

---

*Next: [Part 6 — Providers (State Management)](PART_6_Providers.md)*
