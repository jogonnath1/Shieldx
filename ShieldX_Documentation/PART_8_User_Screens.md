# ShieldX — Full Project Documentation
## Part 8: Presentation — Citizen (User) Screens

Citizen screens live in `lib/presentation/user/`. They are only accessible to authenticated users with `role == 'user'`.

---

## 8.1 `HomeScreen`

**File**: `lib/presentation/user/home_screen.dart`  
**Route**: `/home`

The main citizen dashboard. The most feature-rich user screen.

**Sections**:
1. **Header** — Greeting with user name, avatar, and notification bell (with unread badge)
2. **SOS Button** — Prominent emergency button (uses `SOSButtonWidget`)
3. **Quick Actions** — Four cards: Submit Report, My Complaints, Police Map, Notifications
4. **Recent Complaints** — Last 3 submitted complaints with status chips
5. **Safety Tips** — Scrollable list of contextual tips

**State Dependencies**:
- `authNotifierProvider` — for user name/avatar
- `complaintProvider` — for recent complaints list
- `sosNotifierProvider` — for SOS button state
- `notificationProvider` — for unread count badge

**SOS Button Behavior** on HomeScreen:
- If `SOSStatus.idle` → shows pulsing red SOS button
- If `SOSStatus.countingDown` → shows countdown overlay with cancel option
- If `SOSStatus.active` → shows "I'm Safe" button + live GPS coordinates
- If `SOSStatus.error` → shows error snackbar + resets to idle

---

## 8.2 `SubmitComplaintScreen`

**File**: `lib/presentation/user/submit_complaint_screen.dart`  
**Route**: `/submit-complaint?anonymous=<bool>&station=<name>`

3-step complaint submission wizard.

**Query Parameters**:
- `anonymous=true` — pre-checks the anonymous submission option
- `station=<name>` — pre-fills the target police station

### Step 1: Personal Info (Personal Info Step)

Widget: `PersonalInfoStep` (`lib/presentation/widgets/user/personal_info_step.dart`)

| Field | Validation | Default |
|-------|-----------|---------|
| First Name | Required | From profile |
| Last Name | Required | From profile |
| Phone | BD phone format | From profile |
| NID | 10 or 17 digits (optional) | From profile |
| Profession | Optional | From profile |
| Present Address | Optional | From profile |
| Permanent Address | Optional | From profile |
| Anonymous Submission | Toggle | `false` |

### Step 2: Incident Details (Incident Step)

Widget: `IncidentStep` (`lib/presentation/widgets/user/incident_step.dart`)

| Field | UI | Notes |
|-------|-----|-------|
| Crime Category | Dropdown (14 options) | Auto-filled by classifier |
| Description | Multi-line text area | Triggers `ComplaintClassifier.classify()` after 500ms debounce |
| Incident Date/Time | Date + Time pickers | Defaults to now |
| Location | Map tap or "Use My Location" | OSM reverse geocoded → `locationAddress` |
| Police Station | Dropdown | 6 SMP stations |

**Auto-classification**: As the user types the description, `ComplaintClassifier.classify()` runs and suggests a category with confidence level. The user can accept or override the suggestion.

### Step 3: Evidence Upload (Evidence Step)

Widget: `EvidenceStep` (`lib/presentation/widgets/user/evidence_step.dart`)

- Photo picker (camera or gallery) via `image_picker`
- Up to 5 images
- Each selected image is uploaded to `StorageService.uploadEvidence()` before submission
- Preview grid with remove buttons

### Submission Flow

```
User taps "Submit Report" on Step 3
  │
  ├── If offline:
  │       → SyncService.addToOutbox(complaintData)
  │       → Shows "Saved Offline" snackbar
  │       → Navigator.pop()
  │
  └── If online:
          → ComplaintService.submitComplaint(complaintData)
          → Shows success dialog
          → Navigator.pop()
```

### Draft Auto-save

`PreferencesService.saveComplaintDraft()` is called on every step change. If the user leaves and returns, the draft is restored automatically.

---

## 8.3 `MyComplaintsScreen`

**File**: `lib/presentation/user/my_complaints_screen.dart`  
**Route**: `/my-complaints`

Paginated list of the citizen's own complaints.

**Features**:
- **Tab bar**: Active | Deleted (soft-deleted)
- **Filter bottom sheet**: Filter by status chip (all / submitted / in_progress / ...)
- **Search bar**: Client-side filter by case ID or description
- **Pull to refresh**
- **Offline indicator**: Shows cached data with a banner when offline
- Status color-coded chips on each card
- Tap → `/complaint/:id`

---

## 8.4 `ComplaintDetailScreen`

**File**: `lib/presentation/user/complaint_detail_screen.dart`  
**Route**: `/complaint/:id`

Shows full details of a single complaint.

**Sections**:
1. **Status Timeline** — Ordered list of `StatusHistoryModel` entries
2. **Incident Information** — Category, description, date/time, location
3. **Personal Information** — Complainant details (hidden if anonymous)
4. **Evidence Photos** — Tappable photo gallery with full-screen viewer
5. **Assigned Officer** — Officer name and badge number
6. **Action Buttons** — Edit (if `status == 'submitted'`), Chat

---

## 8.5 `EditComplaintScreen`

**File**: `lib/presentation/user/edit_complaint_screen.dart`  
**Route**: `/complaint/:id/edit`

Allows editing a complaint **only if** its status is still `'submitted'`. Pre-fills all fields from the existing `ComplaintModel`.

**Editable Fields**:
- Crime category, description, location, incident date/time
- Cannot change: user ID, evidence (add-only), anonymous status after submission

---

## 8.6 `PoliceStationsScreen`

**File**: `lib/presentation/user/police_stations_screen.dart`  
**Route**: `/police-stations`

Full-screen interactive map of Sylhet police stations.

**Map Features** (via `flutter_map` + OpenStreetMap):
- Shows all 6 SMP stations as custom marker pins
- User's GPS location marker with accuracy circle
- Tap marker → station info bottom sheet
  - Name, address, phone, email, office hours
  - "Report to This Station" button → `/submit-complaint?station=<name>`
  - "Get Directions" button → opens `url_launcher` with Google Maps deep link
- "Find Nearest Station" FAB → auto-selects closest station
- GPS simulation controls for demo mode

**Map Markers**:
- `StationMarkerWidget` — Custom map pin for each police station
- `GpsUserLocationMarker` — Pulsing blue dot for user location
- `UserLocationHighlightMarker` — Animated ring around the nearest station

---

## 8.7 `ProfileScreen`

**File**: `lib/presentation/user/profile_screen.dart`  
**Route**: `/profile`

Displays the citizen's full profile and account management options.

**Sections**:
1. **Avatar** — Circular avatar with initials fallback
2. **Profile Details** — Name, email, phone, NID, profession, addresses
3. **Verification Badge** — Shows green "Verified" or orange "Pending" status
4. **Account Actions**:
   - Edit Profile → `/edit-profile`
   - Change Password → `/change-password`
   - Change Email → `/change-email`
   - Sign Out → `authNotifierProvider.notifier.signOut()`

---

## 8.8 `EditProfileScreen`

**File**: `lib/presentation/user/edit_profile_screen.dart`  
**Route**: `/edit-profile`

Allows editing all profile fields except email (which has its own dedicated screen).

| Field | Editable |
|-------|---------|
| Name | ✅ |
| Phone | ✅ |
| NID | ✅ |
| Profession | ✅ |
| Present Address | ✅ |
| Permanent Address | ✅ |
| Avatar Photo | ✅ (uploads via `StorageService.uploadAvatar()`) |

---

## 8.9 `ChangePasswordScreen`

**File**: `lib/presentation/user/change_password_screen.dart`  
**Route**: `/change-password`

Simple form: Current password (for re-authentication), new password, confirm new password.

Calls `AuthService.updatePassword(newPassword)` and shows a success snackbar.

---

## 8.10 `ChangeEmailScreen`

**File**: `lib/presentation/user/change_email_screen.dart`  
**Route**: `/change-email`

Two-step email change with OTP verification:

1. Enter new email → `AuthService.updateEmail(newEmail)` (sends OTP to new email)
2. Enter 6-digit OTP → `AuthService.verifyEmailChangeOtp(newEmail, token)`

---

## 8.11 `ChatScreen`

**File**: `lib/presentation/user/chat_screen.dart`  
**Route**: `/chat/:complaintId`

Per-complaint real-time chat between citizen and admin.

**Features**:
- Bubble UI (citizen on right, admin on left)
- Real-time via `chatProvider` (StreamProvider watching `MessageService.watchMessages()`)
- Text input at bottom with send button
- Auto-scrolls to newest message
- Admin messages show "Police Admin" as sender name

---

*Next: [Part 9 — Presentation: Admin Screens](PART_9_Admin_Screens.md)*
