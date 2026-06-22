# Academic Defense Review - Part 3: Top Defense Questions

**Reviewer:** Senior Software Engineering Professor
**Project:** ShieldX – Crime Reporting Management System

*Note: Below is a curated selection of the most rigorous, high-probability questions an academic panel will ask during your defense, categorized by domain. Be prepared to answer these clearly.*

---

## Architecture & Flutter

**Q1: Why did you choose Riverpod over Provider or GetX for state management?**
- **Expected Answer:** Riverpod is compile-safe and doesn't rely on the widget tree.
- **Technical Answer:** Riverpod allows for global declaration without `BuildContext` dependency, making dependency injection clean. We heavily used `StreamProvider` for Supabase realtime streams and `StateNotifierProvider` for complex logic like `SOSNotifier`, which is difficult to manage cleanly in vanilla Provider.
- **Short Viva Answer:** It provides compile-time safety and handles asynchronous streams (like Supabase Realtime) perfectly.

**Q2: How does the SOS system continue to work if the user's GPS hardware fails to get a lock immediately?**
- **Expected Answer:** It uses a fallback mechanism.
- **Technical Answer:** The `SOSNotifier` uses a 4-step fallback chain: It tries for a high-accuracy GPS lock for 10 seconds. If it times out, it falls back to the last known cached location (`locationCacheProvider`). If that fails, it submits the SOS with null coordinates so the admin at least gets the distress signal.
- **Short Viva Answer:** We built a timeout fallback that uses the last cached location if live GPS fails.

**Q3: How did you implement offline functionality in Flutter?**
- **Expected Answer:** By saving data locally when there's no internet.
- **Technical Answer:** We use `SharedPreferences` as an offline queue. A custom `connectivityProvider` continuously pings a reliable endpoint via `http`. When it detects a connection restore, `SyncService.syncOfflineOutbox()` iterates through the queued JSON strings and pushes them to Supabase.
- **Short Viva Answer:** Local storage queue via `SharedPreferences`, which automatically syncs when internet returns.

---

## Database & Supabase

**Q4: Why use Supabase (PostgreSQL) instead of Firebase (NoSQL) for this project?**
- **Expected Answer:** Because our data is relational.
- **Technical Answer:** Crime reporting is inherently relational. A `Complaint` belongs to a `Profile`, has `StatusHistory` logs, and connects to an assigned `Officer`. Doing this in Firebase requires complex denormalization. Supabase provides PostgreSQL, which handles these foreign key relationships natively while still offering real-time websockets.
- **Short Viva Answer:** Our data is highly relational, so PostgreSQL was mathematically a better fit than NoSQL.

**Q5: What prevents a normal citizen from assigning an officer to a case by manipulating the API?**
- **Expected Answer:** Security rules in the database.
- **Technical Answer:** We implemented Supabase Row Level Security (RLS). An `UPDATE` policy on the `complaints` table explicitly checks if `auth.jwt() ->> 'role' = 'admin'`. Even if a citizen reverse-engineers the Flutter app and sends an API call, the PostgreSQL database will reject it.
- **Short Viva Answer:** Database-level Row Level Security (RLS) blocks unauthorized API calls.

**Q6: What happens to the database if thousands of citizens press SOS at exactly the same time?**
- **Expected Answer:** The cloud provider scales.
- **Technical Answer:** Since we use Supabase, the backend relies on PostgreSQL connection pooling (PgBouncer). While we might hit rate limits on a free tier, architecturally, Supabase handles concurrent inserts efficiently. Realtime broadcasts are handled by Phoenix/Elixir channels which are built for massive concurrency.
- **Short Viva Answer:** Supabase uses PgBouncer and Elixir channels to handle high-concurrency inserts and websocket broadcasts.

---

## Software Engineering & SDLC

**Q7: Explain the 4-layer architecture diagram in your report.**
- **Expected Answer:** We separated UI from database logic.
- **Technical Answer:** 
  1. **Presentation:** Flutter Screens and Widgets.
  2. **Provider:** Riverpod state managers holding UI business logic.
  3. **Data/Service:** Dart classes making actual HTTP/Supabase SDK calls.
  4. **Backend:** PostgreSQL and Storage.
  This enforces the Single Responsibility Principle.
- **Short Viva Answer:** It separates UI, State, API Calls, and Database to make the code maintainable.

**Q8: If you had 6 more months, what architectural flaw would you fix?**
- **Expected Answer:** Add automated testing and spatial database features.
- **Technical Answer:** I would migrate the `latitude` and `longitude` `double` columns in Postgres to a proper PostGIS `geometry` type. This would allow the database to mathematically calculate the "nearest police station" at the query level using `ST_Distance`, rather than doing the math on the mobile client.
- **Short Viva Answer:** Implement PostGIS in PostgreSQL for faster, server-side geographic calculations.

*(Note: During defense, examiners usually ask 3 to 5 very deep questions rather than 50 shallow ones. Mastering the 8 scenarios above will cover 90% of defense attacks.)*
