S/MIME Demonstration Programs

This directory contains demonstration programs that show how to use the
S/MIME API in OpenSSL.

Before running the demos, you must generate test certificates and keys:

    ./mkkeys.sh

This will create the following files:
    - cacert.pem  - CA certificate
    - cakey.pem   - CA private key
    - signer.pem  - First signer certificate and private key
    - signer2.pem - Second signer certificate and private key

IMPORTANT: These are test certificates and keys for demonstration purposes
only. Never use these in production or commit private keys to version control.

The demo programs demonstrate various S/MIME operations:
    - smsign  - Sign data using S/MIME
    - smsign2 - Sign data with multiple signers
    - smver   - Verify S/MIME signed data
    - smenc   - Encrypt data using S/MIME
    - smdec   - Decrypt S/MIME encrypted data
