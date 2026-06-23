# ShieldX — Full Project Documentation
## Part 10: Shared Widgets & Common Screens

---

## 10.1 Common Widgets

Located in `lib/common/presentation/widgets/common/`.

---

### 10.1.1 `SOSButtonWidget`

**File**: `lib/common/presentation/widgets/common/sos_button_widget.dart`

The most critical widget in the app. A stateful, animated emergency button.

**Visual States**:

| `SOSStatus` | Appearance |
|-------------|------------|
| `idle` | Pulsing red circular button with "SOS" label. Outer ring animates. |
| `countingDown` | Overlaid countdown (3, 2, 1) with "Cancel" button. Animated ring contracts. |
| `active` | Changes to a green "I'm Safe" button. Shows live GPS coordinates below. |
| `error` | Red error message shown; auto-resets to idle after 3 seconds. |

**Props**:
- `showCoordinates: bool` — whether to display live lat/lng below the button

**Interactions**:
- Tap (idle) → `sosNotifierProvider.notifier.startSOS()`
- Tap (countingDown) → `cancelSOSCountdown()`
- Tap (active) → `markSafe()`

---

### 10.1.2 `GlobalOfflineBanner`

**File**: `lib/common/presentation/widgets/common/global_offline_banner.dart`

An `AnimatedSlide` banner that appears at the top of the screen when `connectivityProvider` returns `false`.

- Slides in from the top with a 300ms animation
- Shows "No Internet Connection" + pending outbox count
- Slides out automatically when connectivity is restored

---

### 10.1.3 `NoInternetScreen`

**File**: `lib/common/presentation/widgets/common/no_internet_screen.dart`

A full-screen placeholder shown when a feature requires internet and none is available.

- Displays a "No Connection" illustration + message
- Shows a "Try Again" button

---

### 10.1.4 `UserProfileDialog`

**File**: `lib/common/presentation/widgets/common/user_profile_dialog.dart`

A modal bottom sheet that shows a complete citizen profile for admin review.

**Displays**:
- Avatar + name + email
- Phone, NID, profession, addresses
- Verification status + block status badges
- Complaint count for this user
- Action buttons: Verify / Block / View Complaints

---

### 10.1.5 `widgets.dart`

**File**: `lib/common/presentation/widgets/common/widgets.dart`

Barrel file exporting all common reusable widget components:
- `CustomTextField` — Styled text input with consistent border/color
- `CustomButton` — Primary action button with loading state
- `CustomCard` — Styled card container with `AppColors.card` background
- `StatusBadge` — Color-coded status chip
- `SectionHeader` — Section title with optional action button
- `LoadingShimmer` — Shimmer placeholder cards for loading states
- `EmptyState` — Empty list / no data illustration widget
- `ConfirmationDialog` — Reusable confirm/cancel dialog
- `AvatarWidget` — Circular avatar with initials fallback

---

### 10.1.6 `EvidenceItemWidget`

**File**: `lib/common/presentation/widgets/common/evidence_item_widget.dart`

A reusable widget to display a single piece of evidence (image or file) in grids. Includes remove functionality and upload progress indication.

---

## 10.2 User Widgets

Located in `lib/common/presentation/widgets/user/`.

---

### 10.2.1 `PersonalInfoStep`

Form step widget for the complaint submission wizard — Step 1.

Manages all personal information fields with pre-filling from the user's profile and validation via `AppValidators`.

---

### 10.2.2 `IncidentStep`

Form step widget — Step 2.

Contains:
- Crime category dropdown with auto-classification chip
- Description text area with character counter
- Date/time pickers
- Embedded mini-map for location selection (tap-to-pin on flutter_map)
- "Use Current Location" button with GPS fallback chain
- Police station dropdown

---

### 10.2.3 `EvidenceStep`

Form step widget — Step 3.

- Grid of picked images (up to 5)
- Camera / Gallery picker bottom sheet
- Remove button on each image
- Progress indicator during upload

---

### 10.2.4 `FilterBottomSheetContent`

**File**: `lib/common/presentation/widgets/user/filter_bottom_sheet_content.dart`

A draggable bottom sheet for filtering the MyComplaintsScreen:

- Status filter chips (multiple-select)
- Date range picker
- Sort order selection (newest/oldest/status)
- "Apply" and "Reset" buttons

---

### 10.2.5 `FilterChipWidget`

**File**: `lib/common/presentation/widgets/user/filter_chip_widget.dart`

A simple `FilterChip` wrapper with `AppColors` styling — used in both the filter sheet and the admin complaints screen.

---

### 10.2.6 `StationMarkerWidget`

**File**: `lib/common/presentation/widgets/user/station_marker_widget.dart`

A custom `flutter_map` marker for police station pins.

Displays a shield icon with the station name below. When selected (nearest station), it scales up with an animation.

---

### 10.2.7 `GpsUserLocationMarker`

**File**: `lib/common/presentation/widgets/user/gps_user_location_marker.dart`

A custom `flutter_map` marker for the user's current GPS position.

Shows a pulsing blue dot (similar to Google Maps) with an accuracy radius circle.

---

### 10.2.8 `UserLocationHighlightMarker`

**File**: `lib/common/presentation/widgets/user/user_location_highlight_marker.dart`

A special animated marker that places a pulsing ring around the closest station to the user, helping them identify which station to report to.

---

### 10.2.9 `QuickActionCard`

**File**: `lib/common/presentation/widgets/user/quick_action_card.dart`

A tappable card used in the HomeScreen quick actions grid.

Props: `icon`, `label`, `color`, `onTap`.

---

### 10.2.10 `RecentComplaintCard`

**File**: `lib/common/presentation/widgets/user/recent_complaint_card.dart`

A compact complaint summary card for the HomeScreen "Recent Complaints" section.

Shows: case ID, category icon, status badge, and relative time.

---

### 10.2.11 `DeletedComplaintCard`

**File**: `lib/common/presentation/widgets/user/deleted_complaint_card.dart`

A complaint card variant for the "Deleted" tab in MyComplaintsScreen.

Shows: deletion date, restore button, permanent-delete button.

---

### 10.2.12 `DeletedNotificationCard`

**File**: `lib/common/presentation/widgets/user/deleted_notification_card.dart`

A notification card variant for the trash view in NotificationsScreen.

Shows: notification content, deletion date, restore and permanent-delete buttons.

---

## 10.3 Common Screen — `NotificationsScreen`

**File**: `lib/common/presentation/common/notifications_screen.dart`  
**Route**: `/notifications`  
**Access**: Both citizens and admins

Full notification inbox with tabs and management features.

**Tabs**:
- **Inbox** — Unread and read notifications
- **Deleted** — Soft-deleted (trash)

**Features**:
- Mark all as read button
- Individual notification tap → navigates to relevant complaint or SOS
- Swipe to delete → soft-deletes with undo snackbar
- In Deleted tab: restore or permanently delete
- Notification type icons: 📋 complaint, 🚨 SOS, ℹ️ system
- Relative timestamps ("2 minutes ago", "Yesterday")

**Real-time**: `notificationProvider` streams new notifications as they arrive from Supabase Realtime.

---

*Next: [Part 11 — App Entry Point & Startup](PART_11_Startup.md)*
