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
        my @symlist;
        open $expsyms, '<', $expectedsyms or die;
        {
            local $/;
            $exps=<$expsyms>;
        }
        close($expsyms);
        
        # Use list-form open3 to avoid shell interpolation
        my $pid = open3(undef, $OBJFH, gensym, 'dumpbin', '/imports', @objfiles);
        
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
        die "dumpbin failed with exit code " . ($? >> 8) if $? != 0;
        
        foreach (@symlist) {
            if (index($exps, $_) < 0) {
                print "Symbol $_ not in the allowed platform symbols list\n";
                exit 1;
            }
        }
        exit 0;
    }
else {
        open $expsyms, '<', $expectedsyms or die;
        {
            local $/;
            $exps=<$expsyms>;
        }
        close($expsyms);

        # Use list-form open3 to avoid shell interpolation
        # Run objdump with safe argument list
        my $pid = open3(undef, $OBJFH, gensym, 'objdump', '-t', @objfiles);
        
        # Process objdump output in Perl instead of using shell pipeline
        my %symbols;
        while (<$OBJFH>)
        {
            # Filter for undefined symbols (UND), excluding @OPENSSL
            next unless /\bUND\b/;
            next if /\@OPENSSL/;
            
            # Extract the last field (symbol name)
            my @fields = split(/\s+/);
            next unless @fields;
            my $symbol = $fields[-1];
            
            # Remove version suffix (everything after @)
            $symbol =~ s/@.*$//;
            
            # Store unique symbols
            $symbols{$symbol} = 1;
        }
        close($OBJFH);
        waitpid($pid, 0);
        die "objdump failed with exit code " . ($? >> 8) if $? != 0;
        
        # Check each symbol against allowed list
        foreach my $symbol (sort keys %symbols)
        {
            if (index($exps, $symbol . "\n") < 0 && index($exps, $symbol) < 0) {
                print "Symbol $symbol not in the allowed platform symbols list\n";
                exit 1;
            }
        }
        exit 0;
    }
