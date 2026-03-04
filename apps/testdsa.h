/*
 * Copyright 1998-2021 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the Apache License 2.0 (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */

#include <openssl/param_build.h>
#include <openssl/core_names.h>

/* used by speed.c */
EVP_PKEY *get_dsa(int);

/*
 * Generate DSA keys at runtime to avoid embedding private key material
 * in source code (CWE-321, CWE-798)
 */
EVP_PKEY *get_dsa(int dsa_bits)
{
    EVP_PKEY *pkey = NULL;
    EVP_PKEY_CTX *pctx = NULL;
    OSSL_PARAM params[2];
    size_t bits = (size_t)dsa_bits;

    if ((pctx = EVP_PKEY_CTX_new_from_name(NULL, "DSA", NULL)) == NULL)
        return NULL;

    /* Generate DSA key with specified bit length */
    params[0] = OSSL_PARAM_construct_size_t(OSSL_PKEY_PARAM_FFC_PBITS, &bits);
    params[1] = OSSL_PARAM_construct_end();

    if (EVP_PKEY_paramgen_init(pctx) <= 0
        || EVP_PKEY_CTX_set_params(pctx, params) <= 0
        || EVP_PKEY_generate(pctx, &pkey) <= 0) {
        EVP_PKEY_free(pkey);
        pkey = NULL;
    }

    EVP_PKEY_CTX_free(pctx);
    return pkey;
}
