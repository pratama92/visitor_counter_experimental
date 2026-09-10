# Playground Counter — AI Context

## 1. Project

**Playground Counter** is a simple offline-first Flutter application for recording playground visits.

The goal is to provide a small, cheap, practical visitor counter that can be used in a real playground environment.

The project prioritizes simplicity, stability, and practical real-world testing over unnecessary features.

The project currently has two development stages:

* **V1** — stable MVP / production-testing baseline
* **V2** — experimental visitor and face-recognition development

V2 is an extension of the product concept but should not unnecessarily modify or break the V1 baseline.

---

## 2. V1 Current Status

**V1 MVP is complete and ready for live testing.**

Current status:

* Flutter application working
* SQLite database working
* Daily visit recording working
* Start/end time calculation working
* Session cost stored with each visit
* Invalid visit supported
* Settings supported
* Release APK built
* Release APK installed on Android phone
* Manual SQLite backup tested successfully
* Backup UI removed from V1
* Ready for real-world testing

The V1 release APK is the production-testing version.

V1 should now be treated as a stable baseline.

---

## 3. V1 Features

V1 includes:

* Dashboard
* Add Visit
* Counter number
* Automatic start time
* Automatic end time based on settings
* Session cost
* Visit history
* Date filtering
* Mark Visit as Invalid
* Settings

  * Title
  * Session Time
  * Session Cost
* Local SQLite persistence

V1 is offline-first.

No cloud service or backend server is required.

---

## 4. V1 Architecture

The application is intentionally simple:

```text
Flutter UI
    ↓
App Logic
    ↓
SQLite
```

SQLite is accessed through `sqflite`.

The application does not require a backend server for V1.

---

## 5. V1 Database

Current V1 tables:

```text
visits
settings
```

### visits

```text
id
counter
start_time
end_time
session_cost
is_invalid
```

### settings

```text
id
title
session_time
session_cost
```

The `visits` table stores `session_cost` when the visit is created.

This is intentional.

Changing settings later will affect future visits only.

Old visits must remain unchanged.

---

## 6. Important V1 Design Decisions

### Invalid instead of delete

Visits will not normally be hard-deleted.

Instead:

```text
is_invalid = 1
```

will mark a visit as invalid.

This preserves historical records.

### Keep the V1 visits table stable

Future features should avoid unnecessarily changing the existing V1 `visits` table.

Especially:

**Do not add `visitor_id` directly to `visits` for visitor or face-recognition functionality.**

Future visitor relationships should use separate structures so existing V1 data remains compatible.

---

# 7. V2 Visitor / Face Recognition

Visitor and face-recognition development is being developed separately as **V2**.

V2 introduces a separate visitor data model.

Current V2 tables include:

```text
visitors
face_samples
visit_visitors
```

The existing V1 `visits` table remains unchanged.

### V2 data concept

```text
Visitor
   │
   ├──< Face Samples
   │
   └──< Visits
```

The `visit_visitors` relationship connects visitors to visits without requiring `visitor_id` to be added directly to the original V1 `visits` table.

---

## 8. V2 Technology

V2 currently uses:

* Flutter
* Dart
* SQLite
* `sqflite`
* Camera
* Google ML Kit Face Detection
* TensorFlow Lite
* MobileFaceNet
* `image`

The MobileFaceNet model is stored as:

```text
assets/models/mobilefacenet.tflite
```

V2 is currently being tested on a real Android device.

---

## 9. V2 Current Milestone

**V2 Milestone 1 — Face Recognition + Visitor Registration + Basic Check-in**

The current experimental prototype has successfully demonstrated:

* Camera capture
* Face detection
* Single-face validation
* Face cropping and preprocessing
* Face embedding generation
* MobileFaceNet inference
* Recognition of previously registered visitors
* Registration of new visitors
* Storage of visitor records in SQLite
* Storage of face samples in SQLite
* Recognition of existing visitors
* Creation of a visit for an existing recognized visitor

Current basic workflow:

```text
Camera
   ↓
Face Detection
   ↓
Face Embedding
   ↓
Compare With Saved Face Samples
   ↓
Existing Visitor / New Visitor
   ↓
Create Visit / Register Visitor
```

The current prototype follows the rule:

> **1 face = 1 visit**

The current recognition threshold is approximately:

```text
0.80 similarity
```

This is currently a prototype value and should not be optimized prematurely.

Real-world testing will determine whether it needs adjustment.

---

## 10. V2 Current Behavior

### Existing visitor

When a captured face matches an existing visitor:

```text
Face
 ↓
Recognition
 ↓
Existing Visitor
 ↓
Confirm
 ↓
Create Visit
```

The visit uses the configured:

* Session time
* Session cost

The current implementation successfully creates the visit.

### New visitor

When a captured face does not match an existing visitor:

```text
Face
 ↓
No Match
 ↓
Enter Visitor Name
 ↓
Create Visitor
 ↓
Save Face Sample
```

New visitor registration and face-sample storage are working.

The complete new-visitor → first-visit workflow is still an area for future improvement.

---

## 11. V2 Recognition Testing

Current testing has shown that:

* The same person can produce similarity scores around the expected recognition range.
* Different people have produced significantly lower similarity scores.
* The same exact image can produce a similarity close to 1.0.
* Camera angle, lighting, and capture conditions can affect similarity.

The current goal is not to achieve perfect biometric accuracy.

The goal is to establish a practical recognition workflow that can be tested in a real environment.

Do not over-optimize the recognition algorithm before sufficient real-world testing exists.

---

## 12. V2 Current Stop Point

The current V2 prototype is intentionally **stopped at this milestone**.

This is considered a good checkpoint because the core experimental workflow is already working.

Do not immediately add more features just because they are technically possible.

The next development should happen only after further testing or when a concrete requirement is identified.

---

## 13. Future V2 Direction

Possible future improvements include:

1. Prevent duplicate check-ins while a visitor's current session is still active.
2. Complete the new visitor → first visit workflow.
3. Ensure visitor-to-visit relationships are stored correctly.
4. Improve recognition reliability through real-world testing.
5. Add visitor history and basic visitor management.
6. Handle incorrect or duplicate visitor registrations.
7. Consider local-network / multi-device operation if the real use case requires it.

These should be implemented incrementally.

Do not introduce cloud infrastructure, complex AI systems, or enterprise-level architecture without a real requirement.

---

## 14. Backup

V1 does **not** include a Backup/Restore menu.

A manual ADB backup method has been tested successfully.

Package ID:

```text
com.example.playground_counter
```

Manual backup:

```bat
adb exec-out run-as com.example.playground_counter cat databases/playground_counter.db > playground_counter_backup_YYYY-MM-DD.db
```

This copies the actual SQLite database to the PC.

The procedure is documented separately under:

```text
how-to/manual-sqlite-backup.md
```

Proper user-facing Backup/Restore can be considered later if the product requires it.

---

## 15. Release / Testing Rule

The V1 release APK is the production-testing baseline.

Before installing a new release when existing test data matters:

```text
Backup SQLite
    ↓
Build Release APK
    ↓
Install Update
    ↓
Test
```

Do not uninstall the application before backing up the database.

Debug and release installations must be treated carefully because local SQLite data can be lost during installation changes.

V2 experimental development should not be allowed to accidentally overwrite or replace the V1 production-testing baseline.

---

## 16. Sequence Diagrams

V1 currently documents three main application sequences:

1. Open App / Load Dashboard
2. Add Visit
3. Mark Visit Invalid

Do not create additional sequence diagrams unless a future feature is complex enough to justify one.

V2 face-recognition flows do not need formal sequence diagrams yet.

---

## 17. Documentation Principle

Documentation should remain proportional to the application.

Do not create unnecessary enterprise-level documentation for this project.

Document:

* Requirements
* Architecture
* Database
* Important design decisions
* Main application sequences
* Practical how-to procedures
* Significant V2 milestones

Avoid documenting every class and method.

---

## 18. Development Philosophy

The project should grow through small, validated improvements.

Preferred development cycle:

```text
Small Change
    ↓
Build
    ↓
Run on Real Device
    ↓
Test
    ↓
Confirm Working
    ↓
Next Small Change
```

Do not make multiple unrelated changes at once.

Prefer existing working code over unnecessary refactoring.

---

## 19. AI Working Rules

When continuing development:

* Keep the application simple.
* Do not add features without a real requirement.
* Prefer existing working code over unnecessary refactoring.
* Preserve existing V1 data.
* Treat V1 as the stable baseline.
* Treat V2 as experimental.
* Do not unnecessarily modify the V1 `visits` table.
* Do not add `visitor_id` directly to V1 `visits` without a strong reason.
* Prefer offline-first behavior.
* Avoid cloud/backend infrastructure unless required.
* Treat old visit records as historical data.
* Test changes on the real Android device.
* Make one small change at a time.
* Do not over-optimize prematurely.
* Do not over-engineer the architecture.
* Do not jump ahead to future features before the current feature is tested.
* When proposing a new feature, first check whether it can be implemented without breaking the V1 baseline.
* When a milestone works reliably enough, it is acceptable to stop and preserve it as a checkpoint.

---

## 20. Main Principle

> **Simple, stable, usable first. Features later.**

The project should solve the real-world problem first and add complexity only when actual usage proves that the complexity is necessary.
