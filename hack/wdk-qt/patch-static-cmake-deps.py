#!/usr/bin/env python
# Inject static link dependencies into Qt 5.6 CMake configs.
#
# Qt 5.6's generated Qt5<Module>Config.cmake hardcodes
#   set(_Qt5<Module>_LIB_DEPENDENCIES "")
# for STATIC builds, so find_package(Qt5) consumers don't link the module's
# static deps (qtpcre, ws2_32, opengl32, ...). Those deps ARE listed in the
# matching lib/Qt5<Module>.prl (QMAKE_PRL_LIBS). This script reads each .prl and
# fills _Qt5<Module>_LIB_DEPENDENCIES so static consumption works. (Qt 5.7+ fixed
# this upstream.) Run only on the static install prefix, after nmake install.
#
# Usage: python patch-static-cmake-deps.py <install-prefix>

import os
import re
import sys
import glob


def is_absolute_path(token):
    """True if the token is an absolute filesystem path (Windows drive or UNIX)."""
    normalized = token.replace("\\", "/")

    if re.match(r"^[A-Za-z]:/", normalized) is not None:
        return True

    return normalized.startswith("/")


def convert_prl_libs(raw, prefix_var):
    """Convert a QMAKE_PRL_LIBS string into a CMake link-dependency list."""
    items = []

    for token in raw.split():
        # 1. qmake's QT_INSTALL_LIBS placeholder -> the relocatable prefix var.
        if token.startswith("-L"):
            continue  # library search dir, redundant once we give full paths

        # An absolute path here is always one of Qt's own build-tree libs
        # (Qt5*.lib, qtpcre.lib, ...). Those are already pulled in transitively
        # via the Qt5:: module targets already present in the dependency list,
        # so dropping them loses nothing and keeps the shipped config
        # relocatable. A module's genuinely-owned internal libs instead arrive
        # via the $$[QT_INSTALL_LIBS] token below and stay prefix-relative.
        if is_absolute_path(token):
            continue

        if "$$[QT_INSTALL_LIBS]" in token:
            tail = token.split("]", 1)[1].lstrip("\\/")  # e.g. qtpcre.lib
            items.append("${%s}/lib/%s" % (prefix_var, tail))
            continue

        # 2. -lfoo  ->  foo
        if token.startswith("-l"):
            items.append(token[2:])
            continue

        # 3. plain system import lib (kernel32.lib, ws2_32.lib, ...) kept as-is.
        items.append(token)

    return items


def patch_config(config_path, prefix):
    name = os.path.basename(config_path)  # Qt5CoreConfig.cmake
    module = name[len("Qt5"):-len("Config.cmake")]  # Core

    prl_path = os.path.join(prefix, "lib", "Qt5%s.prl" % module)
    if not os.path.exists(prl_path):
        return False

    raw_libs = ""
    with open(prl_path, "r", encoding="utf-8", errors="replace") as prl_file:
        for line in prl_file:
            if line.startswith("QMAKE_PRL_LIBS"):
                raw_libs = line.split("=", 1)[1].strip()
                break

    if 0 == len(raw_libs):
        return False

    prefix_var = "_qt5%s_install_prefix" % module
    deps = convert_prl_libs(raw_libs, prefix_var)

    # Drop inter-module Qt libs (Qt5Core.lib ...) by basename: those are already
    # expressed as Qt5:: targets in the existing list. Keep only system/3rdparty.
    def is_qt_module_lib(item):
        base = item.replace("\\", "/").split("/")[-1]
        return re.match(r"(?i)Qt5[A-Za-z]+\.lib$", base) is not None

    deps = [d for d in deps if not is_qt_module_lib(d)]
    if 0 == len(deps):
        return False

    with open(config_path, "r", encoding="utf-8", errors="replace") as config_file:
        text = config_file.read()

    # Match the dependency line whatever its current content (empty for Core,
    # "Qt5::Core;..." for higher modules) and APPEND our deps to it.
    pattern = re.compile(
        r'set\(_Qt5%s_LIB_DEPENDENCIES "([^"]*)"\)' % re.escape(module))
    match = pattern.search(text)
    if match is None:
        return False

    existing = match.group(1)
    merged = [item for item in existing.split(";") if 0 != len(item)]

    added = []
    for dep in deps:
        if dep not in merged:
            merged.append(dep)
            added.append(dep)

    if 0 == len(added):
        return False  # already patched (idempotent re-run)

    replacement = 'set(_Qt5%s_LIB_DEPENDENCIES "%s")' % (module, ";".join(merged))
    text = text[:match.start()] + replacement + text[match.end():]

    with open(config_path, "w", encoding="utf-8") as config_file:
        config_file.write(text)

    print("patched %s += %s" % (module, ";".join(added)))
    return True


def patch_plugin(plugin_cmake_path, prefix):
    """Inject a static plugin's private static-lib deps into its import target.

    Qt 5.6 generates Qt5Gui_<Plugin>.cmake with only the plugin's own .lib and no
    link interface, so a static consumer that imports e.g.
    Qt5::QWindowsIntegrationPlugin is missing Qt5PlatformSupport.lib / Qt5DBus.lib
    (private static libs with no Qt5:: target) and fails to link. Those deps ARE
    listed in the plugin's .prl. Read it and append them as relocatable paths to
    the plugin target's INTERFACE_LINK_LIBRARIES.
    """
    with open(plugin_cmake_path, "r", encoding="utf-8", errors="replace") as plugin_file:
        text = plugin_file.read()

    if "_qt5_plugin_deps_patched" in text:
        return False  # already patched (idempotent re-run)

    # 1. Plugin target name + its .lib path, e.g. (QWindowsIntegrationPlugin,
    #    "platforms/qwindows.lib"), from the _populate_*_plugin_properties call.
    match = re.search(
        r'_populate_\w+_plugin_properties\(\s*(\w+)\s+\w+\s+"([^"]+)"', text)
    if match is None:
        return False

    plugin_name = match.group(1)
    plugin_rel = match.group(2)

    # 2. Locate the matching .prl next to the plugin .lib under plugins/.
    if plugin_rel.endswith(".lib"):
        plugin_rel = plugin_rel[:-len(".lib")]

    prl_path = os.path.join(prefix, "plugins", plugin_rel + ".prl")
    if not os.path.exists(prl_path):
        return False

    raw_libs = ""
    with open(prl_path, "r", encoding="utf-8", errors="replace") as prl_file:
        for line in prl_file:
            if line.startswith("QMAKE_PRL_LIBS"):
                raw_libs = line.split("=", 1)[1].strip()
                break

    if 0 == len(raw_libs):
        return False

    # 3. The plugin cmake lives in lib/cmake/Qt5<Module>/, whose config defines
    #    _qt5<Module>_install_prefix. Derive it from the directory name.
    module = os.path.basename(os.path.dirname(plugin_cmake_path))[len("Qt5"):]  # Gui
    prefix_var = "_qt5%s_install_prefix" % module

    deps = convert_prl_libs(raw_libs, prefix_var)

    # Keep only the prefix-relative Qt static libs (Qt5PlatformSupport, Qt5DBus,
    # ...): those have no Qt5:: target the consumer could link otherwise. System
    # import libs are already on the consumer's link line.
    deps = [dep for dep in deps if prefix_var in dep]
    if 0 == len(deps):
        return False

    addition = (
        '\n# _qt5_plugin_deps_patched: static private deps with no Qt5:: target\n'
        'set_property(TARGET Qt5::%s APPEND PROPERTY INTERFACE_LINK_LIBRARIES "%s")\n'
        % (plugin_name, ";".join(deps)))

    with open(plugin_cmake_path, "a", encoding="utf-8") as plugin_file:
        plugin_file.write(addition)

    print("patched plugin %s += %s" % (plugin_name, ";".join(deps)))
    return True


def main():
    if len(sys.argv) < 2:
        print("usage: patch-static-cmake-deps.py <install-prefix>")
        return 1

    prefix = sys.argv[1]

    # 1. Module configs (Qt5Core, Qt5Gui, ...): fill _Qt5<Mod>_LIB_DEPENDENCIES.
    config_pattern = os.path.join(prefix, "lib", "cmake", "Qt5*", "Qt5*Config.cmake")
    module_count = 0
    for config_path in glob.glob(config_pattern):
        if patch_config(config_path, prefix):
            module_count += 1

    # 2. Plugin import targets (Qt5Gui_QWindowsIntegrationPlugin, ...): add their
    #    private static-lib deps so a static GUI app links the platform plugin.
    plugin_pattern = os.path.join(prefix, "lib", "cmake", "Qt5*", "Qt5*_*Plugin.cmake")
    plugin_count = 0
    for plugin_path in glob.glob(plugin_pattern):
        if patch_plugin(plugin_path, prefix):
            plugin_count += 1

    print("patched %d module config(s), %d plugin(s)" % (module_count, plugin_count))
    return 0


if __name__ == "__main__":
    sys.exit(main())
