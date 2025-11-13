OpenSSL Simple Echo Client/Server
=================================

**SECURITY WARNING: This demo contains a PRIVATE KEY (key.pem) for testing only!**
**This key must NEVER be used in production environments or distributed.**
**See SECURITY-DEMO-KEYS.md in the repository root for details.**

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

**IMPORTANT: The cert.pem and key.pem files included are self signed certificates 
with hard-coded secrets for demonstration purposes only. The key.pem file contains
a private key that must be excluded from any production distribution or deployment.**

The certificates have the "Common Name" of 'localhost'.

For production use, generate new certificates using an actual hostname and 
never use the demo key.pem file.
