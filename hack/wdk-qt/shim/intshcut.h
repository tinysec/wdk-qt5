/*
 * Stub <intshcut.h> for the WDK 7.1 toolchain.
 *
 * The WDK 7.1 user-mode SDK (inc/api) omits the Internet-Shortcut shell header
 * that the full Windows SDK provides. Qt 5.6's qstandardpaths_win.cpp includes
 * it but does not reference any symbol from it, so an empty stub satisfies the
 * include without pulling in the newer Windows SDK (which uses incompatible SAL
 * annotations against the WDK headers).
 */
#ifndef _WDK_INTSHCUT_STUB_H
#define _WDK_INTSHCUT_STUB_H
#endif
