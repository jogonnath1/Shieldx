# ShieldX — Full Project Documentation
## Part 12: Database Schema & Security

---

## 12.1 Database Overview

ShieldX uses **Supabase** (managed PostgreSQL) as its backend. The database consists of 8 tables, all with **Row Level Security (RLS)** enabled.

---

## 12.2 Table Schemas

### `profiles`

Extends Supabase Auth's `auth.users` table with application-specific data.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `uuid` | PK, FK → `auth.users.id` | User UUID |
| `name` | `text` | — | Full display name |
| `phone` | `text` | UNIQUE | BD mobile number |
| `nid` | `text` | UNIQUE | National ID |
| `profession` | `text` | — | User occupation |
| `present_address` | `text` | — | Current residence |
| `permanent_address` | `text` | — | Permanent residence |
| `avatar_url` | `text` | — | Supabase Storage URL |
| `role` | `text` | DEFAULT `'user'` | `'user'` or `'admin'` |
| `is_verified` | `bool` | DEFAULT `false` | Admin-verified citizen |
| `is_blocked` | `bool` | DEFAULT `false` | Blocked by admin |
| `is_main_admin` | `bool` | DEFAULT `false` | Protected main admin flag |
| `fcm_token` | `text` | — | Push notification token |
| `created_at` | `timestamptz` | DEFAULT `now()` | Account creation time |

**RLS Policies**:
- Users can only SELECT/UPDATE their own row (`id = auth.uid()`)
- Admins can SELECT all rows and UPDATE `is_verified`, `is_blocked`, `role` on any user's row
- INSERT is handled by a trigger on `auth.users`

---

### `complaints`

The central table. Stores every crime report.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` | Complaint UUID |
| `user_id` | `uuid` | FK → `profiles.id` (nullable) | Reporter (null for anonymous) |
| `first_name` | `text` | — | Complainant first name |
| `last_name` | `text` | — | Complainant last name |
| `phone` | `text` | — | Complainant phone |
| `nid` | `text` | — | Complainant NID |
| `profession` | `text` | — | Complainant profession |
| `present_address` | `text` | — | Complainant address |
| `permanent_address` | `text` | — | Complainant permanent address |
| `crime_category` | `text` | — | One of 14 categories |
| `description` | `text` | — | Incident description |
| `latitude` | `float8` | — | Incident GPS latitude |
| `longitude` | `float8` | — | Incident GPS longitude |
| `location_address` | `text` | — | Reverse-geocoded address |
| `incident_datetime` | `timestamptz` | — | When incident occurred |
| `status` | `text` | DEFAULT `'submitted'` | Current status |
| `assigned_officer_id` | `uuid` | FK → `officers.id` (nullable) | Assigned officer |
| `evidence_urls` | `text[]` | DEFAULT `'{}'` | Array of Storage URLs |
| `is_anonymous` | `bool` | DEFAULT `false` | Anonymous report flag |
| `police_station` | `text` | — | Target thana name |
| `created_at` | `timestamptz` | DEFAULT `now()` | Submission timestamp |
| `updated_at` | `timestamptz` | — | Last update timestamp |
| `deleted_at` | `timestamptz` | — | Soft-delete timestamp (NULL = active) |

**RLS Policies**:
- Users can SELECT their own complaints (`user_id = auth.uid()`)
- Users can INSERT new complaints
- Users can UPDATE their own complaints where `status = 'submitted'`
- Admins can SELECT, UPDATE (status, assignment), and soft-delete all complaints

---

### `status_history`

Audit log for all complaint status transitions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `uuid` | PK | Entry UUID |
| `complaint_id` | `uuid` | FK → `complaints.id` | Related complaint |
| `status` | `text` | NOT NULL | New status value |
| `note` | `text` | — | Admin's change note |
| `changed_by` | `uuid` | FK → `profiles.id` (nullable) | Admin who made the change |
| `changed_at` | `timestamptz` | DEFAULT `now()` | Timestamp |

**RLS Policies**:
- Users can SELECT history for their own complaints
- Admins can SELECT all + INSERT

---

### `emergencies`

Active SOS alert records with live GPS coordinates.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `uuid` | PK | Emergency UUID |
| `user_id` | `uuid` | FK → `profiles.id` | Citizen who triggered SOS |
| `latitude` | `float8` | NOT NULL | Current GPS latitude |
| `longitude` | `float8` | NOT NULL | Current GPS longitude |
| `status` | `text` | DEFAULT `'active'` | `'active'`, `'resolved'`, `'cancelled'` |
| `created_at` | `timestamptz` | DEFAULT `now()` | Alert trigger time |
| `resolved_at` | `timestamptz` | — | Time resolved/cancelled |
| `resolved_by` | `uuid` | FK → `profiles.id` (nullable) | Admin who resolved it |

**RLS Policies**:
- Users can INSERT their own emergencies and UPDATE their own active ones (for live location)
- Admins can SELECT all and UPDATE status to `'resolved'`

---

### `notifications`

Per-user notification inbox.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `uuid` | PK | Notification UUID |
| `user_id` | `uuid` | FK → `profiles.id` | Recipient |
| `title` | `text` | NOT NULL | Notification heading |
| `message` | `text` | NOT NULL | Notification body |
| `type` | `text` | DEFAULT `'system'` | `'complaint'`, `'sos'`, `'system'` |
| `related_id` | `uuid` | — | FK to complaint or emergency |
| `is_read` | `bool` | DEFAULT `false` | Read status |
| `created_at` | `timestamptz` | DEFAULT `now()` | Creation time |
| `deleted_at` | `timestamptz` | — | Soft-delete timestamp |

**RLS Policies**:
- Users can only SELECT/UPDATE/DELETE their own notifications
- Admins and system (via service role) can INSERT notifications for any user

---

### `phone_verifications`

Demo OTP storage for phone verification (replaces real SMS in development).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `phone` | `text` | PK | Phone number |
| `otp` | `text` | NOT NULL | 6-digit OTP code |
| `created_at` | `timestamptz` | DEFAULT `now()` | OTP generation time |

**RLS Policies**:
- Users can INSERT/UPDATE their own phone OTP
- Users can SELECT to verify

---

### `officers`

Field officer roster for complaint assignment.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `uuid` | PK | Officer UUID |
| `name` | `text` | NOT NULL | Officer full name |
| `badge_number` | `text` | — | Service badge number |
| `rank` | `text` | — | Officer rank |
| `station` | `text` | — | Assigned police station |
| `phone` | `text` | — | Contact number |
| `is_active` | `bool` | DEFAULT `true` | Active/inactive status |
| `created_at` | `timestamptz` | DEFAULT `now()` | Record creation time |

**RLS Policies**:
- Users can SELECT (for viewing assigned officer)
- Only admins can INSERT, UPDATE, DELETE

---

### `messages`

Per-complaint chat messages between citizens and admins.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `uuid` | PK | Message UUID |
| `complaint_id` | `uuid` | FK → `complaints.id` | Thread identifier |
| `sender_id` | `uuid` | FK → `profiles.id` | Message author |
| `content` | `text` | NOT NULL | Message body |
| `created_at` | `timestamptz` | DEFAULT `now()` | Send time |
| `is_admin` | `bool` | DEFAULT `false` | Sender role flag |

**RLS Policies**:
- Users can SELECT/INSERT for complaints they own
- Admins can SELECT/INSERT for any complaint

---

## 12.3 Supabase Realtime Configuration

The following tables have Realtime publication enabled:

| Table | Events Published | Used By |
|-------|-----------------|---------|
| `profiles` | UPDATE | `AuthNotifier._setupProfileSubscription()` |
| `complaints` | INSERT, UPDATE, DELETE | `watchUserComplaints()`, `watchAllComplaints()` |
| `emergencies` | INSERT, UPDATE | `watchActiveEmergencies()`, `watchEmergency()` |
| `notifications` | INSERT, UPDATE, DELETE | `NotificationNotifier.watchNotifications()` |
| `messages` | INSERT | `chatProvider` |

---

## 12.4 Security Architecture Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Security Layers                               │
│                                                                     │
│  Layer 1: Flutter GoRouter                                          │
│  → redirect() checks auth state and role before every navigation   │
│  → Blocked users are forced to /blocked                            │
│  → Admin routes (/admin/*) reject non-admin users                  │
│                                                                     │
│  Layer 2: Supabase Auth JWT                                         │
│  → Every API call from the client carries a signed JWT              │
│  → Supabase validates the JWT on every request                     │
│  → Expired sessions trigger a redirect to /login                   │
│                                                                     │
│  Layer 3: Row Level Security (RLS)                                  │
│  → Citizens: can only see/modify their own rows                     │
│  → Admins: can see all rows; can modify status fields               │
│  → Anonymous users: can only INSERT complaints (no SELECT)          │
│                                                                     │
│  Layer 4: Database RPC Functions                                    │
│  → Sensitive operations (delete account, check block) run as       │
│    server-side functions with elevated privileges                   │
│  → Never exposed directly via table access from the client          │
└─────────────────────────────────────────────────────────────────────┘
```

---

*Next: [Part 13 — Testing & Quality](PART_13_Testing.md)*
