/*
 * Minimal self-contained <windns.h> for the WDK 7.1 toolchain.
 *
 * WDK 7.1's user-mode SDK omits windns.h, but ships dnsapi.lib. Qt 5.6's
 * qdnslookup_win.cpp needs the DNS_RECORD layout plus DnsQuery_W/DnsFree.
 *
 * Struct layouts (header fields + the union members qdnslookup reads) are copied
 * verbatim from the Windows SDK so they are ABI-correct: DnsQuery_W (in
 * dnsapi.dll) allocates the full record; we only read fields, and every union
 * member starts at the same offset, so a reduced union is safe.
 */
#ifndef _WDK_WINDNS_SHIM_H
#define _WDK_WINDNS_SHIM_H

#include <windows.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef LONG  DNS_STATUS, *PDNS_STATUS;
typedef DWORD IP4_ADDRESS, *PIP4_ADDRESS;

typedef struct _IP4_ARRAY
{
    DWORD       AddrCount;
    IP4_ADDRESS AddrArray[1];
}
IP4_ARRAY, *PIP4_ARRAY;

typedef union
{
    DWORD IP6Dword[4];
    WORD  IP6Word[8];
    BYTE  IP6Byte[16];
}
IP6_ADDRESS, *PIP6_ADDRESS;

/* DNS record type values (subset Qt maps to). */
#define DNS_TYPE_A      0x0001
#define DNS_TYPE_NS     0x0002
#define DNS_TYPE_CNAME  0x0005
#define DNS_TYPE_PTR    0x000c
#define DNS_TYPE_MX     0x000f
#define DNS_TYPE_TEXT   0x0010
#define DNS_TYPE_AAAA   0x001c
#define DNS_TYPE_SRV    0x0021

#define DNS_QUERY_STANDARD  0x00000000

typedef struct _DnsRecordFlags
{
    DWORD Section  : 2;
    DWORD Delete   : 1;
    DWORD CharSet  : 2;
    DWORD Unused   : 3;
    DWORD Reserved : 24;
}
DNS_RECORD_FLAGS;

typedef struct { IP4_ADDRESS IpAddress;  } DNS_A_DATA,    *PDNS_A_DATA;
typedef struct { IP6_ADDRESS Ip6Address; } DNS_AAAA_DATA, *PDNS_AAAA_DATA;
typedef struct { PWSTR pNameHost;        } DNS_PTR_DATAW, *PDNS_PTR_DATAW;

typedef struct
{
    PWSTR pNameExchange;
    WORD  wPreference;
    WORD  Pad;
}
DNS_MX_DATAW, *PDNS_MX_DATAW;

typedef struct
{
    PWSTR pNameTarget;
    WORD  wPriority;
    WORD  wWeight;
    WORD  wPort;
    WORD  Pad;
}
DNS_SRV_DATAW, *PDNS_SRV_DATAW;

typedef struct
{
    DWORD dwStringCount;
    PWSTR pStringArray[1];
}
DNS_TXT_DATAW, *PDNS_TXT_DATAW;

typedef struct _DnsRecordW
{
    struct _DnsRecordW *    pNext;
    PWSTR                   pName;
    WORD                    wType;
    WORD                    wDataLength;
    union { DWORD DW; DNS_RECORD_FLAGS S; } Flags;
    DWORD                   dwTtl;
    DWORD                   dwReserved;
    union
    {
        DNS_A_DATA      A;
        DNS_PTR_DATAW   PTR, Ptr, NS, Ns, CNAME, Cname;
        DNS_MX_DATAW    MX, Mx;
        DNS_TXT_DATAW   TXT, Txt;
        DNS_AAAA_DATA   AAAA;
        DNS_SRV_DATAW   SRV, Srv;
        PBYTE           pDataPtr;
    } Data;
}
DNS_RECORDW, *PDNS_RECORDW;

typedef DNS_RECORDW  DNS_RECORD;
typedef PDNS_RECORDW PDNS_RECORD;

typedef enum
{
    DnsFreeFlat = 0,
    DnsFreeRecordList,
    DnsFreeParsedMessageFields
}
DNS_FREE_TYPE;

DNS_STATUS WINAPI DnsQuery_W(PCWSTR pszName, WORD wType, DWORD Options,
                             PVOID pExtra, PDNS_RECORD *ppQueryResults,
                             PVOID *pReserved);
VOID WINAPI DnsFree(PVOID pData, DNS_FREE_TYPE FreeType);

#define DnsRecordListFree(p, t) DnsFree((p), DnsFreeRecordList)
#define DnsQuery DnsQuery_W

#ifdef __cplusplus
}
#endif

#endif /* _WDK_WINDNS_SHIM_H */
