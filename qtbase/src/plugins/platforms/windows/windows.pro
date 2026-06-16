TARGET = qwindows

QT *= core-private
QT *= gui-private
QT *= platformsupport-private

!wince:LIBS *= -lgdi32

include(windows.pri)

SOURCES +=  \
    main.cpp \
    qwindowsbackingstore.cpp \
    qwindowsgdiintegration.cpp \
    qwindowsgdinativeinterface.cpp

HEADERS +=  \
    qwindowsbackingstore.h \
    qwindowsgdiintegration.h \
    qwindowsgdinativeinterface.h

OTHER_FILES += windows.json

# WDK 7.1 has no comsupp.lib; provide the one _bstr_t symbol the MSAA bridge
# needs. Only for the WDK spec -- toolchains that ship comsupp.lib (VS) would
# otherwise get a duplicate _com_issue_error.
# Match on QMAKESPEC (the full spec path, always set) rather than QMAKE_XSPEC:
# QMAKE_XSPEC is populated from .qmake.cache and comes back empty when qmake is
# re-run for this subdir during the recursive build, which silently dropped the
# stub and broke the qwindows link with an unresolved _com_issue_error.
contains(QMAKESPEC, .*win32-wdk7-msvc2008.*): \
    SOURCES += $$PWD/../../../../../hack/wdk-qt/shim/comsupp_stub.cpp

PLUGIN_TYPE = platforms
PLUGIN_CLASS_NAME = QWindowsIntegrationPlugin
!equals(TARGET, $$QT_DEFAULT_QPA_PLUGIN): PLUGIN_EXTENDS = -
load(qt_plugin)
