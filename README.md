# Playground Counter

Playground Counter is a simple offline-first visitor counting and recognition application built with Flutter.

The application helps playground staff record visits, recognize returning visitors, register new visitors, and track visitor activity through a simple and practical interface.

## Features

* Record visitor visits
* Automatically record visit start and end times
* Use configurable session duration and visit cost
* Detect and recognize visitors using face recognition
* Register new visitors with a face sample
* Associate visitors with their visits
* Select and view visits by date
* Display daily visitor totals
* Mark visits as valid or invalid
* Keep invalid records for historical tracking
* Store application data locally for offline use

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

A **Visitor** represents a person who can return multiple times.

A **Visit** represents a single check-in session.

```text
Visitor
   │
   └──< Visit
```

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
* Creation of a visit for a recognized visitor
* Persistent storage of visitor and face data in SQLite
* Basic real-device testing

This milestone establishes the basic **face recognition → visitor → visit** workflow.

## Future

Future development will focus on improving the reliability and practicality of the current workflow rather than adding unnecessary complexity.

Possible future improvements include:

* Preventing duplicate check-ins during an active session
* Completing the new visitor → first visit workflow
* Linking visitors and visits more completely
* Improving recognition reliability through additional testing
* Visitor history and management
* Better handling of incorrect or duplicate face registrations
* Local network / multi-device support

More advanced features will only be introduced when they provide clear practical value.

## Purpose

This project is a practical Flutter application built around a real-world business workflow.

The focus is on:

* Simplicity
* Offline-first operation
* Minimal hardware requirements
* Practical visitor management
* Incremental development
* Maintainable implementation

The project will grow through real-world testing and small, validated improvements rather than unnecessary complexity.
