# ShieldX — Full Project Documentation
## Part 18: System Diagrams

---

## 18.1 Introduction

Visual representations of system processes are essential for academic defense to demonstrate the flow of data and control. This section contains architectural and behavioral diagrams using standard modeling techniques.

---

## 18.2 System Architecture Diagram

```mermaid
graph TD
    subgraph Client Application (Flutter)
        UI[User Interface]
        State[Riverpod State Management]
        Local[SharedPreferences / Offline Queue]
        
        UI <--> State
        State <--> Local
    end

    subgraph Backend Services (Supabase)
        Auth[Supabase Auth]
        DB[(PostgreSQL Database)]
        Storage[Supabase Storage]
        Realtime[Realtime Subscriptions]
    end

    State -- JWT Token --> Auth
    State -- REST API --> DB
    State -- WebSocket --> Realtime
    State -- Multipart Upload --> Storage
    
    DB -. Change Events .-> Realtime
```

---

## 18.3 Data Flow Diagram (DFD) - Level 0 (Context Diagram)

```mermaid
graph LR
    Citizen((Citizen))
    Admin((Police Admin))
    System[ShieldX System]
    
    Citizen -- Submit Complaint / SOS --> System
    Citizen -- Profile Updates --> System
    System -- Status Notifications --> Citizen
    System -- Auth Responses --> Citizen
    
    System -- Live Crime Data & SOS --> Admin
    Admin -- Status Updates & Officer Assignment --> System
    Admin -- User Management --> System
```

---

## 18.4 Sequence Diagram: Submit a Complaint

```mermaid
sequenceDiagram
    actor User as Citizen
    participant App as Flutter App
    participant Auth as Supabase Auth
    participant DB as Supabase DB
    participant Storage as Supabase Storage
    participant Admin as Admin Dashboard

    User->>App: Enter Complaint Details
    App->>Auth: Check Authentication Status
    Auth-->>App: Valid JWT
    
    opt Has Evidence Photos
        App->>Storage: Upload Photos
        Storage-->>App: Return Image URLs
    end
    
    App->>DB: INSERT into 'complaints' table
    DB-->>App: Return success
    App-->>User: Show success message
    
    DB-->>Admin: Realtime Event (INSERT complaint)
    Admin-->>Admin: Update Dashboard UI
```

---

## 18.5 Sequence Diagram: SOS Emergency Alert

```mermaid
sequenceDiagram
    actor Citizen
    participant App as Flutter App
    participant DB as Supabase DB
    participant AdminApp as Admin Dashboard

    Citizen->>App: Long Press SOS Button
    App->>App: 3-Second Countdown
    
    opt Citizen does not cancel
        App->>App: Fetch GPS Coordinates
        App->>DB: INSERT into 'emergencies'
        DB-->>AdminApp: Realtime Broadcast (SOS Alert)
        AdminApp->>AdminApp: Trigger Alarm & Show Location
        
        loop Every 10 seconds
            App->>DB: UPDATE 'emergencies' with new GPS
            DB-->>AdminApp: Realtime Broadcast (Location Change)
            AdminApp->>AdminApp: Move Marker on Map
        end
    end
    
    Citizen->>App: Tap "Mark as Safe"
    App->>DB: UPDATE status to 'resolved'
    DB-->>AdminApp: Realtime Broadcast (SOS Resolved)
    AdminApp->>AdminApp: Remove Alert from Panel
```

---

## 18.6 State Machine Diagram: Complaint Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Submitted: Citizen submits form
    
    Submitted --> InProgress: Admin assigns officer
    Submitted --> Rejected: Admin finds report invalid
    
    InProgress --> UnderInvestigation: Officer begins field work
    
    UnderInvestigation --> Resolved: Case solved / Report filed
    UnderInvestigation --> Closed: Insufficient evidence
    
    Resolved --> [*]
    Closed --> [*]
    Rejected --> [*]
```

---

*Return to [Index — Table of Contents](INDEX.md)*
