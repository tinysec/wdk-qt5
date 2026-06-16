# wdk-qt5

**Qt 5.6.3 built with the WDK 7.1 toolchain — depends only on the system
`msvcrt.dll`, runs on Windows XP, no Visual C++ redistributable, and consumable
straight from CMake via `find_package(Qt5)` / FetchContent.**

[![build](https://github.com/tinysec/wdk-qt5/actions/workflows/build.yml/badge.svg)](https://github.com/tinysec/wdk-qt5/actions/workflows/build.yml)
[![release](https://img.shields.io/github/v/release/tinysec/wdk-qt5?sort=semver)](https://github.com/tinysec/wdk-qt5/releases)
[![license](https://img.shields.io/badge/license-LGPLv2.1%2FLGPLv3-blue)](LICENSE.LGPLv21)

## Overview

Qt 5.6.3 is the last Qt release that supports Windows XP. This repository builds
a **trimmed `qtbase`** (the desktop-widgets essentials, no OpenGL/DBus/SQL) plus
**`qtcharts`** and the **`lrelease` / `lupdate`** i18n tools with the **Windows
Driver Kit 7.1** toolchain (`cl 15.00`, the VS2008 SP1 compiler), using a recipe
that links the **dynamic system `msvcrt.dll`** for the C runtime and **statically
links the C++ standard library**. The result:

- depends only on DLLs that ship with Windows (`msvcrt.dll`, `kernel32.dll`, …) —
  **no `msvcr90.dll` / `msvcp90.dll`, no VC++ redistributable to install**;
- is built **without Visual Studio** — the WDK 7.1 toolchain is installed on a
  stock GitHub-hosted runner by [`tinysec/setup-wdk7`](https://github.com/tinysec/setup-wdk7);
- is published as **prebuilt CMake packages** that downstream projects pull with
  FetchContent, or can be **built from source** with the same one switch.

## Features

- ✅ **Zero redistributable** — the only C runtime dependency is the system
  `msvcrt.dll`; PE subsystem version `5.00`, so binaries load on Windows XP.
- ✅ **A minimal desktop-widgets toolkit + Charts** — `Core`, `Gui`, `Widgets`
  and **`Charts`**, plus `Network`, `Xml`, `Concurrent`, `Test`, `PrintSupport`;
  the `qwindows` platform plugin and image-format plugins; and the `qmake` /
  `moc` / `rcc` / `uic` tools. **OpenGL, DBus and SQL are disabled**, and the
  QML/Quick, Multimedia, WebEngine, SVG, … modules are not built — this is a
  trimmed UI library, not the full Qt.
- ✅ **i18n** — runtime `QTranslator` / `QLocale` / `tr()` is in `Core`; the
  package also ships `lrelease` / `lupdate` to compile (`.ts` → `.qm`) and
  extract (`source` → `.ts`) translations.
- ✅ **Static by default** — links Qt into one self-contained `.exe` that depends
  only on `msvcrt.dll`; set `QT5_SHARED=ON` for DLLs. Four prebuilt variants:
  `i386` / `amd64` × `shared` / `static`.
- ✅ **CMake-native** — relocatable `Qt5Config.cmake` files; `find_package(Qt5)`,
  `AUTOMOC` / `AUTORCC` / `AUTOUIC` all work.
- ✅ **Prebuilt or from source** — one boolean (`QT5_FROM_SOURCE`) switches
  between downloading a release asset and building locally.
- ✅ **Floating release** — a `v5.6.3` alias tag/release always points at the
  latest CI build with **stable asset URLs**.
- ✅ **No Visual Studio required**, on the build side or the consumer side.

## Prebuilt packages

Each CI build publishes:

| Release | Marked | Asset names | Use for |
|---|---|---|---|
| `v5.6.3.<build>` | latest | `qt-v5.6.3.<build>-wdk7-<link>-<arch>.zip` | reproducible pin |
| `v5.6.3` (alias) | — | `qt-wdk7-<link>-<arch>.zip` (stable URL) | track latest |

`<link>` is `shared` or `static`; `<arch>` is `i386` or `amd64`. Stable URL form:

```
https://github.com/tinysec/wdk-qt5/releases/download/v5.6.3/qt-wdk7-<link>-<arch>.zip
```

Each `.zip` is an install prefix (`bin/`, `lib/`, `include/`, `plugins/`,
`lib/cmake/`).

## Use in CMake

Consuming Qt requires the **setup-wdk7 toolchain** (so your own code is built
with the same WDK 7.1 CRT recipe) plus this repo's `cmake/qt5.cmake` helper.

### 1. Configure with the WDK7 toolchain

In your CI / build command:

```bash
cmake -S . -B build -G "NMake Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE=<setup-wdk7>/cmake/wdk7.cmake \
  -DWDK7_ARCH=i386            # or amd64
cmake --build build
```

On GitHub Actions, add the toolchain step:

```yaml
- uses: tinysec/setup-wdk7@v1
  id: wdk7
# then pass ${{ steps.wdk7.outputs.toolchain-file }} as CMAKE_TOOLCHAIN_FILE
```

### 2. Pull Qt in your `CMakeLists.txt`

Vendor `cmake/qt5.cmake` (or `file(DOWNLOAD …)` it), then:

```cmake
include(qt5.cmake)

# Default is STATIC: one self-contained .exe depending only on msvcrt.dll, which
# is the point of this XP/zero-redist build. Set QT5_SHARED=ON for DLLs.
qt5_provide()             # QT5_ARCH follows WDK7_ARCH; sets CMAKE_PREFIX_PATH

find_package(Qt5 5.6 REQUIRED COMPONENTS Core Widgets)

set(CMAKE_AUTOMOC ON)
add_executable(app WIN32 main.cpp)
target_link_libraries(app Qt5::Core Qt5::Widgets)
qt5_deploy(app)           # copies Qt DLLs next to the exe (no-op when static)

# A static Qt build needs the platform plugin imported explicitly:
if(NOT QT5_SHARED)
    target_link_libraries(app Qt5::QWindowsIntegrationPlugin)
    # and Q_IMPORT_PLUGIN(QWindowsIntegrationPlugin) in your source
endif()
```

Static (the default) links Qt into the executable: a single `app.exe` that
depends only on the system `msvcrt.dll` — nothing to deploy. With `QT5_SHARED=ON`
you get Qt DLLs; `qt5_deploy(app)` then copies them (and the platform plugin)
next to the `.exe` so it runs without putting the Qt `bin/` on `PATH`.

### Options

| Option | Type | Default | Meaning |
|---|---|---|---|
| `QT5_SHARED` | BOOL | `OFF` | `OFF` = static self-contained .exe, `ON` = shared DLLs |
| `QT5_FROM_SOURCE` | BOOL | `OFF` | `OFF` = download prebuilt, `ON` = build from source |
| `QT5_ARCH` | STRING | follows `WDK7_ARCH` | `i386` or `amd64` |

### Translations (i18n)

Runtime translation is built in (`QTranslator`, `QLocale`, `tr()`). To author
your own translations, the package ships `lrelease` / `lupdate` in `bin/`:

```bash
lupdate main.cpp -ts app_zh_CN.ts   # extract tr() strings into a .ts
# ... translate app_zh_CN.ts ...
lrelease app_zh_CN.ts               # compile the .ts into app_zh_CN.qm
```

## Build it yourself

The build is driven by plain scripts under `hack/wdk-qt/` (each respects
`QT_ARCH` = `i386`/`amd64` and `QT_LINK` = `shared`/`static`):

```bat
set QT_ARCH=i386
set QT_LINK=static
hack\wdk-qt\clean-build.bat     :: configure + build qtbase into build-wdk-qtbase-i386-static
hack\wdk-qt\install.bat         :: nmake install (+ patch static CMake deps, drop QtSql)
hack\wdk-qt\build-qtcharts.bat  :: build Qt5Charts into the same prefix
hack\wdk-qt\build-i18n.bat      :: build lrelease/lupdate into the prefix bin/
```

The WDK is located via `W7BASE` / `WDK7_ROOT` (set by setup-wdk7), falling back
to `C:\WinDDK\7600.16385.1`.

## How it works

- A custom mkspec `win32-wdk7-msvc2008` plus a force-included `wdk-compat.h`
  supply the CRT shims the WDK omits (the system `msvcrt.dll` is VC6-era), and
  link `ntstc_msvcrt.lib` for the statically-linked C++ standard library.
- Self-contained shim headers replace SDK/compiler headers the WDK lacks
  (`intrin.h`, `windns.h`, `commoncontrols.h`, …).
- A handful of small, guarded `qtbase` source patches handle gaps in the old
  STL70 headers and the 32-bit-`time_t` CRT.
- `configure` disables OpenGL, DBus and SQL (`-no-opengl -no-dbus
  -no-sql-sqlite`); the QtSql lib body, which Qt 5.6 always builds, is deleted
  after install. `Network` and `Xml` are kept (useful for GUI apps; note no
  HTTPS, since `-no-openssl`).
- `qtcharts` is vendored and built with the same mkspec/shims (only `syncqt` is
  needed for its forwarding headers). For the static build, the plugin import
  targets are patched so a GUI app links the platform plugin cleanly.
- The i18n tools come from the vendored `qttools/src/linguist`; `lupdate` gets
  an `asInvoker` manifest force-embedded so Windows installer-detection does not
  flag its `update` name and demand elevation.

## License

Qt 5.6.3 is licensed under LGPLv2.1 / LGPLv3 (and GPL); see the `LICENSE.*`
files. The build tooling in this repository is provided under the same terms.
