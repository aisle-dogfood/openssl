#!/usr/bin/env perl
#

use File::Copy;
use File::Path;
use Fcntl ':flock';
use strict;
use warnings;

#open STDOUT, '>&STDERR';

# Pin to a specific nghttp3 version to ensure supply chain integrity
# This is a demo-only build; update this tag when newer stable releases are available
# Verify the tag exists at: https://github.com/ngtcp2/nghttp3/releases
my $NGHTTP3_VERSION = "v1.3.0";

chdir "demos/http3";
open(my $fh, '>>', './build.info') or die "Could not open build.info - $!";
flock($fh, LOCK_EX) or die "Could not lock build.info - $!";

if (-d "./nghttp3") {
    rmtree("./nghttp3") or die "Cannot remove nghttp3: $!";
}

# Clone with version pinning and shallow depth for supply chain security
my $clone_result = system("git clone --branch $NGHTTP3_VERSION --depth 1 https://github.com/ngtcp2/nghttp3.git");
if ($clone_result != 0) {
    die "Failed to clone nghttp3 version $NGHTTP3_VERSION. Check that the version exists and network is available.";
}

chdir "nghttp3";
mkdir "build";
system("git submodule init ./lib/sfparse ./tests/munit");
system("git submodule update");
system("cmake -DENABLE_LIB_ONLY=1 -S . -B build");
system("cmake --build build");

my $libs="./build/lib/libnghttp*";

for my $file (glob $libs) {
    copy($file, "..");
}

chdir "../../..";
close($fh);

exit(0);
