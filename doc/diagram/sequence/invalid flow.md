Operator        Flutter UI        App Logic        SQLite
   │                │                │               │
   │ Mark Invalid   │                │               │
   ├───────────────>│                │               │
   │                │ Confirmation  │               │
   │<───────────────┤                │               │
   │ Confirm        │                │               │
   ├───────────────>│                │               │
   │                │ Update Visit  │               │
   │                ├───────────────>│               │
   │                │                │ is_invalid=1  │
   │                │                ├──────────────>│
   │                │                │<──────────────┤
   │                │<───────────────┤               │
   │<───────────────┤                │               │