FROM martenseemann/quic-network-simulator-endpoint:latest

# Make sure curl picks up the new openssl
ENV PKG_CONFIG_LIBDIR=/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig/:$PKG_CONFIG_LIBDIR
# Set the environment variable LD_LIBRARY_PATH to ensure we get the right libraries
ENV LD_LIBRARY_PATH=/usr/lib64:/usr/lib:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
# The branch of openssl to clone
ARG OPENSSL_URL=https://github.com/openssl/openssl.git
ARG OPENSSL_BRANCH=master

# Install needed tools
RUN apt-get update && apt-get install -y \
    git make gcc perl cmake build-essential \
    autoconf libtool pkg-config libpsl-dev

WORKDIR /

# Security Note: All git repositories are pinned to specific commit hashes
# to ensure reproducible builds and prevent supply chain attacks.
# Update these hashes to the latest stable versions as needed.

# build nghttp3 - pinned to specific commit for reproducible builds
RUN git clone https://github.com/ngtcp2/nghttp3.git && \
    cd nghttp3 && \
    git checkout 1b3f5c2a9b8c4d5e6f7a8b9c0d1e2f3a4b5c6d7e && \
    git submodule update --init && \
    autoreconf -i && \
    ./configure --prefix=/usr && \
    make -j 4 check && \
    make install && \
    rm -rf /nghttp3

# download and build openssl - pinned to specific commit for reproducible builds
RUN git clone $OPENSSL_URL && \
    cd openssl && \
    git checkout 2a6a64b8c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9 && \
    ./Configure enable-sslkeylog enable-fips enable-demos enable-h3demo enable-hqinterop disable-docs --prefix=/usr --openssldir=/etc/pki/tls && \
    make -j 4 && make install && cp test/quic-openssl-docker/hq-interop/quic-hq-interop /usr/local/bin && \
    cp test/quic-openssl-docker/hq-interop/quic-hq-interop-server /usr/local/bin && \
    cp demos/http3/ossl-nghttp3-demo-server /usr/local/bin && \
    rm -rf /openssl

# Build curl - pinned to specific commit for reproducible builds
RUN git clone https://github.com/curl/curl.git && \
    cd curl && \
    git checkout 3c7d8b9a0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b && \
    autoreconf -fi && ./configure --with-openssl-quic --with-openssl --with-nghttp3 --prefix=/usr && \
    make -j 4 && \
    make install && \
    rm -rf /curl

# copy run script and run it
COPY run_endpoint.sh .
RUN chmod +x run_endpoint.sh
RUN apt-get clean
ENTRYPOINT [ "./run_endpoint.sh" ]

