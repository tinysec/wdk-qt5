# qt5.cmake - consume the WDK7-built Qt 5 (point release, e.g. 5.6.3) from CMake.
#
# 5.6.3 is just the specific Qt 5 point release this repo builds; the consumer
# interface is generic Qt5 (matching find_package(Qt5) / Qt5::Core targets).
#
# Options (CMake-idiomatic booleans + a couple of strings):
#   QT5_SHARED       BOOL  (default ON)  ON = shared DLLs, OFF = static libs
#   QT5_FROM_SOURCE  BOOL  (default OFF) OFF = download prebuilt, ON = build here
#   QT5_ARCH         STRING i386|amd64   (default: follows WDK7_ARCH, else ptr size)
#   QT5_VERSION      STRING Qt point release (default 5.6.3)
#   QT5_RELEASE      STRING release tag (default v5.6.3 floating alias; pin vX.Y.Z.N)
#   QT5_REPO         STRING base GitHub repo URL
#   QT5_TOKEN        STRING token for a private-repo download (else GH_/GITHUB_TOKEN)
#
# Usage in the consumer:
#   include(qt5.cmake)
#   qt5_provide()                         # sets CMAKE_PREFIX_PATH
#   find_package(Qt5 5.6 REQUIRED COMPONENTS Core Widgets)
#
# The consumer must also configure with the setup-wdk7 toolchain, e.g.
#   -DCMAKE_TOOLCHAIN_FILE=wdk7.cmake -DWDK7_ARCH=i386
# QT5_ARCH defaults to WDK7_ARCH, so set the arch once on the toolchain.

option(QT5_SHARED      "Use the shared (DLL) Qt build; OFF = static libs" ON)
option(QT5_FROM_SOURCE "Build Qt from source instead of downloading prebuilt" OFF)
set(QT5_ARCH    ""        CACHE STRING "Qt5 arch: i386 | amd64 (default follows WDK7_ARCH)")
set(QT5_VERSION "5.6.3"   CACHE STRING "Qt5 point release built by this repo")
# Default to the FLOATING alias tag: it always points at the latest CI build and
# its asset names are stable, so this URL never changes. Pin a versioned tag
# (e.g. v5.6.3.42) for a reproducible build.
set(QT5_RELEASE "v5.6.3"  CACHE STRING "Prebuilt release tag (alias or versioned)")
set(QT5_REPO    "https://github.com/tinysec/wdk-qt5" CACHE STRING "Repo base URL")
set(QT5_TOKEN   ""        CACHE STRING "GitHub token for a private-repo download")
set_property(CACHE QT5_ARCH PROPERTY STRINGS i386 amd64)

# Resolve the arch: explicit QT5_ARCH > WDK7_ARCH (set for the toolchain) > size.
function(_qt5_resolve_arch out_var)
    set(_arch "${QT5_ARCH}")
    if(_arch STREQUAL "" AND DEFINED WDK7_ARCH AND NOT WDK7_ARCH STREQUAL "")
        set(_arch "${WDK7_ARCH}")
    endif()
    if(_arch STREQUAL "")
        if(DEFINED CMAKE_SIZEOF_VOID_P AND CMAKE_SIZEOF_VOID_P EQUAL 4)
            set(_arch "i386")
        else()
            set(_arch "amd64")
        endif()
    endif()
    if(_arch STREQUAL "x86" OR _arch STREQUAL "Win32")
        set(_arch "i386")
    elseif(_arch STREQUAL "x64")
        set(_arch "amd64")
    endif()
    if(NOT (_arch STREQUAL "i386" OR _arch STREQUAL "amd64"))
        message(FATAL_ERROR "qt5: unsupported QT5_ARCH '${_arch}' (use i386 or amd64)")
    endif()
    set("${out_var}" "${_arch}" PARENT_SCOPE)
endfunction()

function(qt5_provide)
    include(FetchContent)

    _qt5_resolve_arch(_arch)
    if(QT5_SHARED)
        set(_link "shared")
    else()
        set(_link "static")
    endif()

    if(NOT QT5_FROM_SOURCE)
        # 1. Download the matching prebuilt package. The floating alias release
        #    (vX.Y.Z) carries stable asset names; a pinned versioned release
        #    (vX.Y.Z.N) carries build-numbered names.
        if(QT5_RELEASE MATCHES "^v[0-9]+\\.[0-9]+\\.[0-9]+$")
            set(_asset "qt-wdk7-${_link}-${_arch}.7z")
        else()
            set(_asset "qt-${QT5_RELEASE}-wdk7-${_link}-${_arch}.7z")
        endif()

        # Private-repo assets need a token; default it from the environment.
        set(_token "${QT5_TOKEN}")
        if(_token STREQUAL "" AND DEFINED ENV{GH_TOKEN})
            set(_token "$ENV{GH_TOKEN}")
        endif()
        if(_token STREQUAL "" AND DEFINED ENV{GITHUB_TOKEN})
            set(_token "$ENV{GITHUB_TOKEN}")
        endif()

        set(_url "${QT5_REPO}/releases/download/${QT5_RELEASE}/${_asset}")
        if(NOT _token STREQUAL "")
            FetchContent_Declare(qt5_pkg URL "${_url}"
                DOWNLOAD_EXTRACT_TIMESTAMP TRUE
                HTTP_HEADER "Authorization: Bearer ${_token}")
        else()
            FetchContent_Declare(qt5_pkg URL "${_url}"
                DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
        endif()
        FetchContent_MakeAvailable(qt5_pkg)

        set(_prefix "${qt5_pkg_SOURCE_DIR}")
    else()
        # 2. Clone the source and build the requested variant at configure time.
        FetchContent_Declare(qt5_src
            GIT_REPOSITORY "${QT5_REPO}.git"
            GIT_TAG "${QT5_RELEASE}")
        FetchContent_MakeAvailable(qt5_src)

        set(_prefix "${qt5_src_SOURCE_DIR}/build-wdk-qtbase-${_arch}-${_link}/install")
        if(NOT EXISTS "${_prefix}/lib/cmake/Qt5Core/Qt5CoreConfig.cmake")
            message(STATUS "qt5: building ${_arch}/${_link} from source (this takes a while)...")
            execute_process(
                COMMAND "${CMAKE_COMMAND}" -E env "QT_ARCH=${_arch}" "QT_LINK=${_link}"
                        cmd /c "${qt5_src_SOURCE_DIR}/hack/wdk-qt/clean-build.bat"
                RESULT_VARIABLE _rc)
            if(NOT _rc EQUAL 0)
                message(FATAL_ERROR "qt5: source build failed (exit ${_rc}).")
            endif()
        endif()
    endif()

    # The prefix may be at the populated root or inside an install/ subdir.
    if(NOT EXISTS "${_prefix}/lib/cmake/Qt5Core/Qt5CoreConfig.cmake"
       AND EXISTS "${_prefix}/install/lib/cmake/Qt5Core/Qt5CoreConfig.cmake")
        set(_prefix "${_prefix}/install")
    endif()
    if(NOT EXISTS "${_prefix}/lib/cmake/Qt5Core/Qt5CoreConfig.cmake")
        message(FATAL_ERROR "qt5: Qt5 CMake package not found under ${_prefix}")
    endif()

    # 3. Expose the prefix so the consumer's find_package(Qt5) resolves it.
    set(CMAKE_PREFIX_PATH "${_prefix};${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(QT5_PREFIX "${_prefix}" PARENT_SCOPE)
    if(QT5_FROM_SOURCE)
        set(_src "source")
    else()
        set(_src "prebuilt")
    endif()
    message(STATUS "qt5: ${_link}/${_arch} Qt ${QT5_VERSION} from ${_src} at ${_prefix}")
endfunction()
