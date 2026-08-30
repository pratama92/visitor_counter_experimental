# Playground Counter — Manual SQLite Backup

## Purpose

Playground Counter V1 will use SQLite for local data.

For production testing, the database will be backed up manually before installing a new release APK.

No backup menu will be included in V1.

---

## Package ID

```text
com.example.playground_counter
```

## Backup

Connect the Android phone with USB debugging enabled.

From the project folder:

```bat
adb exec-out run-as com.example.playground_counter cat databases/playground_counter.db > playground_counter_backup_YYYY-MM-DD.db
```

Example:

```bat
adb exec-out run-as com.example.playground_counter cat databases/playground_counter.db > playground_counter_backup_2026-08-30.db
```

The backup file will be created in the current project folder.

---

## Check Backup

```bat
dir playground_counter_backup_*.db
```

---

## Update the App

After the backup:

```bat
flutter build apk --release
```

Then install the new release:

```bat
flutter install
```

---

## Simple Rule

**Before every release update:**

```text
Phone
  ↓
Backup SQLite DB
  ↓
Build Release APK
  ↓
Install Release
  ↓
Test
```

If something goes wrong, keep the backup and do not delete the app data.

---

## Important

Do **not** uninstall the app before making a backup.

Do **not** delete the existing SQLite database.

V1 will keep the database structure simple and stable.

Proper user-facing Backup/Restore will be considered later.
