# ShieldX — Full Project Documentation
## Part 17: System Requirements Specification (SRS) & Use Cases

---

## 17.1 Introduction

This document outlines the System Requirements Specification (SRS) and details the primary Use Cases for the ShieldX Crime Reporting Portal. This serves as a formal requirement analysis standard for academic defense and project evaluation.

---

## 17.2 Actor Definitions

| Actor | Description |
|-------|-------------|
| **Citizen (User)** | A member of the public who uses the mobile application to report crimes, trigger emergencies, and track their case status. Must register with phone and NID. |
| **Police Admin** | Law enforcement personnel who monitor incoming complaints, dispatch officers, analyze crime data, and manage citizen accounts. |
| **System** | The automated backend infrastructure (Supabase) that processes location data, categorizes crimes, and dispatches real-time notifications. |

---

## 17.3 Functional Requirements (FR)

### Citizen Functional Requirements
- **FR1.1**: The system must allow users to register using Email, Phone Number, and National ID (NID).
- **FR1.2**: Users must be able to submit a complaint with a description, crime category, location (GPS), and multimedia evidence (photos).
- **FR1.3**: Users must be able to trigger an SOS alert that broadcasts their live GPS coordinates to the police dashboard.
- **FR1.4**: Users must be able to view a history of their submitted complaints and check their real-time status.
- **FR1.5**: Users must be able to locate nearby police stations on an interactive map.

### Admin Functional Requirements
- **FR2.1**: Admins must have access to a dashboard displaying real-time statistics, pie charts, and a geographical heatmap of crimes.
- **FR2.2**: Admins must be able to view, update the status of, and assign field officers to incoming complaints.
- **FR2.3**: Admins must receive instantaneous visual and auditory alerts when a citizen triggers an SOS.
- **FR2.4**: Admins must be able to manage user accounts (verify, block, or delete).
- **FR2.5**: Admins must be able to filter data by specific Police Stations (Thanas).

---

## 17.4 Non-Functional Requirements (NFR)

- **NFR1 (Performance)**: The system must reflect new complaints and SOS alerts on the admin dashboard within 2 seconds of submission (real-time sync).
- **NFR2 (Security)**: All database queries must be protected by Row Level Security (RLS). Citizens must never be able to access other citizens' complaints.
- **NFR3 (Reliability/Offline)**: If a citizen loses internet connection while drafting a complaint, the system must queue the complaint locally and sync it automatically upon reconnection.
- **NFR4 (Usability)**: The user interface must be accessible, following modern material design standards, with intuitive form steps for stressed users.

---

## 17.5 System Use Cases

### UC1: Submit Crime Complaint
- **Primary Actor**: Citizen
- **Precondition**: User is authenticated.
- **Main Flow**:
  1. User navigates to "Submit Complaint".
  2. User enters personal info (or chooses anonymous).
  3. User enters incident details. System auto-categorizes based on keywords.
  4. User captures or uploads evidence.
  5. User submits. System saves data and alerts admin.
- **Postcondition**: Complaint is stored in database with 'submitted' status.

### UC2: Trigger SOS Emergency
- **Primary Actor**: Citizen
- **Precondition**: User is authenticated and grants GPS permissions.
- **Main Flow**:
  1. User long-presses the SOS button.
  2. A 3-second cancellation countdown begins.
  3. If not cancelled, system captures GPS coordinates and creates an `emergencies` record.
  4. Admin dashboard instantly flags the alert and displays the live location.
- **Postcondition**: Active emergency broadcast is initiated.

### UC3: Manage Complaint Status
- **Primary Actor**: Police Admin
- **Precondition**: Admin is authenticated with `role = 'admin'`.
- **Main Flow**:
  1. Admin navigates to the Complaints Panel.
  2. Admin selects a newly submitted complaint.
  3. Admin reviews evidence and location.
  4. Admin assigns an officer and updates status to `in_progress`.
  5. System sends push notification to the citizen.
- **Postcondition**: Complaint status is updated, and audit log (`status_history`) is created.

### UC4: Review Analytics Dashboard
- **Primary Actor**: Police Admin
- **Precondition**: Admin is authenticated.
- **Main Flow**:
  1. Admin opens the app and lands on the Dashboard.
  2. System fetches aggregated data for the current month.
  3. Admin views breakdown by crime category (Pie Chart) and geographic heatmap.
  4. Admin uses the Station Switcher to filter data for a specific Thana (e.g., Kotwali).
- **Postcondition**: Admin gains situational awareness for resource deployment.

---

*Return to [Index — Table of Contents](INDEX.md)*
