CMS (Cryptographic Message Syntax) Demos
========================================

This directory contains demonstration programs for using the CMS API in OpenSSL.

IMPORTANT: Certificate and Key Generation
------------------------------------------

For security reasons, private keys are NOT included in this repository.
Before running the demos, you must generate test certificates and keys locally.

To generate the required certificates and keys, run:

    ./mkcerts.sh

This will create:
  - cacert.pem    (Root CA certificate)
  - cakey.pem     (Root CA private key)
  - signer.pem    (First signer certificate and private key)
  - signer2.pem   (Second signer certificate and private key)

These files are required by the demo programs and should NOT be committed to
the repository.

Demo Programs
-------------

cms_comp     - Compress a message
cms_ddec     - Decrypt a detached message
cms_dec      - Decrypt a message
cms_denc     - Encrypt a detached message
cms_enc      - Encrypt a message
cms_sign     - Sign a message
cms_sign2    - Sign a message with two signers
cms_uncomp   - Uncompress a message
cms_ver      - Verify a signed message

Running the Demos
-----------------

1. First, generate the certificates and keys:
   ./mkcerts.sh

2. Build the demo programs:
   make

3. Run individual demos or all tests:
   make test

Note: Make sure OpenSSL libraries are in your library path:
   LD_LIBRARY_PATH=../.. ./cms_sign
