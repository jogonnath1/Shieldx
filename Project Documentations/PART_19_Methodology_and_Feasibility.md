# ShieldX — Full Project Documentation
## Part 19: Methodology & Feasibility Study

---

## 19.1 Introduction

A core component of an academic project defense is justifying the development approach and evaluating the project's viability. This document outlines the Software Development Life Cycle (SDLC) methodology utilized and presents a formal Feasibility Study for ShieldX.

---

## 19.2 Literature Review: Existing vs. Proposed System

### 19.2.1 Existing System Limitations
In the traditional framework of crime reporting in Bangladesh:
- **Manual Logging**: Citizens must physically travel to a police station to file a General Diary (GD) or First Information Report (FIR).
- **Lack of Transparency**: Complainants have no digital way to track the progress of their case.
- **Emergency Inefficiency**: Phoning emergency hotlines (e.g., 999) requires verbal description of location, which is difficult under extreme duress or in unfamiliar areas.
- **Data Fragmentation**: Paper-based records make it nearly impossible to quickly visualize crime hotspots or perform data analytics for resource allocation.

### 19.2.2 Proposed System Advantages (ShieldX)
ShieldX solves these issues by:
- **Digital Convenience**: Complaints can be filed securely from anywhere.
- **Real-Time GPS SOS**: Panic button immediately transmits precise location coordinates.
- **Automated Transparency**: Push notifications inform citizens exactly when their complaint status changes.
- **Centralized Admin Dashboard**: Police administrators get instant charts and heatmaps, dramatically improving data-driven decision-making.

---

## 19.3 Software Development Life Cycle (SDLC)

The **Agile Methodology (Scrum framework)** was selected for the development of ShieldX. This allowed for iterative progress, continuous testing, and rapid adaptation to requirements.

### Agile Phases Implemented:
1. **Requirements Gathering**: Identifying the needs of both citizens (anonymity, ease of use, SOS) and police (data visualization, management tools).
2. **Design & Prototyping**: Designing the UI/UX in Figma and establishing the database schema (ERD).
3. **Sprints (Development)**:
   - *Sprint 1*: Firebase/Supabase setup, Auth logic, and core UI scaffolding.
   - *Sprint 2*: Citizen complaint submission, GPS integration, and offline queuing.
   - *Sprint 3*: Admin dashboard, Realtime subscriptions, and SOS broadcast system.
   - *Sprint 4*: Refactoring into `lib/admin` and `lib/user` modules, bug fixing, and polish.
4. **Testing**: Unit testing the `ComplaintClassifier` and manual QA of the full application flow.
5. **Deployment**: Generating release APKs and finalizing project documentation.

---

## 19.4 Feasibility Study

A feasibility study was conducted prior to development to ensure the project was viable on all fronts.

### 19.4.1 Technical Feasibility
**Result: Highly Feasible**
- **Framework**: Flutter provides a robust, cross-platform UI toolkit that compiles to native code, ensuring high performance on Android and iOS from a single codebase.
- **Backend**: Supabase handles real-time WebSockets, PostgreSQL database management, and authentication out-of-the-box, significantly reducing backend development overhead.
- **Hardware**: Modern smartphones possess the necessary hardware (GPS, Camera, Internet connectivity) to fully utilize the app.

### 19.4.2 Economic Feasibility
**Result: Highly Feasible**
- **Development Costs**: Minimal. Flutter is open-source. Supabase offers a generous free tier for development, which can scale affordably in production.
- **Hardware Costs**: Citizens and Police already possess smartphones; no specialized hardware (e.g., dispatch terminals) needs to be procured.
- **Operational Savings**: Digitizing records reduces paper waste, physical storage costs, and administrative man-hours for law enforcement.

### 19.4.3 Operational Feasibility
**Result: Feasible**
- **User Acceptance**: The app is designed with material design guidelines, making it intuitive for the average smartphone user. The SOS feature is a single long-press, requiring minimal cognitive load during stress.
- **Police Adoption**: The centralized dashboard automatically visualizes data, requiring less manual data entry and spreadsheet management from officers.
- **Challenge**: The primary operational challenge will be verifying user identities to prevent spam/false reports. This is mitigated by the NID and phone number requirements during registration.

---

*Return to [Index — Table of Contents](INDEX.md)*
