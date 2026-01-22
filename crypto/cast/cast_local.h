/*
 * Copyright 1995-2023 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the Apache License 2.0 (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */

#ifdef OPENSSL_SYS_WIN32
# include <stdlib.h>
#endif

#include "internal/constant_time.h"

/* NOTE - c is not incremented as per n2l */
#define n2ln(c,l1,l2,n) { \
                        c+=n; \
                        l1=l2=0; \
                        switch (n) { \
                        case 8: l2 =((unsigned long)(*(--(c))))    ; \
                        /* fall through */                              \
                        case 7: l2|=((unsigned long)(*(--(c))))<< 8; \
                        /* fall through */                              \
                        case 6: l2|=((unsigned long)(*(--(c))))<<16; \
                        /* fall through */                              \
                        case 5: l2|=((unsigned long)(*(--(c))))<<24; \
                        /* fall through */                              \
                        case 4: l1 =((unsigned long)(*(--(c))))    ; \
                        /* fall through */                              \
                        case 3: l1|=((unsigned long)(*(--(c))))<< 8; \
                        /* fall through */                              \
                        case 2: l1|=((unsigned long)(*(--(c))))<<16; \
                        /* fall through */                              \
                        case 1: l1|=((unsigned long)(*(--(c))))<<24; \
                                } \
                        }

/* NOTE - c is not incremented as per l2n */
#define l2nn(l1,l2,c,n) { \
                        c+=n; \
                        switch (n) { \
                        case 8: *(--(c))=(unsigned char)(((l2)    )&0xff); \
                        /* fall through */                                    \
                        case 7: *(--(c))=(unsigned char)(((l2)>> 8)&0xff); \
                        /* fall through */                                    \
                        case 6: *(--(c))=(unsigned char)(((l2)>>16)&0xff); \
                        /* fall through */                                    \
                        case 5: *(--(c))=(unsigned char)(((l2)>>24)&0xff); \
                        /* fall through */                                    \
                        case 4: *(--(c))=(unsigned char)(((l1)    )&0xff); \
                        /* fall through */                                    \
                        case 3: *(--(c))=(unsigned char)(((l1)>> 8)&0xff); \
                        /* fall through */                                    \
                        case 2: *(--(c))=(unsigned char)(((l1)>>16)&0xff); \
                        /* fall through */                                    \
                        case 1: *(--(c))=(unsigned char)(((l1)>>24)&0xff); \
                                } \
                        }

#undef n2l
#define n2l(c,l)        (l =((unsigned long)(*((c)++)))<<24L, \
                         l|=((unsigned long)(*((c)++)))<<16L, \
                         l|=((unsigned long)(*((c)++)))<< 8L, \
                         l|=((unsigned long)(*((c)++))))

#undef l2n
#define l2n(l,c)        (*((c)++)=(unsigned char)(((l)>>24L)&0xff), \
                         *((c)++)=(unsigned char)(((l)>>16L)&0xff), \
                         *((c)++)=(unsigned char)(((l)>> 8L)&0xff), \
                         *((c)++)=(unsigned char)(((l)     )&0xff))

#if defined(OPENSSL_SYS_WIN32) && defined(_MSC_VER)
# define ROTL(a,n)     (_lrotl(a,n))
#else
# define ROTL(a,n)     ((((a)<<(n))&0xffffffffL)|((a)>>((32-(n))&31)))
#endif

#define C_M    0x3fc
#define C_0    22L
#define C_1    14L
#define C_2     6L
#define C_3     2L              /* left shift */

/*
 * Constant-time S-box lookup helper to mitigate cache-timing attacks.
 * Looks up value from a 256-entry S-box table using constant_time_lookup.
 */
static ossl_inline CAST_LONG CAST_sbox_lookup_ct(const CAST_LONG *table,
                                                   unsigned int idx)
{
    CAST_LONG result;
    /* Ensure index is in valid range [0, 255] */
    idx &= 0xff;
    constant_time_lookup(&result, table, sizeof(CAST_LONG), 256, idx);
    return result;
}

/*
 * The E_CAST macro now uses constant-time S-box lookups to prevent
 * cache-timing side-channel attacks. This ensures that table accesses
 * do not leak information about secret key material or plaintext.
 */
#define E_CAST(n,key,L,R,OP1,OP2,OP3) \
        { \
        CAST_LONG a,b,c,d; \
        t=(key[n*2] OP1 R)&0xffffffff; \
        t=ROTL(t,(key[n*2+1])); \
        a=CAST_sbox_lookup_ct(CAST_S_table0, (t>> 8)); \
        b=CAST_sbox_lookup_ct(CAST_S_table1, (t    )); \
        c=CAST_sbox_lookup_ct(CAST_S_table2, (t>>24)); \
        d=CAST_sbox_lookup_ct(CAST_S_table3, (t>>16)); \
        L^=(((((a OP2 b)&0xffffffffL) OP3 c)&0xffffffffL) OP1 d)&0xffffffffL; \
        }

extern const CAST_LONG CAST_S_table0[256];
extern const CAST_LONG CAST_S_table1[256];
extern const CAST_LONG CAST_S_table2[256];
extern const CAST_LONG CAST_S_table3[256];
extern const CAST_LONG CAST_S_table4[256];
extern const CAST_LONG CAST_S_table5[256];
extern const CAST_LONG CAST_S_table6[256];
extern const CAST_LONG CAST_S_table7[256];
