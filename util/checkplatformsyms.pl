#! /usr/bin/env perl
# Copyright 2006-2023 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the Apache License 2.0 (the "License").  You may not use
# this file except in compliance with the License.  You can obtain a copy
# in the file LICENSE in the source distribution or at
# https://www.openssl.org/source/license.html

use warnings;
use strict;
use Config;
use IPC::Open3;
use Symbol 'gensym';

my $expectedsyms=$ARGV[0];

shift(@ARGV);

my $objlist;
my @objfiles = @ARGV;
my $expsyms;
my $exps;
my $OBJFH;

if ($Config{osname} eq "MSWin32") {
        my $currentdll = "";
        my @cmd = ("dumpbin", "/imports", @objfiles);
        my @symlist;
        open $expsyms, '<', $expectedsyms or die;
        {
            local $/;
            $exps=<$expsyms>;
        }
        close($expsyms);
        my $pid = open3(undef, $OBJFH, undef, @cmd) or die "Cannot open process: $!";
        while (<$OBJFH>)
        {
            chomp;
            my $dllfile = $_;
            $dllfile =~ s/( +)(.*)(\.dll)(.*)/DLLFILE \2/;
            if (index($dllfile, "DLLFILE") >= 0) {
                $currentdll = substr($dllfile, 8);
                $currentdll =~ s/^\s+|s+$//g;
            }
            # filter imports from our own library
            if ("$currentdll" ne "libcrypto-3-x64") {
                my $line = $_;
                $line =~ s/                          [0-9a-fA-F]{1,2} /SYMBOL /;
                if (index($line, "SYMBOL") != -1) {
                    $line =~ s/.*SYMBOL //;
                    push(@symlist, $line);
                }
            }
        }
        close($OBJFH);
        waitpid($pid, 0);
        foreach (@symlist) {
            if (index($exps, $_) < 0) {
                print "Symbol $_ not in the allowed platform symbols list\n";
                exit 1;
            }
        }
        exit 0;
    }
else {
        # Build safe command array for objdump
        my @cmd = ("objdump", "-t", @objfiles);

        open $expsyms, '<', $expectedsyms or die;
        {
            local $/;
            $exps=<$expsyms>;
        }
        close($expsyms);

        # Execute objdump safely without shell
        my $pid = open3(undef, $OBJFH, undef, @cmd) or die "Cannot open process: $!";
        
        # Process output in Perl instead of shell pipeline
        my %symbols;
        while (<$OBJFH>)
        {
            # Filter for UND (undefined) symbols, excluding @OPENSSL
            if (/UND/ && !/\@OPENSSL/) {
                # Extract last field (symbol name) - equivalent to awk '{print $NF}'
                my @fields = split(/\s+/);
                my $symbol = $fields[-1];
                # Remove version suffix - equivalent to sed -e"s/@.*$//"
                $symbol =~ s/@.*$//;
                $symbols{$symbol} = 1;
            }
        }
        close($OBJFH);
        waitpid($pid, 0);
        
        # Check symbols (already unique due to hash)
        foreach my $symbol (sort keys %symbols)
        {
                my $symline = $symbol . "\n";
                if (index($exps, $symline) < 0) {
                    print "Symbol $symbol not in the allowed platform symbols list\n";
                    exit 1;
                }
        }
        exit 0;
    }
