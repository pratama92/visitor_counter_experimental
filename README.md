# Playground Counter

Playground Counter is a simple offline-first visitor counting application built with Flutter.

The application will help playground staff record visitor counts, track visits, and view daily visitor totals through a simple and practical interface.

## Features

* Record visitor counts
* Increase or decrease the visitor count
* Automatically record visit start and end times
* Select and view visits by date
* Display daily visitor totals
* Mark visits as valid or invalid
* Keep invalid records for historical tracking
* Store visit data locally for offline use

## Technology

* Flutter
* Dart
* SQLite

## Design

The application will keep the first version intentionally simple.

The main record will be a **Visit**, containing the visitor count, start time, end time, and validity status.

Invalid records will not be permanently deleted. They will remain available as part of the visit history.

## Future

Future versions will introduce visitor management and visitor photographs.

The future data model will separate **Visitor** and **Visit**, allowing one visitor to have multiple visits.

```text
Visitor
   │
   └──< Visit
```

Visitor recognition and other features will be introduced only after the core counting and visit-recording workflow is stable.

## Purpose

This project will be a practical Flutter application built around a real-world business workflow, with a focus on simplicity, offline-first operation, and maintainable development.
