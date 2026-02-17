# QtQuickTemplate

A cross-platform **Qt 6 / Qt Quick (QML)** starter repo that aims to be “just enough structure” to begin a real app:

- A clean QML app shell with **portrait + landscape** layouts and a tiny navigation controller.
- A centralized **Theme** singleton (design tokens) and a custom **Qt Quick Controls 2 style** (`AppStyle`).
- A place for reusable native/C++ code (including a small **C++20 module** example library).
- Platform packaging hooks for **Android, Windows, macOS, and Linux**.
- Optional **QDoc** targets for documentation generation.

---

## What you get out of the box

### UI & QML architecture
- `Main.qml` is the `ApplicationWindow` entry point.
- A `NavigationController` swaps pages via a shared `Loader`.
- Two layout templates:
  - `MainPortraitLayout.qml` (header → content → footer)
  - `MainLandscapeLayout.qml` (side column for header/footer + content on the right)
- A sample set of pages (`Home`, `SamplePage`, `StyleShowcase`) and simple `Header`/`Footer` components.

### Styling
- `AppTheme` module: `Theme.qml` singleton holds colors, typography, spacing, radii, animations, etc.
- `AppStyle` module: a custom Qt Quick Controls 2 style that overrides common controls (Button, TextField, etc.).
- Style selection happens in C++ before QML loads:
  - `QQuickStyle::setStyle("AppStyle")`
  - fallback style: `"Basic"`

### Native/C++ structure
- `src/main/common/` holds the application entry point and shared C++ code.
- `include/main/common/` holds the public headers for that code.
- Platform specialization lives next to the app:
  - `src/main/android/` contains Android-specific C++ glue.

### Platform bootstrapping (Android splash)
- Android uses a `QtActivity` subclass that shows a lightweight overlay and fades it out when Qt renders its first frame.
- C++ calls into the Android activity on the first rendered frame (`onFirstFrame(...)`).

### Docs
- A `docs` target generates HTML documentation via QDoc (if `qdoc` is found).
- The `libs/helloworld` sample library also has its own QDoc target.

---

## Repository layout

```text
.
├── CMakeLists.txt
├── conanfile.py
├── README_STYLE.md
├── doc/
│   └── qtquicktemplate.qdocconf
├── include/
│   └── main/
│       └── common/
│           ├── app_info.h
│           └── platform_init.h
├── libs/
│   ├── CMakeLists.txt                 # auto-adds child lib dirs
│   └── helloworld/                    # sample C++20 module library
│       ├── CMakeLists.txt
│       ├── helloworld.cppm
│       ├── include/helloworld.h
│       ├── src/helloworld.cpp
│       └── doc/helloworld.qdocconf
├── platforms/
│   ├── android/                       # Qt Android package source (Gradle project + resources)
│   ├── ios/                           # Qt iOS platform-specific files
│   ├── linux/                         # .desktop + appstream metainfo templates
│   ├── macos/                         # Info.plist (bundle metadata)
│   └── windows/                       # .rc + manifest
├── qml/
│   ├── Main.qml
│   ├── NavigationController.qml
│   ├── organisms/
│   │   ├── Header.qml
│   │   └── Footer.qml
│   ├── pages/
│   │   ├── Home.qml
│   │   ├── SamplePage.qml
│   │   └── StyleShowcase.qml
│   ├── templates/
│   │   ├── MainPortraitLayout.qml
│   │   └── MainLandscapeLayout.qml
│   ├── theme/
│   │   └── Theme.qml                  # AppTheme singleton (design tokens)
│   └── AppStyle/                      # Qt Quick Controls 2 style overrides
│       ├── Button.qml
│       ├── CheckBox.qml
│       ├── ComboBox.qml
│       ├── GroupBox.qml
│       ├── MenuItem.qml
│       ├── ProgressBar.qml
│       ├── ScrollBar.qml
│       ├── Slider.qml
│       ├── Switch.qml
│       ├── TabButton.qml
│       ├── TextField.qml
│       └── ToolTip.qml
└── src/
    └── main/
        ├── common/
        │   ├── main.cpp
        │   ├── app_info.cpp
        │   └── platform_init_default.cpp
        └── android/
            └── platform_init_android.cpp
```

---

## Build prerequisites

- **Qt 6.10+** (Core, Quick, QuickControls2, Qml)
- **CMake 3.28+**
- A C++20-capable compiler
- If using **Clang + C++20 modules**, you need `clang-scan-deps` available (the project tries hard to find it automatically, including from Android NDK paths).

Optional:
- **Conan 2** (the repo includes a basic `conanfile.py`)

---

## Building (Desktop)

### Plain CMake

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
```

Run (examples):
- macOS/Windows typically produce `QtQuickTemplate` as an app/bundle.
- On Linux (and other non-Apple UNIX), the output name is prefixed with `app` (e.g. `appQtQuickTemplate`).

### Using Conan (optional)

This recipe currently doesn’t declare third-party deps, but it wires up `CMakeToolchain` + `CMakeDeps`, so adding deps later is painless.

```bash
conan install . -s build_type=Debug --build=missing -of build/conan
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=build/conan/conan_toolchain.cmake
cmake --build build -j
```

---

## Building (Android)

This repo is set up to be built using a Qt Android kit (Qt Creator is the smoothest path):

- `QT_ANDROID_PACKAGE_SOURCE_DIR` points at `platforms/android/`, so Qt’s Android deployment tooling will pick up the Gradle project and resources automatically.
- The Android activity shows a splash overlay and removes it once Qt reports its first rendered frame.

If you need to change the Android app id / namespace, start in:
- `platforms/android/build.gradle` (namespace)
- `platforms/android/src/main/kotlin/.../MainActivity.kt` (package)
- `platforms/android/AndroidManifest.xml`
- `platforms/android/version.properties` (versionName/versionCode)

---

## QML modules & resource layout

This project intentionally **flattens QML resource paths** using `QT_RESOURCE_ALIAS` so that pages/components can be referenced by simple filenames (e.g. `Qt.resolvedUrl("Home.qml")`) even if they live under `qml/pages/` in the source tree.

Modules:
- `AppTheme` → `Theme.qml` singleton
- `AppStyle` → custom controls style (depends on `AppTheme`)
- `QtQuickTemplate` → main application QML

---

## Documentation (QDoc)

If `qdoc` is available in your Qt installation, you’ll get build targets:

- Generate app docs:
  ```bash
  cmake --build build --target docs
  ```

- Generate `helloworld` library docs:
  ```bash
  cmake --build build --target helloworld_docs
  ```

The main QDoc configuration lives in `doc/qtquicktemplate.qdocconf`.

---

## Customizing this template

A quick checklist you’ll almost certainly want to do:

- Rename the project: `project(QtQuickTemplate ...)` in `CMakeLists.txt`
- Update `app.setOrganizationName("YourOrganization")` and other branding strings in `main.cpp`
- Replace package identifiers:
  - Linux metainfo + icon id: `dev.crowell.app.template`
  - macOS bundle id: `CFBundleIdentifier`
  - Android namespace/package
- Swap icons:
  - `platforms/windows/app.ico`
  - `platforms/macos/app.icns` (optional)
  - `platforms/linux/icons/*` (optional)
- Decide on a license and add a LICENSE file (some platform metadata currently contains placeholders)

---

## Style notes

See `README_STYLE.md` for a deeper dive into the Theme/AppStyle approach and how the controls are overridden.

---

## Contributing

PRs welcome—keep changes small, keep the template sharp, and try not to introduce “magic” unless it removes more pain than it adds.
