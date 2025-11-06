/*
 * Copyright 2016-2024 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the Apache License 2.0 (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */

# if defined(__linux) || defined(__sun) || defined(__hpux)
/*
 * Following definition aliases fopen to fopen64 on above mentioned
 * platforms. This makes it possible to open and sequentially access files
 * larger than 2GB from 32-bit application. It does not allow one to traverse
 * them beyond 2GB with fseek/ftell, but on the other hand *no* 32-bit
 * platform permits that, not with fseek/ftell. Not to mention that breaking
 * 2GB limit for seeking would require surgery to *our* API. But sequential
 * access suffices for practical cases when you can run into large files,
 * such as fingerprinting, so we can let API alone. For reference, the list
 * of 32-bit platforms which allow for sequential access of large files
 * without extra "magic" comprise *BSD, Darwin, IRIX...
 */
#  ifndef _FILE_OFFSET_BITS
#   define _FILE_OFFSET_BITS 64
#  endif
# endif

#include "internal/e_os.h"
#include "internal/cryptlib.h"
#include "internal/common.h"

#if !defined(OPENSSL_NO_STDIO)

# include <stdio.h>
# ifdef __DJGPP__
#  include <unistd.h>
# endif

/*
 * Validate filename to prevent path traversal attacks
 * Returns 1 if filename is safe, 0 if potentially dangerous
 */
static int validate_filename(const char *filename)
{
    const char *p;
    int dotdot_count = 0;
    
    if (filename == NULL)
        return 0;
    
    /* 
     * Check for excessive path traversal sequences that could escape
     * reasonable directory boundaries. Allow some ".." for legitimate
     * relative paths but block excessive traversal.
     */
    p = filename;
    while ((p = strstr(p, "..")) != NULL) {
        /* Check if ".." is a complete path component */
        if ((p == filename || p[-1] == '/' || p[-1] == '\\') &&
            (p[2] == '\0' || p[2] == '/' || p[2] == '\\')) {
            dotdot_count++;
            /* Allow reasonable number of parent directory references */
            if (dotdot_count > 10) {
                return 0; /* Excessive path traversal detected */
            }
        }
        p += 2;
    }
    
    /* 
     * For security, reject absolute paths that point to sensitive system directories
     */
    if (ossl_is_absolute_path(filename)) {
        const char *sensitive_dirs[] = {
            "/etc/", "/proc/", "/sys/", "/dev/", "/boot/", "/root/",
            "C:\\Windows\\", "C:\\Program Files\\", "C:\\Users\\",
            NULL
        };
        int i;
        
        for (i = 0; sensitive_dirs[i] != NULL; i++) {
            size_t len = strlen(sensitive_dirs[i]);
            if (strncmp(filename, sensitive_dirs[i], len) == 0) {
                return 0; /* Access to sensitive directory blocked */
            }
        }
    }
    
    /* Block null bytes and other dangerous characters */
    if (strchr(filename, '\0') != filename + strlen(filename)) {
        return 0; /* Null byte in filename */
    }
    
    return 1; /* Filename appears safe */
}

FILE *openssl_fopen(const char *filename, const char *mode)
{
    FILE *file = NULL;
# if defined(_WIN32) && defined(CP_UTF8)
    int sz, len_0;
    DWORD flags;
# endif

    if (filename == NULL)
        return NULL;
    
    /* Validate filename to prevent path traversal attacks */
    if (!validate_filename(filename)) {
        ERR_raise_data(ERR_LIB_SYS, EACCES,
                       "filename validation failed for security: %s", filename);
        return NULL;
    }
# if defined(_WIN32) && defined(CP_UTF8)
    len_0 = (int)strlen(filename) + 1;

    /*
     * Basically there are three cases to cover: a) filename is
     * pure ASCII string; b) actual UTF-8 encoded string and
     * c) locale-ized string, i.e. one containing 8-bit
     * characters that are meaningful in current system locale.
     * If filename is pure ASCII or real UTF-8 encoded string,
     * MultiByteToWideChar succeeds and _wfopen works. If
     * filename is locale-ized string, chances are that
     * MultiByteToWideChar fails reporting
     * ERROR_NO_UNICODE_TRANSLATION, in which case we fall
     * back to fopen...
     */
    if ((sz = MultiByteToWideChar(CP_UTF8, (flags = MB_ERR_INVALID_CHARS),
                                  filename, len_0, NULL, 0)) > 0 ||
        (GetLastError() == ERROR_INVALID_FLAGS &&
         (sz = MultiByteToWideChar(CP_UTF8, (flags = 0),
                                   filename, len_0, NULL, 0)) > 0)
        ) {
        WCHAR wmode[8];
        WCHAR *wfilename = _alloca(sz * sizeof(WCHAR));

        if (MultiByteToWideChar(CP_UTF8, flags,
                                filename, len_0, wfilename, sz) &&
            MultiByteToWideChar(CP_UTF8, 0, mode, strlen(mode) + 1,
                                wmode, OSSL_NELEM(wmode)) &&
            (file = _wfopen(wfilename, wmode)) == NULL &&
            (errno == ENOENT || errno == EBADF)
            ) {
            /*
             * UTF-8 decode succeeded, but no file, filename
             * could still have been locale-ized...
             */
            file = fopen(filename, mode);
        }
    } else if (GetLastError() == ERROR_NO_UNICODE_TRANSLATION) {
        file = fopen(filename, mode);
    }
# elif defined(__DJGPP__)
    {
        char *newname = NULL;

        if (pathconf(filename, _PC_NAME_MAX) <= 12) {  /* 8.3 file system? */
            char *iterator;
            char lastchar;

            if ((newname = OPENSSL_malloc(strlen(filename) + 1)) == NULL)
                return NULL;

            for (iterator = newname, lastchar = '\0';
                *filename; filename++, iterator++) {
                if (lastchar == '/' && filename[0] == '.'
                    && filename[1] != '.' && filename[1] != '/') {
                    /* Leading dots are not permitted in plain DOS. */
                    *iterator = '_';
                } else {
                    *iterator = *filename;
                }
                lastchar = *filename;
            }
            *iterator = '\0';
            filename = newname;
        }
        file = fopen(filename, mode);

        OPENSSL_free(newname);
    }
# else
    file = fopen(filename, mode);
# endif
    return file;
}

#else

void *openssl_fopen(const char *filename, const char *mode)
{
    return NULL;
}

#endif
