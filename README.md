# Visitor Counter

Visitor Counter is a simple offline-first visitor counting and recognition application built with Flutter.

The application is designed for small venues and real-world activities that need a practical way to record visits, recognize returning visitors, register new visitors, and track visitor activity.

The implementation is intentionally general-purpose rather than being tied to a specific venue such as a playground.

## Potential Use Cases

Visitor Counter can potentially be used for:

* Playgrounds
* Swimming pools
* Fishing ponds
* Recreation areas
* Tourist attractions
* Weddings and private events
* Seminars and workshops
* Community events
* Other small venues requiring simple visitor tracking

The application focuses on common visitor-management requirements rather than venue-specific complexity.

## Features

* Record visitor visits
* Automatically record visit start and end times
* Use configurable session duration and visit cost
* Detect and recognize visitors using face recognition
* Register new visitors with a face sample
* Store visitor and face data locally
* View visits by date
* Display daily visitor totals
* Mark visits as valid or invalid
* Keep invalid records for historical tracking
* Operate without requiring an internet connection

## Technology

* Flutter
* Dart
* SQLite
* Google ML Kit Face Detection
* TensorFlow Lite
* MobileFaceNet

## Design

The application is intentionally kept simple and practical.

The data model separates the **Visitor** from the **Visit**.

A **Visitor** represents a person who may visit multiple times.

A **Visit** represents an individual check-in session.

The intended relationship is:

```text
Visitor
   │
   └──< Visit
```

Visitor-related data is kept separate from the original V1 visit records so that the existing V1 data structure can remain stable.

Face recognition is used to identify an existing visitor or determine that a new visitor needs to be registered.

The current recognition workflow is intentionally lightweight:

```text
Camera
   ↓
Face Detection
   ↓
Face Embedding
   ↓
Visitor Recognition
   ↓
Existing Visitor / New Visitor
   ↓
Visit
```

The current prototype follows the rule:

> **1 face = 1 visit**

The application remains local-first, with visitor, face sample, and visit data stored in SQLite.

## Current Milestone

The current experimental V2 prototype has successfully demonstrated:

* Face detection from the device camera
* Face embedding generation using MobileFaceNet
* Recognition of previously registered visitors
* Registration of new visitors and face samples
* Persistent storage of visitor and face data in SQLite
* Creation of a visit for a recognized visitor
* Basic real-device testing

This milestone establishes the basic:

```text
Face Recognition
      ↓
Visitor
      ↓
Visit
```

workflow.

The current V2 prototype is intentionally stopped at this milestone while further testing can be performed.

## Future

Future development will focus on improving the reliability and practicality of the current workflow rather than adding unnecessary complexity.

Possible future improvements include:

* Preventing duplicate check-ins while a visitor's current session is active
* Completing the new visitor → first visit workflow
* Completing visitor-to-visit relationship handling
* Improving recognition reliability through real-world testing
* Visitor history and management
* Handling incorrect or duplicate face registrations
* Local network / multi-device support

More advanced features will only be introduced when they provide clear practical value.

## Purpose

Visitor Counter is a practical Flutter application built around a real-world visitor-management workflow.

The implementation is intended to remain lightweight and adaptable across different small venues.

The main focus is:

* Simplicity
* Offline-first operation
* Minimal hardware requirements
* Practical visitor management
* Face-based visitor recognition
* Incremental development
* Maintainable implementation
* Real-world usability

The project will grow through real-world testing and small, validated improvements rather than unnecessary complexity.
