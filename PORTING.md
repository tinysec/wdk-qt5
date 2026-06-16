# Porting the WDK7 build to other Qt versions

## Highest supported version: Qt 5.6.x

The WDK 7.1 toolchain ships `cl 15.00.30729` — the **Visual Studio 2008 SP1**
compiler (MSVC 9.0). That fixes the ceiling:

| Qt version | Min MSVC | C++11 required | WDK7 (cl 15.00 / VS2008) |
|---|---|---|---|
| **5.6.x** (5.6.3 = last) | 2008 | no | ✅ builds (this repo) |
| 5.7+ | 2013 | **yes** | ❌ impossible — cl 15.00 has no C++11 |

Qt **5.7 made C++11 mandatory and raised the minimum compiler to MSVC 2013**, so
no amount of patching makes 5.7+ build with the VS2008-era WDK7 compiler.

This lines up with the XP story: **Qt 5.6 is also the last Qt that supports
Windows XP**. So **5.6.3 is simultaneously the highest VS2008-compilable and the
last XP-compatible Qt** — it is the sweet spot, not an arbitrary choice.

Older 5.x (5.5, 5.4, …) also compile with VS2008 and the same method applies,
but there is rarely a reason to go below 5.6.3.

## What is portable, and how to apply it

The build splits into **version-independent drop-in files** and a **tiny source
patch**.

### 1. Drop-in (copy as-is into the target Qt tree / repo)

These fix WDK-toolchain gaps, not Qt-version specifics, so they are reusable:

- `qtbase/mkspecs/win32-wdk7-msvc2008/` — the mkspec, `qplatformdefs.h`, and the
  force-included `wdk-compat.h` (CRT shims).
- `hack/wdk-qt/` — env / configure / build / install scripts, the shim headers
  (`shim/intrin.h`, `windns.h`, `commoncontrols.h`, `intshcut.h`,
  `comsupp_stub.cpp`), and `patch-static-cmake-deps.py`.
- `cmake/qt5.cmake` — the downstream consumer helper.
- `.github/workflows/build.yml` — the CI matrix + floating-release pipeline.

### 2. Source patch (4 files in `qtbase/`)

Apply `hack/wdk-qt/qtbase-wdk7.patch`:

```bash
git apply hack/wdk-qt/qtbase-wdk7.patch        # from the repo root
```

If it does not apply cleanly against a different Qt version (line context
drift), redo these four small, guarded edits by hand — all are no-ops for other
toolchains:

1. **`qtbase/qmake/Makefile.win32`** — add a `win32-wdk7-msvc2008` branch to the
   qmake-bootstrap compiler switch (stl70 defines + `ntstc_msvcrt` link), and
   make `LFLAGS` include the new `LFLAGS_CRT`.
2. **`qtbase/src/corelib/global/qcompilerdetection.h`** — guard the two
   `stdext::make_*_array_iterator` defines with `&& !defined(_STL70_)` so the
   generic raw-pointer fallback is used (WDK stl70 lacks those helpers).
3. **`qtbase/src/corelib/tools/qdatetime.cpp`** — under `_USE_32BIT_TIME_T`, copy
   the `time_t` into a `__time64_t` before calling `_localtime64_s` (WDK defaults
   `time_t` to 32-bit).
4. **`qtbase/src/plugins/platforms/windows/windows.pro`** — add
   `comsupp_stub.cpp` to `SOURCES`, guarded by
   `contains(QMAKE_XSPEC, win32-wdk7-msvc2008)`.

### 3. Expect a few new gaps per version

Each Qt version touches a slightly different slice of the STL70 / CRT / SDK
surface. When a new version hits an unresolved symbol or missing header, fix it
the same way the existing shims do: add the missing declaration to
`hack/wdk-qt/shim/` or `wdk-compat.h`, or a small `_STL70_`-guarded source patch.
The categories are always the same — old STL70 missing a feature, the system
`msvcrt.dll` missing a newer CRT function, or the WDK SDK missing a header.

## Updating CI for a new version

In `.github/workflows/build.yml` change `VERSION_MAJOR/MINOR/PATCH`, and in
`cmake/qt5.cmake` change `QT5_VERSION` / `QT5_RELEASE` defaults. The asset names
and floating-alias logic are already version-parameterized.
