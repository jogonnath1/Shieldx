# Diagram Validation Changelog

This document summarizes the transition from the previous placeholder report diagrams to the strict, source-grounded Mermaid representations.

## Contradictions & Resolutions
1. **Layer Skipping (SOSNotifier):** The previous sequence diagram showed the UI/Provider directly interacting with Supabase. The Dart code strictly routes through EmergencyService. **Resolution:** Forced SOSNotifier to call EmergencyService in both Sequence and DFD diagrams to match lib/providers/ → lib/data/ architecture.
2. **Missing Fallbacks:** The previous report mentioned a basic GPS fallback but omitted the full 4-step sequence (Simulated -> Live -> Cached -> Default). **Resolution:** Added all 4 branching paths in sequence_sos_activation.mmd.
3. **Missing Foreign Keys:** The messages table in the previous ERD did not show sender_id. **Resolution:** Explicitly added profiles ||--o{ messages : "sends (sender_id)".
4. **Invalid Extends:** "Mark Safe" was floating. **Resolution:** Fixed it to strictly <<extend>> "Trigger SOS".

## Source Mapping & Fix Summary

| Diagram | Source Files Used | Issues in Prior Version | Fix Applied |
|---------|-------------------|-------------------------|-------------|
| **1. Activity** | pp_router.dart, submit_complaint_screen.dart, sync_service.dart | Missing OTP branch; ambiguous offline behavior. | Added Email/Phone OTP choice; strictly routed offline path to SaveToOfflineOutbox. |
| **2. Use Case** | presentation/**/*.dart, pp_router.dart | Non-standard extends; floating use cases. | Removed orphan nodes; applied strict <<include>> (mandatory) and <<extend>> (optional). |
| **3. Class** | lib/data/models/*.dart | Missing Dart fields; concatenated multiplicities (e.g., *..0..1). | Extracted 100% of Dart fields; wrote multi-ended standard UML multiplicity tags; applied UML visibility. |
| **4. Sequence** | sos_provider.dart, emergency_service.dart | Ignored Layered Architecture; missing GPS fallback loop. | Enforced UI -> Service -> DB layering; mapped exact 4-step GPS fallback and loop streams. |
| **5. Architecture** | Project directory structure | Allowed layer-skipping arrows. | Ensured strictly downward/adjacent dependencies matching import statements. |
| **6. ERD** | lib/data/models/*.dart | Missing messages.sender_id FK. | Added all 7 models/tables; explicitly mapped all FK columns using Crow's Foot. |
| **7. DFD Level-1** | sos_provider.dart, emergency_service.dart | Unnumbered processes; direct UI-to-DB writes. | Numbered processes (1.0, 2.0); routed D1/D2 writes through EmergencyService. |
