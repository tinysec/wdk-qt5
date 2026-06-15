# qt5.cmake - consume the WDK7-built Qt 5 (point release, e.g. 5.6.3) from CMake.
#
# 5.6.3 is just the specific Qt 5 point release this repo builds; the consumer
# interface is generic Qt5 (matching find_package(Qt5) / Qt5::Core targets).
#
# Supports two providers x two link modes (2x2), all behind find_package(Qt5):
#   QT5_PROVIDER = prebuilt (default) | source
#       prebuilt : download a published .7z release asset (fast)
#       source   : git-clone this repo and build it at configure time (slow,
#                  needs the WDK7 toolchain present; allows source customization)
#   QT5_LINK     = shared (default) | static
#   QT5_ARCH     = i386 (default) | amd64
#   QT5_VERSION  = Qt point release built by this repo (default 5.6.3)
#   QT5_RELEASE  = release tag for prebuilt (e.g. v5.6.3.1)
#   QT5_REPO     = base GitHub repo URL (no trailing slash)
#
# Usage in the consumer:
#   include(qt5.cmake)
#   qt5_provide()                         # sets CMAKE_PREFIX_PATH
#   find_package(Qt5 5.6 REQUIRED COMPONENTS Core Widgets)
#
# The consumer must also configure with the setup-wdk7 toolchain and a matching
# arch, e.g.  -DCMAKE_TOOLCHAIN_FILE=wdk7.cmake -DWDK7_ARCH=i386 (for QT5_ARCH=i386).

set(QT5_PROVIDER "prebuilt" CACHE STRING "Qt5 provider: prebuilt | source")
set(QT5_LINK     "shared"   CACHE STRING "Qt5 link mode: shared | static")
set(QT5_ARCH     "i386"     CACHE STRING "Qt5 arch: i386 | amd64")
set(QT5_VERSION  "5.6.3"    CACHE STRING "Qt5 point release built by this repo")
# Default to the FLOATING alias tag: it always points at the latest CI build and
# its asset names are stable (no build number), so this URL never changes. Pin to
# a versioned tag (e.g. v5.6.3.42) for a reproducible build.
set(QT5_RELEASE  "v5.6.3"   CACHE STRING "Prebuilt release tag (alias or versioned)")
set(QT5_REPO     "https://github.com/tinysec/qt563" CACHE STRING "Repo base URL")
set_property(CACHE QT5_PROVIDER PROPERTY STRINGS prebuilt source)
set_property(CACHE QT5_LINK     PROPERTY STRINGS shared static)
set_property(CACHE QT5_ARCH     PROPERTY STRINGS i386 amd64)

function(qt5_provide)
    include(FetchContent)

    if(QT5_PROVIDER STREQUAL "prebuilt")
        # 1. Download the matching prebuilt package. The .7z contains the install
        #    prefix at its root (include/, lib/, bin/, plugins/, lib/cmake/).
        #    The floating alias release (vX.Y.Z) carries stable asset names; a
        #    pinned versioned release (vX.Y.Z.N) carries build-numbered names.
        if(QT5_RELEASE MATCHES "^v[0-9]+\\.[0-9]+\\.[0-9]+$")
            set(_asset "qt-wdk7-${QT5_LINK}-${QT5_ARCH}.7z")
        else()
            set(_asset "qt-${QT5_RELEASE}-wdk7-${QT5_LINK}-${QT5_ARCH}.7z")
        endif()
        FetchContent_Declare(qt5_pkg
            URL "${QT5_REPO}/releases/download/${QT5_RELEASE}/${_asset}")
        FetchContent_MakeAvailable(qt5_pkg)

        set(_prefix "${qt5_pkg_SOURCE_DIR}")
    else()
        # 2. Clone the source and build the requested variant at configure time.
        FetchContent_Declare(qt5_src
            GIT_REPOSITORY "${QT5_REPO}.git"
            GIT_TAG "${QT5_RELEASE}")
        FetchContent_MakeAvailable(qt5_src)

        set(_prefix "${qt5_src_SOURCE_DIR}/build-wdk-qtbase-${QT5_LINK}/install")

        if(NOT EXISTS "${_prefix}/lib/cmake/Qt5Core/Qt5CoreConfig.cmake")
            message(STATUS "qt5: building ${QT5_LINK} variant from source (this takes a while)...")
            execute_process(
                COMMAND "${CMAKE_COMMAND}" -E env "QT_LINK=${QT5_LINK}"
                        cmd /c "${qt5_src_SOURCE_DIR}/hack/wdk-qt/clean-build.bat"
                RESULT_VARIABLE _rc)
            if(NOT _rc EQUAL 0)
                message(FATAL_ERROR "qt5: source build failed (exit ${_rc}).")
            endif()
        endif()
    endif()

    if(NOT EXISTS "${_prefix}/lib/cmake/Qt5Core/Qt5CoreConfig.cmake")
        message(FATAL_ERROR "qt5: Qt5 CMake package not found under ${_prefix}")
    endif()

    # 3. Expose the prefix so the consumer's find_package(Qt5) resolves it.
    set(CMAKE_PREFIX_PATH "${_prefix};${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(QT5_PREFIX "${_prefix}" PARENT_SCOPE)
    message(STATUS "qt5: using ${QT5_PROVIDER} ${QT5_LINK}/${QT5_ARCH} Qt ${QT5_VERSION} at ${_prefix}")
endfunction()
