#!/usr/bin/env perl
#
# WARNING: This script is for DEMO purposes only and should NOT be used in
# production or security-sensitive environments. The nghttp3 library is cloned
# from a pinned version to reduce supply chain risk, but full integrity
# verification (signatures, checksums) is not implemented.
#
# For production use, please use system-provided nghttp3 packages or vendor
# a verified release artifact.

use File::Copy;
use File::Path;
use Fcntl ':flock';
use strict;
use warnings;

# Pin to a specific stable version of nghttp3 to reduce supply chain risk.
# This version should be periodically reviewed and updated.
my $NGHTTP3_VERSION = "v1.3.0";

#open STDOUT, '>&STDERR';

chdir "demos/http3";
open(my $fh, '>>', './build.info') or die "Could not open build.info - $!";
flock($fh, LOCK_EX) or die "Could not lock build.info - $!";

if (-d "./nghttp3") {
    rmtree("./nghttp3") or die "Cannot remove nghttp3: $!";
}

# Clone a specific pinned version with shallow clone to reduce attack surface
system("git clone --branch $NGHTTP3_VERSION --depth 1 https://github.com/ngtcp2/nghttp3.git") == 0
    or die "Failed to clone nghttp3 at version $NGHTTP3_VERSION: $!";

chdir "nghttp3";
mkdir "build";
system("git submodule init ./lib/sfparse ./tests/munit") == 0
    or die "Failed to initialize submodules: $!";
system("git submodule update --depth 1") == 0
    or die "Failed to update submodules: $!";
system("cmake -DENABLE_LIB_ONLY=1 -S . -B build") == 0
    or die "Failed to configure build: $!";
system("cmake --build build") == 0
    or die "Failed to build nghttp3: $!";

my $libs="./build/lib/libnghttp*";

for my $file (glob $libs) {
    copy($file, "..");
}

chdir "../../..";
close($fh);

exit(0);
