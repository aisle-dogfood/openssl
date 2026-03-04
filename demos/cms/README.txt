CMS Demonstration Programs

This directory contains demonstration programs that show how to use the
Cryptographic Message Syntax (CMS) API in OpenSSL.

Before running the demos, you must generate test certificates and keys:

    ./mkkeys.sh

This will create the following files:
    - cacert.pem  - CA certificate
    - cakey.pem   - CA private key
    - signer.pem  - First signer certificate and private key
    - signer2.pem - Second signer certificate and private key

IMPORTANT: These are test certificates and keys for demonstration purposes
only. Never use these in production or commit private keys to version control.

The demo programs demonstrate various CMS operations:
    - cms_sign    - Sign data using CMS
    - cms_sign2   - Sign data with multiple signers
    - cms_ver     - Verify CMS signed data
    - cms_enc     - Encrypt data using CMS
    - cms_dec     - Decrypt CMS encrypted data
    - cms_denc    - Decrypt CMS enveloped data
    - cms_ddec    - Decrypt CMS data with detached content
    - cms_comp    - Compress data using CMS
    - cms_uncomp  - Uncompress CMS compressed data
