#include "../win32-msvc2008/qplatformdefs.h"

/* WDK 7.1 system msvcrt.dll lacks vsnprintf_s; route to wdk_vsnprintf_s (in
   wdk-compat.h), which reproduces its bound + always-NUL-terminate semantics. */
#undef QT_VSNPRINTF
#define QT_VSNPRINTF(buffer, count, format, arg) \
    wdk_vsnprintf_s(buffer, count, format, arg)
