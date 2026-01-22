/*
 * Copyright 2015-2021 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the Apache License 2.0 (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */

/*
 * MD2 low level APIs are deprecated for public use, but still ok for
 * internal use.
 */
#include "internal/deprecated.h"

#include <openssl/md2.h>
#include "crypto/evp.h"
#include "legacy_meth.h"

/*
 * MD2 is a cryptographically broken hash function (CWE-327/CWE-328).
 * EVP_md2() accessor has been removed to prevent accidental usage.
 * MD2 is only available through the legacy provider for explicit
 * backward compatibility requirements. Applications should migrate
 * to secure hash functions (SHA-256 or higher).
 *
 * To access MD2 when absolutely necessary:
 * 1. Load the legacy provider explicitly
 * 2. Use EVP_MD_fetch(NULL, "MD2", NULL)
 */
