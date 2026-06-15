/*
 * Replacement for the one comsupp.lib symbol Qt's windows plugin needs.
 *
 * comutil.h's _bstr_t/_variant_t call _com_issue_error() on failure; it lives in
 * comsupp.lib, which the WDK 7.1 toolchain lacks. This reproduces the real
 * behavior exactly: throw a _com_error built from the HRESULT (the build has
 * C++ exceptions enabled). Constructing/throwing _com_error needs only its
 * inline constructor, so no other comsupp symbol is pulled in.
 */
#include <comdef.h>

void __stdcall _com_issue_error(HRESULT hr)
{
    throw _com_error(hr);
}
