# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Summary

Cross-platform Qt 6 / Qt Quick (QML) application template. CMake build system targeting iOS, macOS, Android, Linux, and Windows. Requires Qt 6.10+, CMake 3.28+, C++23.

## Build Commands

All Apple presets require a `CMakeUserPresets.json` with signing credentials (gitignored). Presets ending in `-local` are user-defined overrides inheriting from the base presets in `CMakePresets.json`.

### macOS (Direct Distribution — DMG)
```bash
cmake --preset macos-release-local          # Configure (Ninja)
cmake --build --preset macos-app-local      # Build only
cmake --build --preset macos-distributable-local  # Full: build → macdeployqt → DMG → notarize → staple → verify
```

### macOS (App Store — PKG)
```bash
cmake --preset macos-appstore-local         # Configure (Xcode generator)
cmake --build --preset macos-appstore-distributable-local  # Full: build → archive → export PKG → verify → upload ASC
```

### iOS (App Store)
```bash
cmake --preset ios-release-local            # Configure (Xcode generator)
cmake --build --preset ios-app-local        # Build only
cmake --build --preset ios-distributable-local  # Full: build → archive → export IPA → verify → upload ASC
```

### Linux
```bash
cmake -S . -B build/linux-release -DCMAKE_BUILD_TYPE=Release
cmake --build build/linux-release
cmake --build build/linux-release --target AppImage  # Optional AppImage packaging
```

### Android
Build via Qt Creator (recommended) or the generated Gradle project in `<build-dir>/android-build`.

## Architecture

### CMake Module Organization

Root `CMakeLists.txt` is minimal (14 lines) — it delegates to two entry points:

- **`cmake/ProjectSetup.cmake`** → `configure_project()`: compiler settings, Conan, Qt discovery, AUTOMOC
- **`cmake/MainApp.cmake`** → `configure_main_app()`: creates the executable, registers QML modules, platform sources, code signing, packaging targets

Deploy modules live in `cmake/deploy/` and define custom build targets that chain together:
- **iOS**: `IOSArchive → IOSExportIPA → VerifyIOSIPA → IOSUploadASC → ReleaseDistributableIOS`
- **macOS DMG**: `MacDeployQt → DMG → NotarizeMacOS → VerifyMacOSPackage → ReleaseDistributableMacOS`
- **macOS App Store**: `MacAppStoreArchive → MacExportPkg → VerifyMacPkg → MacUploadASC → ReleaseDistributableMacOSAppStore`

Shared deploy helpers eliminate cross-platform duplication:
- **`DeployPipelines.cmake`** — single entry point; includes all deploy modules and provides `configure_deploy_pipelines(target)`
- **`AscUpload.cmake`** — unified App Store Connect upload for iOS IPA and macOS PKG
- **`XcodeExport.cmake`** — unified `xcodebuild -exportArchive` for iOS and macOS App Store
- **`ArtifactVerify.cmake`** / **`VerifyArtifact.cmake`** — unified artifact verification
- **`VersionTarget.cmake`** — shared `add_version_target()` used by iOS and macOS builds
- **`cmake/qt/FindMacDeployQt.cmake`** — shared `find_macdeployqt()` used by macOS DMG and App Store builds
- **`cmake/platform/IOSResources.cmake`** — iOS asset catalog and launch screen setup

Build-time `-P` scripts (version generation, notarization, verification, etc.) live in `cmake/deploy/{platform}/` subdirectories; shared scripts live in `cmake/deploy/`.

All CMake modules use `include_guard(GLOBAL)`.

### Application Structure

- **Entry point**: `src/main/common/main.cpp` — creates QGuiApplication, sets AppStyle, loads `Main.qml`
- **Navigation**: C++ `NavigationController` singleton (`include/main/common/navigation/`) manages a back-stack of `(url, props, showChrome)` entries. QML drives a `Loader` from `currentUrl`/`currentProps`.
- **QML root**: `ui/Main.qml` — `ApplicationWindow` with adaptive portrait/landscape layouts
- **Organisms**: `ui/organisms/` — reusable composite components (Header, Footer, NavBar, NavigationStack)
- **Pages**: `ui/pages/` (Readme, StyleShowcase, License) with content components in `ui/pages/content/`
- **Layouts**: `ui/templates/` (AdaptiveLayout, MainPortraitLayout, MainLandscapeLayout)
- **Android back**: JNI glue in `src/main/android/` queues `NavigationController::pop()` onto the Qt thread

### QML Modules

Three QML modules, each a separate CMake target:
- **`dev.crowell.QtQuickTemplate`** — main app QML (files in `ui/`)
- **`dev.crowell.AppTheme`** — `Theme.qml` singleton with design tokens (colors, spacing, radii, typography)
- **`dev.crowell.AppStyle`** — custom Qt Quick Controls 2 style overriding Button, TextField, etc.

AppTheme and AppStyle link against Qt Private modules (`Qt6::QmlPrivate`, `Qt6::QuickPrivate`, `Qt6::QuickTemplates2Private`) for deep style customization. Both have the Qt type compiler enabled.

QML files use `QT_RESOURCE_ALIAS` for flattened resource paths (e.g., `ui/pages/Readme.qml` → `pages/Readme.qml`).

### Libraries

Libraries live in `libs/`. Helper macros in `cmake/libs/LibraryCommon.cmake`:
- `add_portable_cpp_library()` / `add_portable_qt_library()` — static on iOS, shared elsewhere
- `apply_android_max_page_size()` — 16KB page alignment for Android

`libs/appstyle/tools/` contains Node.js developer utilities for palette extraction (`extract-crowell-palette.js`) and WCAG contrast validation (`validate-contrast.js`).

### Version Generation

`cmake/deploy/GenerateVersion.cmake` computes build number from `git rev-list --count HEAD`:
- iOS: generates `platforms/ios/version.xcconfig`
- Android: generates `platforms/android/version.properties`
- Format: `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1.0.0.<commit_count>`

## Key Conventions

- **C++23** project-wide (C++20 for the helloworld sample library demonstrating modules)
- **Qt minimum**: 6.10 — the FFmpeg static-linking workaround in `cmake/qt/QtProject.cmake` is specific to this version
- **Cache variable prefix**: all project-specific CMake cache variables use the `QTQUICKTEMPLATE_` prefix
- **Platform resources**: `platforms/{ios,macos,android,linux,windows}/` — Info.plists, entitlements, icons, manifests
- **QML directory is `ui/`**, not `qml/` — this matters for macdeployqt's `-qmldir` flag

## Known Harmless Warnings

- `qmldir file not found at ".../dev/crowell/QtQuickTemplate"` during configure — qmldir is generated at build time
- `QT_CREATOR_SKIP_CONAN_SETUP` unused variable — set in user presets for Qt Creator compatibility
- `app-store` export method deprecated — should be `app-store-connect` in future Xcode versions
- CPack DragNDrop `install_name_tool` RPATH errors — harmless, macdeployqt already fixed RPATHs

## Task Delegation

For complex, multi-step tasks, delegate to specialized subagents:
- **Explore**: codebase search, file discovery, architecture questions — use before modifying unfamiliar code
- **Plan**: design implementation strategy for multi-file or cross-platform changes
- **Bash**: build commands, git operations, platform toolchain invocations
- **general-purpose**: multi-step research requiring investigation across many files
- **tech-lead-orchestrator**: cross-domain work spanning C++, CMake, Qt/QML, and platform-specific code

Prefer parallel subagent execution for independent tasks. CMake module changes may cascade across platforms — validate the full dependency chain before committing.
