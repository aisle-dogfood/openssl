#! /usr/bin/env perl
# Copyright 2025 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the Apache License 2.0 (the "License").  You may not use
# this file except in compliance with the License.  You can obtain a copy
# in the file LICENSE in the source distribution or at
# https://www.openssl.org/source/license.html

use strict;
use warnings;

use OpenSSL::Test qw/:DEFAULT bldtop_dir srctop_file/;
use OpenSSL::Test::Utils;

setup("test_fips_checksums");

plan skip_all => "fips-checksums is not available on Windows or VMS"
    if $^O =~ /^(VMS|MSWin32)$/;

my $script = srctop_file("util", "fips-checksums.sh");

sub run_fips_checksums {
    my ($filename, $statusref) = @_;

    local $ENV{PATH} = defined $ENV{PATH} && $ENV{PATH} ne ""
        ? bldtop_dir("apps") . ":" . $ENV{PATH}
        : bldtop_dir("apps");

    my @output = run(cmd(["sh", $script, $filename]),
                     capture => 1, statusvar => $statusref);
    chomp(@output);
    return @output;
}

sub write_perl_input {
    my ($filename) = @_;

    open my $fh, ">", $filename or die "Can't write $filename: $!\n";
    print {$fh} "print qq(hello\\n);\n"
        or die "Can't write $filename: $!\n";
    close $fh or die "Can't close $filename: $!\n";
}

plan tests => 9;

indir "fips-checksums-metacharacters.$$" => sub {
    my $marker = "fips_checksums_marker";
    my $filename = 'touch${IFS}fips_checksums_marker|e;#.pl';
    my $status = 0;
    my @output;

    write_perl_input($filename);
    @output = run_fips_checksums($filename, \$status);

    ok($status, "fips-checksums handles filenames with sed metacharacters");
    is(scalar @output, 1, "fips-checksums emits one checksum line");
    like($output[0], qr/^[0-9a-f]{64}  \Q$filename\E$/,
         "fips-checksums prints the literal filename");
    ok(!-e $marker, "fips-checksums does not execute injected sed commands");
}, create => 1, cleanup => 1;

indir "fips-checksums-leading-dash.$$" => sub {
    my $filename = '-leading-option.pl';
    my $status = 0;
    my @output;

    write_perl_input($filename);
    @output = run_fips_checksums($filename, \$status);

    ok($status, "fips-checksums handles filenames beginning with '-'");
    is(scalar @output, 1, "fips-checksums hashes one leading-dash filename");
    like($output[0], qr/^[0-9a-f]{64}  \Q$filename\E$/,
         "fips-checksums prints the literal leading-dash filename");
}, create => 1, cleanup => 1;

indir "fips-checksums-control-char.$$" => sub {
    my $filename = "bad\nname.pl";
    my $status = 0;
    my @output;

    write_perl_input($filename);
    @output = run_fips_checksums($filename, \$status);

    ok(!$status, "fips-checksums rejects filenames with control characters");
    is(scalar @output, 0,
       "fips-checksums emits no checksum line for rejected filenames");
}, create => 1, cleanup => 1;
