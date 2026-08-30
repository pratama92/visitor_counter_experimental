# Development Log — Kotlin Incremental Cache Compilation Failure

**Project:** Playground Counter  
**Date:** 2026-08-30  
**Status:** Resolved

---

## Encounter

Running `flutter run` failed during Android compilation.

The failure occurred at:

    :camera_android_camerax:compileDebugKotlin

The main error was:

    Daemon compilation failed

followed by:

    Could not close incremental caches

and:

    Storage for [...] is already registered

The affected cache was located under:

    build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\

---

## Dependency Check

The camera dependency tree was checked with:

    flutter pub deps | Select-String "camera"

Result:

    camera 0.12.0+2
    └── camera_android_camerax 0.7.4+7

The failure was therefore occurring inside the Android CameraX implementation of the `camera` package.

`flutter pub get` completed successfully, so dependency resolution itself was working.

The outdated packages reported by Pub were:

    material_color_utilities 0.13.0
    test_api 0.7.12

These were not identified as the cause of the Kotlin compilation failure.

---

## Flutter Environment Check

`flutter doctor -v` showed:

    Flutter 3.47.2
    Dart 3.13.2
    Android SDK 36.0.0
    Java 17

The configured Flutter SDK was:

    C:\Users\Anugrah\develop\flutter

`android/local.properties` confirmed:

    flutter.sdk=C:\\Users\\Anugrah\\develop\\flutter

PowerShell also confirmed that the active Flutter command resolved to:

    C:\Users\Anugrah\develop\flutter\bin\flutter.bat

There was a Flutter PATH warning because a local directory also existed at:

    D:\MINI-PROJECT\playground_counter\flutter

However, the actual Flutter command being executed was the correct SDK.

---

## Pub Cache Configuration

The Pub cache was moved to the D: drive:

    D:\Pub\Cache

The user environment variable was configured with:

    [Environment]::SetEnvironmentVariable("PUB_CACHE", "D:\Pub\Cache", "User")

Verification:

    $env:PUB_CACHE

returned:

    D:\Pub\Cache

This successfully moved the Pub cache, but it was not the direct solution to the Kotlin compilation failure.

---

## Android Project Structure

The Android project uses Kotlin DSL.

The relevant files are:

    android/
    ├── build.gradle.kts
    ├── settings.gradle.kts
    ├── gradle.properties
    ├── local.properties
    └── app/

Therefore the project does not contain:

    android\settings.gradle

The correct file is:

    android\settings.gradle.kts

The project uses:

    com.android.application version 9.1.0
    org.jetbrains.kotlin.android version 2.4.0

---

## Root Cause

The failure was identified as a Kotlin incremental compilation cache conflict.

The strongest evidence was:

    Storage for [...] is already registered

The affected files included:

    class-fq-name-to-source.tab
    source-to-classes.tab
    internal-name-to-source.tab
    id-to-file.tab
    file-to-id.tab
    source-to-output.tab

These were located inside the Kotlin incremental compilation cache for:

    camera_android_camerax

This was not a Dart source-code error and was not a normal Pub dependency-resolution failure.

---

## Fix

The effective fix was to disable Kotlin incremental compilation.

The following line was added to:

    android/gradle.properties

    kotlin.incremental=false

The resulting configuration contains:

    org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
    android.useAndroidX=true
    android.newDsl=false
    android.builtInKotlin=false
    kotlin.incremental=false

---

## Why This Was the Fix

The error was specifically related to Kotlin's incremental compilation cache.

The message:

    Storage for [...] is already registered

indicates that Kotlin's incremental compiler encountered a cache/storage registration conflict.

Disabling incremental compilation avoids that problematic cache mechanism for this project.

---

## What Was Not the Solution

Repeatedly running:

    flutter clean

and:

    flutter pub get

was not considered the actual fix.

`flutter pub get` was already completing successfully, while the failure happened later during Kotlin compilation.

Moving the Pub cache to:

    D:\Pub\Cache

was also not the direct fix.

The important configuration change was:

    kotlin.incremental=false

---

## Result

After adding:

    kotlin.incremental=false

to:

    android/gradle.properties

the project returned to a green build state.

The previous failure:

    :camera_android_camerax:compileDebugKotlin

was no longer blocking the build.

---

## Future Troubleshooting

If the same error appears again:

    Daemon compilation failed

combined with:

    Could not close incremental caches

and:

    Storage for [...] is already registered

especially when the failing task is:

    :camera_android_camerax:compileDebugKotlin

check Kotlin incremental compilation before changing application code or upgrading unrelated dependencies.

The relevant project setting is:

    kotlin.incremental=false

---

## Environment Reference

| Component              | Configuration                      |
| ---------------------- | ---------------------------------- |
| Project                | Playground Counter                 |
| Flutter                | 3.47.2                             |
| Dart                   | 3.13.2                             |
| Flutter SDK            | `C:\Users\Anugrah\develop\flutter` |
| Android SDK            | `C:\Android\sdk`                   |
| Android SDK Version    | 36.0.0                             |
| Java                   | JDK 17                             |
| Pub Cache              | `D:\Pub\Cache`                     |
| Camera                 | 0.12.0+2                           |
| Camera Android CameraX | 0.7.4+7                            |
| Kotlin                 | 2.4.0                              |
| Android Gradle Plugin  | 9.1.0                              |
| Build Status           | Resolved / Green                   |

---

## Final Decision

Keep the following configuration in:

    android/gradle.properties

    kotlin.incremental=false

This is the recorded workaround/fix for the Kotlin incremental-cache conflict encountered during Playground Counter Android development.

**Resolution: Green**
