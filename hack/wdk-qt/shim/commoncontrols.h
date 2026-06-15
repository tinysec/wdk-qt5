/*
 * <commoncontrols.h> for the WDK 7.1 toolchain (omitted from its user-mode SDK).
 *
 * Provides the real IImageList COM interface so qwindowstheme.cpp keeps its
 * SHGetImageList high-resolution shell-icon path (guarded by
 * __IImageList_INTERFACE_DEFINED__) instead of degrading to ExtractIconEx.
 *
 * The interface (method order/signatures) and the two structs are copied
 * verbatim from the Windows SDK so the vtable layout is ABI-correct: GetIcon
 * must sit at its exact slot for the call through the dnsapi-allocated... (no,
 * shell32-provided) IImageList to land on the right method.
 */
#ifndef _WDK_COMMONCONTROLS_SHIM_H
#define _WDK_COMMONCONTROLS_SHIM_H

#include <objbase.h>   /* IUnknown, HRESULT, REFIID, STDMETHODCALLTYPE, MIDL_INTERFACE */
#include <commctrl.h>  /* HIMAGELIST, IMAGELISTDRAWPARAMS, IMAGEINFO */

/* SAL no-ops so the verbatim interface parses under the WDK SAL set. */
#ifndef _In_
#define _In_
#endif
#ifndef _In_opt_
#define _In_opt_
#endif
#ifndef _Out_
#define _Out_
#endif
#ifndef _Out_opt_
#define _Out_opt_
#endif
#ifndef _Outptr_
#define _Outptr_
#endif

/* IMAGELISTDRAWPARAMS, IMAGEINFO, HIMAGELIST come from <commctrl.h> above. */

#ifndef __IImageList_INTERFACE_DEFINED__
#define __IImageList_INTERFACE_DEFINED__

MIDL_INTERFACE("46EB5926-582E-4017-9FDF-E8998DAA0950")
IImageList : public IUnknown
{
public:
    virtual HRESULT STDMETHODCALLTYPE Add(_In_ HBITMAP hbmImage, _In_opt_ HBITMAP hbmMask, _Out_ int *pi) = 0;
    virtual HRESULT STDMETHODCALLTYPE ReplaceIcon(int i, _In_ HICON hicon, _Out_ int *pi) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetOverlayImage(int iImage, int iOverlay) = 0;
    virtual HRESULT STDMETHODCALLTYPE Replace(int i, _In_ HBITMAP hbmImage, _In_opt_ HBITMAP hbmMask) = 0;
    virtual HRESULT STDMETHODCALLTYPE AddMasked(_In_ HBITMAP hbmImage, COLORREF crMask, _Out_ int *pi) = 0;
    virtual HRESULT STDMETHODCALLTYPE Draw(_In_ IMAGELISTDRAWPARAMS *pimldp) = 0;
    virtual HRESULT STDMETHODCALLTYPE Remove(int i) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetIcon(int i, UINT flags, _Out_ HICON *picon) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetImageInfo(int i, _Out_ IMAGEINFO *pImageInfo) = 0;
    virtual HRESULT STDMETHODCALLTYPE Copy(int iDst, _In_ IUnknown *punkSrc, int iSrc, UINT uFlags) = 0;
    virtual HRESULT STDMETHODCALLTYPE Merge(int i1, _In_ IUnknown *punk2, int i2, int dx, int dy, REFIID riid, _Outptr_ void **ppv) = 0;
    virtual HRESULT STDMETHODCALLTYPE Clone(REFIID riid, _Outptr_ void **ppv) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetImageRect(int i, _Out_ RECT *prc) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetIconSize(_Out_ int *cx, _Out_ int *cy) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetIconSize(int cx, int cy) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetImageCount(_Out_ int *pi) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetImageCount(UINT uNewCount) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetBkColor(COLORREF clrBk, _Out_ COLORREF *pclr) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetBkColor(_Out_ COLORREF *pclr) = 0;
    virtual HRESULT STDMETHODCALLTYPE BeginDrag(int iTrack, int dxHotspot, int dyHotspot) = 0;
    virtual HRESULT STDMETHODCALLTYPE EndDrag(void) = 0;
    virtual HRESULT STDMETHODCALLTYPE DragEnter(_In_opt_ HWND hwndLock, int x, int y) = 0;
    virtual HRESULT STDMETHODCALLTYPE DragLeave(_In_opt_ HWND hwndLock) = 0;
    virtual HRESULT STDMETHODCALLTYPE DragMove(int x, int y) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetDragCursorImage(_In_ IUnknown *punk, int iDrag, int dxHotspot, int dyHotspot) = 0;
    virtual HRESULT STDMETHODCALLTYPE DragShowNolock(BOOL fShow) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetDragImage(_Out_opt_ POINT *ppt, _Out_opt_ POINT *pptHotspot, REFIID riid, _Outptr_ void **ppv) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetItemFlags(int i, _Out_ DWORD *dwFlags) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetOverlayImage(int iOverlay, _Out_ int *piIndex) = 0;
};

#endif /* __IImageList_INTERFACE_DEFINED__ */

#endif /* _WDK_COMMONCONTROLS_SHIM_H */
