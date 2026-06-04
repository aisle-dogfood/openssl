#! /usr/bin/env perl
# Copyright 2026 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the Apache License 2.0 (the "License").  You may not use
# this file except in compliance with the License.  You can obtain a copy
# in the file LICENSE in the source distribution or at
# https://www.openssl.org/source/license.html

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Path qw(make_path);
use OpenSSL::Test qw/:DEFAULT srctop_file/;

setup("test_mktar");

plan skip_all => "test_mktar requires a POSIX shell"
    if $^O =~ /^(VMS|MSWin32)$/;

plan tests => 4;

indir "mktar-valid.$$" => sub {
    prepare_tree(<<'EOF');
MAJOR=3
MINOR=5
PATCH=3
PRE_RELEASE_TAG=alpha1-dev
BUILD_METADATA=build5
RELEASE_DATE="16 Sep 2025"
SHLIB_VERSION=3
EOF

    ok(run_mktar(), "mktar.sh accepts valid VERSION.dat data");
    ok(-f "openssl-3.5.3-alpha1-dev+build5.tar.gz",
       "mktar.sh still uses parsed version data for the tarball name");
}, create => 1, cleanup => 1;

indir "mktar-malicious.$$" => sub {
    prepare_tree(<<'EOF');
MAJOR=3
MINOR=5
PATCH=3
PRE_RELEASE_TAG=alpha1-dev
BUILD_METADATA=$(touch pwned)
RELEASE_DATE="16 Sep 2025"
SHLIB_VERSION=3
EOF

    ok(!run_mktar(), "mktar.sh rejects shell syntax embedded in VERSION.dat");
    ok(!-e "pwned", "mktar.sh does not execute commands from VERSION.dat");
}, create => 1, cleanup => 1;

sub prepare_tree {
    my $version_data = shift;

    make_path("util", "bin");
    copy(srctop_file("util", "mktar.sh"), "util/mktar.sh")
        or die "Could not copy util/mktar.sh: $!";
    chmod 0755, "util/mktar.sh"
        or die "Could not chmod util/mktar.sh: $!";

    open my $version_fh, '>', "VERSION.dat"
        or die "Could not write VERSION.dat: $!";
    print {$version_fh} $version_data;
    close $version_fh or die "Could not close VERSION.dat: $!";

    open my $git_fh, '>', "bin/git"
        or die "Could not write fake git helper: $!";
    print {$git_fh} <<'EOF';
#! /bin/sh
outfile=
while [ $# -gt 0 ]; do
    if [ "$1" = "-o" ]; then
        shift
        outfile=$1
    fi
    shift
done
: > "$outfile"
EOF
    close $git_fh or die "Could not close fake git helper: $!";
    chmod 0755, "bin/git"
        or die "Could not chmod fake git helper: $!";
}

sub run_mktar {
    my $path_suffix = defined $ENV{PATH} ? ":$ENV{PATH}" : "";
    local $ENV{PATH} = abs_path("bin") . $path_suffix;

    return run(cmd(["sh", "util/mktar.sh"]));
}
