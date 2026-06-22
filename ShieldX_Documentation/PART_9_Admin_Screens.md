# ShieldX — Full Project Documentation
## Part 9: Presentation — Admin Screens

Admin screens live in `lib/presentation/admin/`. They are protected by both the GoRouter redirect (role check) and Supabase Row Level Security policies.

---

## 9.1 `AdminShell`

**File**: `lib/presentation/admin/admin_shell.dart`

The `ShellRoute` wrapper that provides the persistent bottom navigation bar for all admin tab screens.

**Bottom Navigation Tabs**:

| Index | Icon | Label | Route |
|-------|------|-------|-------|
| 0 | Dashboard icon | Dashboard | `/admin/dashboard` |
| 1 | List icon | Complaints | `/admin/complaints` |
| 2 | People icon | Users | `/admin/users` |
| 3 | Shield icon | Officers | `/admin/officers` |
| 4 | Person icon | Profile | `/admin/profile` |

The shell also embeds `AdminSOSAlertWidget` as a persistent floating overlay on top of all admin screens — so SOS alerts are always visible regardless of which tab is active.

---

## 9.2 `AdminDashboardScreen`

**File**: `lib/presentation/admin/admin_dashboard_screen.dart`  
**Route**: `/admin/dashboard`

The most data-rich screen in the app.

**Components**:

### Top Bar
- Station switcher dropdown (see `StationSwitcherWidget`)
- Notification bell with unread count
- Admin name + avatar

### Summary Stats Row
Four cards showing counts:
- Total Complaints
- Submitted (new)
- In Progress
- Resolved

### Status Distribution Chart
A `fl_chart` pie chart showing the proportion of each status across all complaints (or filtered by station).

### Crime Category Bar Chart
Top 7 crime categories by complaint count for the selected station.

### Monthly Trend Line Chart
Complaints per month over the past 6 months.

### Crime Heatmap
A `flutter_map` view with complaint GPS coordinates rendered as colored dots, giving visual hotspot identification per thana.

### Active SOS Alerts Summary
Count of live SOS alerts with a link to the SOS panel.

**State Dependencies**:
- `selectedStationProvider` — which thana is currently selected
- `allComplaintsStreamProvider` — the full complaint stream for stats computation
- `adminSosProvider` — active emergencies count

---

## 9.3 `AdminComplaintsScreen`

**File**: `lib/presentation/admin/admin_complaints_screen.dart`  
**Route**: `/admin/complaints`

Full complaint management list for admins.

**Features**:
- **Search bar** — full-text search by case ID, description, category, or user name
- **Status filter tabs** — All, Submitted, In Progress, Under Investigation, Resolved, Closed, Rejected
- **Bulk selection mode** — long-press to enter selection mode; select multiple for bulk-delete or bulk-status-update
- **Sort options** — newest first / oldest first / by status
- **Station filter** — filter by thana using `selectedStationProvider`
- **Soft-delete tab** — view and restore or permanently delete soft-deleted complaints
- **Swipe to delete** on individual complaint cards

**Each Complaint Card Shows**:
- Case ID badge
- Crime category chip
- Status badge (color-coded)
- Complainant name (or "Anonymous")
- Date submitted
- Police station name
- Assigned officer (if any)

**Tap → `/admin/complaints/:id`** for detailed management.

---

## 9.4 `AdminComplaintDetailScreen`

**File**: `lib/presentation/admin/admin_complaint_detail_screen.dart`  
**Route**: `/admin/complaints/:id`

Full complaint detail and management panel for admins.

**Sections**:
1. **Header** — Case ID, status chip, date submitted
2. **Status Management**:
   - Dropdown to change status to any valid next state
   - Optional text note field for the change
   - Assign officer dropdown (populated from `officerProvider`)
   - "Update Status" button
3. **Complainant Details** — Full personal info (shown even for anonymous reports)
4. **Incident Information** — Category, description, date/time, GPS + map preview
5. **Evidence Gallery** — Full-size viewable photos
6. **Status History Timeline** — Chronological list of all status changes with notes
7. **Chat** — Link to the per-complaint chat room

---

## 9.5 `AdminUsersScreen`

**File**: `lib/presentation/admin/admin_users_screen.dart`  
**Route**: `/admin/users`

Full citizen account management.

**List Features**:
- Search by name, email, or phone
- Filter tabs: All | Verified | Unverified | Blocked
- Each user card shows: name, email, phone, NID, verification + block status badges

**Per-User Actions** (swipe or tap menu):

| Action | Condition | Description |
|--------|-----------|-------------|
| Verify | `!isVerified && !isBlocked` | Sets `is_verified = true`; allows SOS |
| Unverify | `isVerified` | Revokes verified status |
| Block | `!isBlocked && !isMainAdmin` | Sets `is_blocked = true`; kicks user immediately |
| Unblock | `isBlocked` | Restores account access |
| Promote to Admin | `!isAdmin && !isMainAdmin` | Sets `role = 'admin'` |
| Delete | `!isMainAdmin` | Calls `delete_user_account` RPC |
| View Profile | Always | Opens `UserProfileDialog` |

**Real-time Effects**: Blocking/verifying a user is picked up instantly by the citizen's running app via Supabase Realtime.

---

## 9.6 `AdminOfficersScreen`

**File**: `lib/presentation/admin/admin_officers_screen.dart`  
**Route**: `/admin/officers`

Manage the field officer roster.

**Features**:
- List of all officers with name, rank, badge number, station, phone, active status
- **Add Officer** FAB → opens a bottom sheet form:
  - Name (required), Badge Number, Rank, Station (dropdown), Phone
- **Toggle Active** — enables/disables officer for assignment
- **Delete** officer with confirmation dialog
- Officers appear in the assignment dropdown in `AdminComplaintDetailScreen`

---

## 9.7 `AdminStationsScreen`

**File**: `lib/presentation/admin/admin_stations_screen.dart`  
**Route**: `/admin/stations`

Per-station statistics and overview.

**Features**:
- 6 station cards (one per SMP thana)
- Each card shows: station name, address, phone, total complaints, breakdown by status
- Tap → detailed station view with a map and bar chart
- "View All Complaints" button → navigates to `/admin/complaints` pre-filtered by thana

---

## 9.8 `AdminProfileScreen`

**File**: `lib/presentation/admin/admin_profile_screen.dart`  
**Route**: `/admin/profile`

Admin's own profile and settings.

**Sections**:
1. **Profile Info** — Avatar, name, email, role badge, verification status
2. **Edit Profile** → same `EditProfileScreen` as citizens
3. **Change Password** → `ChangePasswordScreen`
4. **Change Email** → `ChangeEmailScreen`
5. **App Settings** — GPS Simulation toggle (dev tool), version info
6. **Sign Out** button

---

## 9.9 `AdminSOSAlertWidget`

**File**: `lib/presentation/admin/admin_sos_alert_widget.dart`

A floating widget that appears over all admin screens when one or more SOS alerts are active. It is part of `AdminShell` and always visible.

**States**:
- **No active SOS** → hidden (zero height)
- **Active SOS** → expands from top of screen as a dismissible banner

**Active SOS Panel Content**:
- Alert count badge
- For each active emergency:
  - Citizen name, phone
  - GPS coordinates (lat/lng)
  - Time since alert
  - "View on Map" button → opens Google Maps at the citizen's location
  - "Mark Resolved" button → calls `EmergencyService.resolveEmergency()`

**State**: `adminSosProvider` — `StreamProvider` watching `EmergencyService.watchActiveEmergencies()`

---

## 9.10 `StationSwitcherWidget`

**File**: `lib/presentation/widgets/admin/station_switcher_widget.dart`

A reusable dropdown widget embedded in the dashboard and complaints screens. Allows switching the data view between:
- **All Stations** (global stats)
- Any one of the 6 specific thanas

Updates `selectedStationProvider` which is watched by stats-computing providers.

---

*Next: [Part 10 — Widgets & Shared Components](PART_10_Widgets.md)*
