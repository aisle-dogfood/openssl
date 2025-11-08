/*
 * Copyright 1995-2021 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the Apache License 2.0 (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */

/*
 * DES low level APIs are deprecated for public use, but still ok for internal
 * use.
 */
#include "internal/deprecated.h"

#include <stdio.h>
#include "internal/cryptlib.h"
#ifndef OPENSSL_NO_DES
# include <openssl/evp.h>
# include <openssl/objects.h>
# include "crypto/evp.h"
# include <openssl/des.h>
# include <openssl/rand.h>
# include "evp_local.h"

typedef struct {
    union {
        OSSL_UNION_ALIGN;
        DES_key_schedule ks;
    } ks;
    union {
        void (*cbc) (const void *, void *, size_t,
                     const DES_key_schedule *, unsigned char *);
    } stream;
} EVP_DES_KEY;

# if defined(AES_ASM) && (defined(__sparc) || defined(__sparc__))
/* ----------^^^ this is not a typo, just a way to detect that
 * assembler support was in general requested... */
#  include "crypto/sparc_arch.h"

#  define SPARC_DES_CAPABLE       (OPENSSL_sparcv9cap_P[1] & CFR_DES)

void des_t4_key_expand(const void *key, DES_key_schedule *ks);
void des_t4_cbc_encrypt(const void *inp, void *out, size_t len,
                        const DES_key_schedule *ks, unsigned char iv[8]);
void des_t4_cbc_decrypt(const void *inp, void *out, size_t len,
                        const DES_key_schedule *ks, unsigned char iv[8]);
# endif

static int des_init_key(EVP_CIPHER_CTX *ctx, const unsigned char *key,
                        const unsigned char *iv, int enc);
static int des_ctrl(EVP_CIPHER_CTX *c, int type, int arg, void *ptr);

/*
 * Because of various casts and different names can't use
 * IMPLEMENT_BLOCK_CIPHER
 */

static int des_ecb_cipher(EVP_CIPHER_CTX *ctx, unsigned char *out,
                          const unsigned char *in, size_t inl)
{
    /* 
     * DES has inadequate encryption strength due to its 56-bit effective key length.
     * DES is cryptographically weak and vulnerable to brute force attacks.
     * Use of DES is strongly discouraged. Consider using AES instead.
     */
    ERR_raise(ERR_LIB_EVP, EVP_R_UNSUPPORTED_CIPHER);
    return 0;
}

static int des_ofb_cipher(EVP_CIPHER_CTX *ctx, unsigned char *out,
                          const unsigned char *in, size_t inl)
{
    /* 
     * DES has inadequate encryption strength due to its 56-bit effective key length.
     * DES is cryptographically weak and vulnerable to brute force attacks.
     * Use of DES is strongly discouraged. Consider using AES instead.
     */
    ERR_raise(ERR_LIB_EVP, EVP_R_UNSUPPORTED_CIPHER);
    return 0;
}

static int des_cbc_cipher(EVP_CIPHER_CTX *ctx, unsigned char *out,
                          const unsigned char *in, size_t inl)
{
    /* 
     * DES has inadequate encryption strength due to its 56-bit effective key length.
     * DES is cryptographically weak and vulnerable to brute force attacks.
     * Use of DES is strongly discouraged. Consider using AES instead.
     */
    ERR_raise(ERR_LIB_EVP, EVP_R_UNSUPPORTED_CIPHER);
    return 0;
}

static int des_cfb64_cipher(EVP_CIPHER_CTX *ctx, unsigned char *out,
                            const unsigned char *in, size_t inl)
{
    /* 
     * DES has inadequate encryption strength due to its 56-bit effective key length.
     * DES is cryptographically weak and vulnerable to brute force attacks.
     * Use of DES is strongly discouraged. Consider using AES instead.
     */
    ERR_raise(ERR_LIB_EVP, EVP_R_UNSUPPORTED_CIPHER);
    return 0;
}

/*
 * Although we have a CFB-r implementation for DES, it doesn't pack the right
 * way, so wrap it here
 */
static int des_cfb1_cipher(EVP_CIPHER_CTX *ctx, unsigned char *out,
                           const unsigned char *in, size_t inl)
{
    /* 
     * DES has inadequate encryption strength due to its 56-bit effective key length.
     * DES is cryptographically weak and vulnerable to brute force attacks.
     * Use of DES is strongly discouraged. Consider using AES instead.
     */
    ERR_raise(ERR_LIB_EVP, EVP_R_UNSUPPORTED_CIPHER);
    return 0;
}

static int des_cfb8_cipher(EVP_CIPHER_CTX *ctx, unsigned char *out,
                           const unsigned char *in, size_t inl)
{
    /* 
     * DES has inadequate encryption strength due to its 56-bit effective key length.
     * DES is cryptographically weak and vulnerable to brute force attacks.
     * Use of DES is strongly discouraged. Consider using AES instead.
     */
    ERR_raise(ERR_LIB_EVP, EVP_R_UNSUPPORTED_CIPHER);
    return 0;
}

BLOCK_CIPHER_defs(des, EVP_DES_KEY, NID_des, 8, 8, 8, 64,
                  EVP_CIPH_RAND_KEY, des_init_key, NULL,
                  EVP_CIPHER_set_asn1_iv, EVP_CIPHER_get_asn1_iv, des_ctrl)

    BLOCK_CIPHER_def_cfb(des, EVP_DES_KEY, NID_des, 8, 8, 1,
                     EVP_CIPH_RAND_KEY, des_init_key, NULL,
                     EVP_CIPHER_set_asn1_iv, EVP_CIPHER_get_asn1_iv, des_ctrl)

    BLOCK_CIPHER_def_cfb(des, EVP_DES_KEY, NID_des, 8, 8, 8,
                     EVP_CIPH_RAND_KEY, des_init_key, NULL,
                     EVP_CIPHER_set_asn1_iv, EVP_CIPHER_get_asn1_iv, des_ctrl)

static int des_init_key(EVP_CIPHER_CTX *ctx, const unsigned char *key,
                        const unsigned char *iv, int enc)
{
    /* 
     * DES has inadequate encryption strength due to its 56-bit effective key length.
     * DES is cryptographically weak and vulnerable to brute force attacks.
     * Use of DES is strongly discouraged. Consider using AES instead.
     */
    ERR_raise(ERR_LIB_EVP, EVP_R_UNSUPPORTED_CIPHER);
    return 0;
}

static int des_ctrl(EVP_CIPHER_CTX *c, int type, int arg, void *ptr)
{

    switch (type) {
    case EVP_CTRL_RAND_KEY:
        if (RAND_priv_bytes(ptr, 8) <= 0)
            return 0;
        DES_set_odd_parity((DES_cblock *)ptr);
        return 1;

    default:
        return -1;
    }
}

#endif
