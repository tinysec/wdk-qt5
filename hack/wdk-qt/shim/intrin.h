/*
 * Minimal self-contained <intrin.h> for the WDK 7.1 toolchain.
 *
 * WDK 7.1 ships the per-ISA SSE headers (emmintrin.h / xmmintrin.h / mmintrin.h)
 * but not the umbrella <intrin.h> that full Visual Studio provides. Qt 5.6
 * unconditionally includes <intrin.h> on MSVC (qnumeric_p.h, qsimd_p.h).
 *
 * This shim declares only the compiler intrinsics Qt 5.6 qtbase references on
 * x86. All are cl 15.00 (VS2008 SP1) built-ins, so no import library is needed.
 * It is fully self-contained (no Visual Studio dependency) so it works in CI
 * where only the WDK is installed.
 */
#ifndef _WDK_INTRIN_SHIM_H
#define _WDK_INTRIN_SHIM_H

/* SSE/SSE2 types and intrinsics (__m128i, _mm_*), provided by the WDK. */
#include <emmintrin.h>

/* WDK's emmintrin.h lacks the SSE cast intrinsics, but cl 15.00 reserves the
   names as builtins (so a same-name function is rejected with C2169 while a use
   without a declaration is C3861). Provide them as macros over differently-named
   helpers: the preprocessor rewrites the call before intrinsic resolution. The
   union is a pure bit reinterpretation -- semantically identical to the real
   _mm_cast* intrinsics. */
static __inline __m128i wdk_castps_si128(__m128 _a)
{
    union { __m128 f; __m128i i; } u; u.f = _a; return u.i;
}
static __inline __m128 wdk_castsi128_ps(__m128i _a)
{
    union { __m128i i; __m128 f; } u; u.i = _a; return u.f;
}
static __inline __m128i wdk_castpd_si128(__m128d _a)
{
    union { __m128d d; __m128i i; } u; u.d = _a; return u.i;
}
static __inline __m128d wdk_castsi128_pd(__m128i _a)
{
    union { __m128i i; __m128d d; } u; u.i = _a; return u.d;
}
static __inline __m128d wdk_castps_pd(__m128 _a)
{
    union { __m128 f; __m128d d; } u; u.f = _a; return u.d;
}
static __inline __m128 wdk_castpd_ps(__m128d _a)
{
    union { __m128d d; __m128 f; } u; u.d = _a; return u.f;
}
#define _mm_castps_si128(a)  wdk_castps_si128(a)
#define _mm_castsi128_ps(a)  wdk_castsi128_ps(a)
#define _mm_castpd_si128(a)  wdk_castpd_si128(a)
#define _mm_castsi128_pd(a)  wdk_castsi128_pd(a)
#define _mm_castps_pd(a)     wdk_castps_pd(a)
#define _mm_castpd_ps(a)     wdk_castpd_ps(a)

#ifdef _M_X64
/* WDK emmintrin.h lacks the 64-bit int <-> __m128i moves (x64-only, used by
   qstring). _mm_cvtsi64_si128 puts the int64 in the low qword and zeroes the
   high qword; _mm_cvtsi128_si64 returns the low qword. */
static __inline __m128i wdk_cvtsi64_si128(__int64 _a)
{
    union { __int64 ll[2]; __m128i v; } u; u.ll[0] = _a; u.ll[1] = 0; return u.v;
}
static __inline __int64 wdk_cvtsi128_si64(__m128i _a)
{
    union { __m128i v; __int64 ll[2]; } u; u.v = _a; return u.ll[0];
}
#define _mm_cvtsi64_si128(a)  wdk_cvtsi64_si128(a)
#define _mm_cvtsi128_si64(a)  wdk_cvtsi128_si64(a)
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Bit scan (qsimd_p.h, qalgorithms.h). */
unsigned char _BitScanForward(unsigned long *_Index, unsigned long _Mask);
unsigned char _BitScanReverse(unsigned long *_Index, unsigned long _Mask);
#pragma intrinsic(_BitScanForward)
#pragma intrinsic(_BitScanReverse)

/* CPU feature detection (qsimd.cpp). __cpuidex requires cl 15.00.30729 SP1. */
void __cpuid(int _CpuInfo[4], int _Function);
void __cpuidex(int _CpuInfo[4], int _Function, int _SubFunction);

/* Read time-stamp counter (qbenchmarkmeasurement.cpp on x64, where MSVC has no
   inline asm). Also declared in winnt.h; re-declaring an intrinsic is harmless. */
unsigned __int64 __rdtsc(void);
#pragma intrinsic(__rdtsc)

#ifdef _M_X64
/* x64-only intrinsics Qt uses on 64-bit (qnumeric_p.h, qalgorithms.h). */
unsigned char _BitScanForward64(unsigned long *_Index, unsigned __int64 _Mask);
unsigned char _BitScanReverse64(unsigned long *_Index, unsigned __int64 _Mask);
unsigned __int64 _umul128(unsigned __int64 _Mul1, unsigned __int64 _Mul2, unsigned __int64 *_HighProduct);
#pragma intrinsic(_BitScanForward64)
#pragma intrinsic(_BitScanReverse64)
#pragma intrinsic(_umul128)
#endif

/* Byte swap (qendian / qhash). */
unsigned short  _byteswap_ushort(unsigned short _Short);
unsigned long   _byteswap_ulong(unsigned long _Long);
unsigned __int64 _byteswap_uint64(unsigned __int64 _Int64);
#pragma intrinsic(_byteswap_ushort)
#pragma intrinsic(_byteswap_ulong)
#pragma intrinsic(_byteswap_uint64)

#ifdef __cplusplus
}
#endif

#endif /* _WDK_INTRIN_SHIM_H */
