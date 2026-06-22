# Academic Defense Review - Part 2: Database & Requirements Validation

**Reviewer:** Senior Software Engineering Professor
**Project:** ShieldX – Crime Reporting Management System

This document provides a strict academic evaluation of the database design, requirements engineering, and technical methodology presented in the project report.

---

## 1. Database Consistency Review

### Academic Critique
- **Cross-Check Match:** The report lists 7 primary Supabase tables (`profiles`, `complaints`, `emergencies`, `notifications`, `status_history`, `officers`, `messages`). This perfectly maps to the 7 backend data models implemented in the codebase.
- **Issue 1 - Normalization (Location Data):**
  - *Observation:* The `complaints` table stores `latitude` and `longitude` directly as `double precision`.
  - *Academic Concern:* While functional, an examiner might ask why spatial indexing (e.g., PostGIS) wasn't used for coordinate data, given that the system requires "nearest police station" proximity calculations.
- **Issue 2 - Enum Usage:**
  - *Observation:* The `status` field in `complaints` is treated as a plain string in Dart and likely `text` or `varchar` in PostgreSQL.
  - *Academic Concern:* Best practices dictate using a Postgres `ENUM` type (e.g., `'pending', 'investigating', 'resolved', 'closed'`) to prevent data insertion anomalies.

### Corrected Consistency Advice
Be prepared to defend the choice of using plain coordinate doubles instead of PostGIS due to "project scope constraints" and "simplicity of distance calculation in Dart using the `latlong2` package."

---

## 2. Functional Requirements (FR) Validation

### Academic Critique
- **FR: Offline Support**
  - *Observation:* The report claims offline functionality.
  - *Validation:* The codebase implements a `SyncService` that queues data in `SharedPreferences` and uses a `Timer` with an HTTP ping (`connectivity_provider.dart`) to sync later.
  - *Conclusion:* Technically sound. The implementation perfectly backs the claim.
- **FR: Real-time Communication**
  - *Observation:* Claims real-time admin dashboards and chat.
  - *Validation:* Supabase Realtime subscriptions (`.stream()`) are explicitly implemented in `allComplaintsStreamProvider` and `NotificationProvider`.
  - *Conclusion:* Verified and valid.

---

## 3. Non-Functional Requirements (NFR) Validation

### Academic Critique
- **NFR: 99.9% Availability**
  - *Academic Concern:* A common mistake in student projects is blindly claiming 99.9% or 99.99% uptime.
  - *Flagged Issue:* Unless you are paying for an Enterprise Supabase tier with SLAs, the free/pro tier does not strictly guarantee 99.99% uptime.
  - *Defense Recommendation:* During viva, if questioned, state: "The system inherits the high-availability architecture of AWS/Supabase cloud infrastructure, but SLA guarantees are tied to the cloud provider's tier."
- **NFR: Security**
  - *Observation:* Mentions "secure authentication."
  - *Validation:* Verified by the use of Supabase Auth (JWT + PKCE) and Row Level Security (RLS). RLS physically blocks unauthorized data access at the database level, which is an excellent architectural defense point.

---

## 4. Methodology Review

### Academic Critique
- **Issue:** Software Development Life Cycle (SDLC) justification.
- **Academic Concern:** Students often declare "Agile" without proof.
- **Defense Advice:** If asked "How did you use Agile?", you must point to the *iterative development* of ShieldX: "We first built the core Auth module, tested it, then built the Complaint module, and finally integrated the Realtime Admin dashboard, refining the GPS feature iteratively based on field testing."
