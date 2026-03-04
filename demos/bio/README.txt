This directory contains some simple examples of the use of BIO's
to simplify socket programming.

The client-conf, server-conf, client-arg and client-conf include examples
of how to use the SSL_CONF API for configuration file or command line
processing.

Before running the demos, you must generate test certificates and keys:

    ./mkkeys.sh

This will create the following files:
    - server.pem    - RSA server certificate and private key
    - server-ec.pem - EC server certificate and private key

IMPORTANT: These are test certificates and keys for demonstration purposes
only. Never use these in production or commit private keys to version control.
