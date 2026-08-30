# Playground Counter — AI Context

## 1. Project

**Playground Counter** is a simple offline-first Flutter application for recording playground visits.

The goal is to provide a small, cheap, practical counter application that can be used in a real playground environment.

The project will prioritize simplicity and stability over unnecessary features.

---

## 2. Current Status

**V1 MVP is complete and ready for live testing.**

Current status:

- Flutter application working
- SQLite database working
- Daily visit recording working
- Start/end time calculation working
- Session cost stored with each visit
- Invalid visit supported
- Settings supported
- Release APK built
- Release APK installed on Android phone
- Manual SQLite backup tested successfully
- Backup UI removed from V1
- Ready for real-world testing

The current release APK is the production-testing version.

---

## 3. V1 Features

V1 includes:

- Dashboard
- Add Visit
- Counter number
- Automatic start time
- Automatic end time based on settings
- Session cost
- Visit history
- Date filtering
- Mark Visit as Invalid
- Settings
  - Title
  - Session Time
  - Session Cost

- Local SQLite persistence

V1 is offline-first.

No cloud service is required.

---

## 4. Architecture

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

## 5. Database

Current tables:

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

### Keep the visits table stable

Future features should avoid unnecessarily changing the existing V1 `visits` table.

Especially:

**Do not add `visitor_id` directly to `visits` for the future face-recognition feature.**

---

## 7. Future Visitor / Face Recognition Design

Face recognition will be added later.

The planned structure is:

```text
Visitor
    │
    │ 1-to-many
    ▼
Visit relationship
```

More specifically, a separate relationship structure will be introduced rather than mutating the original V1 visit records.

The purpose is to preserve compatibility with existing V1 data.

Future implementation must be designed as an extension of the current system, not as a rewrite of V1.

---

## 8. Backup

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

This will copy the actual SQLite database to the PC.

This procedure is documented separately under:

```text
how-to/manual-sqlite-backup.md
```

Proper user-facing Backup/Restore can be considered later.

---

## 9. Release / Testing Rule

The release APK will be used for production testing.

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

---

## 10. Sequence Diagrams

V1 currently documents three main application sequences:

1. Open App / Load Dashboard
2. Add Visit
3. Mark Visit Invalid

Do not create additional sequence diagrams unless a future feature is complex enough to justify one.

---

## 11. Documentation Principle

Documentation should remain proportional to the application.

Do not create unnecessary enterprise-level documentation for this MVP.

Document:

- Requirements
- Architecture
- Database
- Important design decisions
- Main application sequences
- Practical how-to procedures

Avoid documenting every class and method.

---

## 12. Future Direction

After V1 live testing is stable:

1. Fix real bugs found during testing.
2. Freeze the V1 baseline.
3. Consider Visitor management.
4. Add photo/face recognition.
5. Add the Visitor-to-Visit relationship without unnecessarily changing the existing V1 visit data.
6. Add proper Backup/Restore if the product requires it.

---

## 13. AI Working Rules

When continuing development:

- Keep the MVP simple.
- Do not add features without a real requirement.
- Prefer existing working code over unnecessary refactoring.
- Preserve existing V1 data.
- Avoid mutating the `visits` table unless there is a strong reason.
- Do not introduce cloud/backend infrastructure unless required.
- Prefer offline-first behavior.
- Treat old visit records as historical data.
- When proposing a new feature, first check whether it can be added without breaking V1.
- Test the real application before adding more features.
- Do not over-engineer the application.

The main principle is:

> **Simple, stable, usable first. Features later.**
