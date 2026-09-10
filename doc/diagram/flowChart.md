# Visitor Counter

```text
                ┌──────────┐
                │ Operator │
                └────┬─────┘
                     │
                     ▼
              ┌──────────────┐
              │  Flutter UI  │
              └──────┬───────┘
                     │
                     ▼
              ┌──────────────┐
              │  App Logic   │
              └──────┬───────┘
                     │
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼
┌──────────────────┐   ┌──────────────────┐
│ Face Recognition │   │      SQLite      │
│                  │   │                  │
│ Camera           │   │ visits           │
│ Face Detection   │   │ visit_visitors   │
│ MobileFaceNet    │   │ visitors         │
│ Embedding        │   │ face_samples     │
└──────────────────┘   │ settings         │
                       └──────────────────┘
```
