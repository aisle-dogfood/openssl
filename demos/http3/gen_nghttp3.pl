#!/usr/bin/env perl
#
# WARNING: This script is for demo purposes only and should NOT be used in
# production environments. It downloads and builds external code from a third-
# party repository. For production use, vendor a specific release artifact or
# install nghttp3 from trusted distribution packages.
#

use File::Copy;
use File::Path;
use Fcntl ':flock';
use strict;
use warnings;

# Pin to a specific nghttp3 version/tag to prevent supply chain attacks
# Update this tag periodically after vetting new releases
my $NGHTTP3_VERSION = "v1.3.0";
my $NGHTTP3_COMMIT_SHA = "c4c7ed464e2e1c5c0a729980309e60ef36b65de6";

#open STDOUT, '>&STDERR';

chdir "demos/http3";
open(my $fh, '>>', './build.info') or die "Could not open build.info - $!";
flock($fh, LOCK_EX) or die "Could not lock build.info - $!";

if (-d "./nghttp3") {
    rmtree("./nghttp3") or die "Cannot remove nghttp3: $!";
}

# Clone specific version with limited depth to reduce attack surface
my $clone_result = system("git clone --branch $NGHTTP3_VERSION --depth 1 https://github.com/ngtcp2/nghttp3.git");
if ($clone_result != 0) {
    die "Failed to clone nghttp3 repository at version $NGHTTP3_VERSION";
}

chdir "nghttp3";

# Verify the commit SHA matches expected value
my $actual_sha = `git rev-parse HEAD`;
chomp($actual_sha);
if ($actual_sha ne $NGHTTP3_COMMIT_SHA) {
    die "Commit SHA verification failed!\n" .
        "Expected: $NGHTTP3_COMMIT_SHA\n" .
        "Got:      $actual_sha\n" .
        "This may indicate repository tampering or version mismatch.";
}

mkdir "build";
my $submodule_init = system("git submodule init ./lib/sfparse ./tests/munit");
if ($submodule_init != 0) {
    die "Failed to initialize git submodules";
}

my $submodule_update = system("git submodule update");
if ($submodule_update != 0) {
    die "Failed to update git submodules";
}

my $cmake_config = system("cmake -DENABLE_LIB_ONLY=1 -S . -B build");
if ($cmake_config != 0) {
    die "Failed to configure nghttp3 build with cmake";
}

my $cmake_build = system("cmake --build build");
if ($cmake_build != 0) {
    die "Failed to build nghttp3";
}

my $libs="./build/lib/libnghttp*";

for my $file (glob $libs) {
    copy($file, "..");
}

chdir "../../..";
close($fh);

exit(0);
