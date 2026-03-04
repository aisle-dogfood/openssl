OpenSSL Simple Echo Client/Server
=================================

This project implements a simple echo client/server.

It is a console application, with command line parameters determining the mode
of operation (client or server). Start it with no parameters to see usage.

The server code was adapted from the Simple TLS Server on the OpenSSL Wiki.
The server code was modified to perform the echo function, and client code
was added to open a connection with the server and to send keyboard input
to the server.

The new client code illustrates that:

- Connection to the SSL server starts as a standard TCP 'connect'.
- Once connected with TCP, the client 'upgrades' to SSL using
  SSL_connect().
- When the SSL connection completes, data is sent and received using
  SSL_write() and SSL_read().
- Pretty simple.

## ⚠️  SECURITY WARNING ⚠️

**The key.pem file included in this directory is a PUBLICLY AVAILABLE demo
private key that MUST NOT be used in production.**

This hard-coded private key is visible to anyone with access to the OpenSSL
repository. Using it in any production or publicly accessible environment
would provide NO security and allow anyone to impersonate your server.

**For production use**: Generate a new private key with proper entropy:
```bash
openssl genpkey -algorithm RSA -out mykey.pem -pkeyopt rsa_keygen_bits:2048
openssl req -new -x509 -key mykey.pem -out mycert.pem -days 365
```

The cert.pem and key.pem files included are self signed certificates with the
"Common Name" of 'localhost'.

Best to create the 'pem' files using an actual hostname.
