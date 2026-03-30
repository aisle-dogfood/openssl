/*
 * Copyright 1999-2024 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the Apache License 2.0 (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */

#include <stdio.h>
#include <stdlib.h>
#include "internal/cryptlib.h"
#include <openssl/x509.h>
#include <openssl/evp.h>
#include <openssl/core_names.h>
#include <openssl/kdf.h>

/*
 * Doesn't do anything now: Builtin PBE algorithms in static table.
 */

void PKCS5_PBE_add(void)
{
}

int PKCS5_PBE_keyivgen_ex(EVP_CIPHER_CTX *cctx, const char *pass, int passlen,
                          ASN1_TYPE *param, const EVP_CIPHER *cipher,
                          const EVP_MD *md, int en_de, OSSL_LIB_CTX *libctx,
                          const char *propq)
{
    PBEPARAM *pbe = NULL;

    /* Extract useful info from parameter */
    if (param == NULL || param->type != V_ASN1_SEQUENCE ||
        param->value.sequence == NULL) {
        ERR_raise(ERR_LIB_EVP, EVP_R_DECODE_ERROR);
        return 0;
    }

    pbe = ASN1_TYPE_unpack_sequence(ASN1_ITEM_rptr(PBEPARAM), param);
    if (pbe == NULL) {
        ERR_raise(ERR_LIB_EVP, EVP_R_DECODE_ERROR);
        return 0;
    }

    /*
     * PBKDF1 is obsolete and considered insecure (PKCS#5 v1.5).
     * Reject its use to prevent inadvertent selection of weak KDF.
     * Users should migrate to PBKDF2 (PKCS#5 v2.0) or stronger KDFs.
     */
    ERR_raise(ERR_LIB_EVP, EVP_R_UNSUPPORTED_KEY_DERIVATION_FUNCTION);
    PBEPARAM_free(pbe);
    return 0;
}

int PKCS5_PBE_keyivgen(EVP_CIPHER_CTX *cctx, const char *pass, int passlen,
                       ASN1_TYPE *param, const EVP_CIPHER *cipher,
                       const EVP_MD *md, int en_de)
{
    return PKCS5_PBE_keyivgen_ex(cctx, pass, passlen, param, cipher, md, en_de,
                                 NULL, NULL);
}

