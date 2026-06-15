/*
 * WDK 7.1 CRT compatibility shims for building Qt 5.6.3.
 *
 * The WDK 7.1 CRT headers ship only the ISO underscore-prefixed names for some
 * POSIX functions (e.g. _fstat) and leave the bare POSIX aliases undeclared,
 * unlike the full Visual Studio 2008 CRT. This force-included header restores
 * the few aliases Qt's sources expect. Guarded by _STL70_ so it only affects
 * the WDK build.
 */
#ifndef WDK_COMPAT_H
#define WDK_COMPAT_H

#if defined(_STL70_)

/* WDK 7.1 SDK/DDK headers gate x64 paths on _AMD64_ (a build-system define),
   not the compiler's _M_X64. Derive it so x64 builds see the right layouts. */
#if defined(_M_X64) && !defined(_AMD64_)
#define _AMD64_
#endif

/* Must be defined before <stdlib.h> so rand_s is declared. We force-include
   <stdlib.h> below for the _environ fix, which would otherwise lock in a
   declaration without rand_s before Qt's own _CRT_RAND_S define takes effect. */
#ifndef _CRT_RAND_S
#define _CRT_RAND_S
#endif

#include <sys/stat.h>
#include <time.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

/* The system msvcrt.dll lacks the secure vsnprintf_s. Reproduce its semantics
   on top of _vsnprintf: write at most (sizeOfBuffer-1) chars and ALWAYS
   NUL-terminate (the legacy _vsnprintf does not terminate on exact fill).
   Matches the original mkspec call vsnprintf_s(buf, count, count-1, fmt, ap). */
static __inline int wdk_vsnprintf_s(char *_buf, size_t _bufSize, const char *_fmt, va_list _args)
{
    int written;

    if (!_buf || 0 == _bufSize)
        return -1;

    written = _vsnprintf(_buf, _bufSize - 1, _fmt, _args);
    _buf[_bufSize - 1] = '\0';

    return written;
}

/* The system msvcrt.dll exports neither the _environ data symbol nor the
   __p__environ() accessor, but it does export _get_environ(char***). Route
   _environ through that so QProcess::systemEnvironment() links. */
static __inline char **wdk_get_environ(void)
{
    char **env = 0;

    _get_environ(&env);
    return env;
}
#undef _environ
#define _environ (wdk_get_environ())

/* The system msvcrt.dll lacks the 64-bit stdio offset calls (_ftelli64 /
   _fseeki64, added in newer CRTs) but exports fgetpos/fsetpos with a 64-bit
   fpos_t. Reimplement the 64-bit offset calls on top of those. */
static __inline __int64 wdk_ftelli64(FILE *_f)
{
    fpos_t pos;

    if (0 != fgetpos(_f, &pos))
        return -1;

    return (__int64)pos;
}
#define _ftelli64 wdk_ftelli64

static __inline int wdk_fseeki64(FILE *_f, __int64 _off, int _origin)
{
    fpos_t base = 0;

    if (SEEK_CUR == _origin)
    {
        if (0 != fgetpos(_f, &base))
            return -1;
    }
    else if (SEEK_END == _origin)
    {
        if (0 != fseek(_f, 0, SEEK_END))
            return -1;
        if (0 != fgetpos(_f, &base))
            return -1;
    }

    {
        fpos_t target = base + _off;
        return fsetpos(_f, &target);
    }
}
#define _fseeki64 wdk_fseeki64

/* WDK declares _fstat + struct stat, but not the POSIX fstat alias.
   struct stat and struct _stat share the same layout in the MSVC CRT. */
static __inline int wdk_fstat_compat(int _fd, struct stat *_st)
{
    return _fstat(_fd, (struct _stat *)_st);
}
#define fstat wdk_fstat_compat

/* The system msvcrt.dll lacks the _get_timezone/_get_tzname accessors (added in
   newer CRTs) but still exports the legacy _timezone/_tzname globals. Reimplement
   the accessors on top of those globals. */
static __inline errno_t wdk_get_timezone(long *_tz)
{
    if (!_tz)
        return 22; /* EINVAL */

    *_tz = _timezone;
    return 0;
}
#define _get_timezone wdk_get_timezone

static __inline errno_t wdk_get_tzname(size_t *_ret, char *_buf, size_t _sz, int _idx)
{
    const char *src = _tzname[_idx];
    size_t len = strlen(src) + 1;

    if (_buf && _sz > 0)
    {
        strncpy(_buf, src, _sz);
        _buf[_sz - 1] = '\0';
    }
    if (_ret)
        *_ret = len;

    return 0;
}
#define _get_tzname wdk_get_tzname

/* The system msvcrt.dll exports _localtime32_s/_localtime64_s but not the
   generic localtime_s. Bundled SQLite calls localtime_s; provide it mapping to
   the size-correct real function (value-identical to the secure CRT call). */
static __inline errno_t localtime_s(struct tm *_tm, const time_t *_t)
{
#ifdef _USE_32BIT_TIME_T
    return _localtime32_s(_tm, (const __time32_t *)_t);
#else
    return _localtime64_s(_tm, (const __time64_t *)_t);
#endif
}

#endif /* _STL70_ */

#endif /* WDK_COMPAT_H */
