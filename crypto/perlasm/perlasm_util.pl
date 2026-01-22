# Copyright 2025 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the Apache License 2.0 (the "License").  You may not use
# this file except in compliance with the License.  You can obtain a copy
# in the file LICENSE in the source distribution or at
# https://www.openssl.org/source/license.html

# Common utilities for perlasm scripts

# Shell-escape a string for safe inclusion in shell commands
# Implements POSIX shell single-quote escaping
sub shell_quote {
    my $arg = shift;
    return "''" if !defined($arg) || $arg eq '';
    # For safety, if the argument contains only safe characters, return as-is
    # Safe characters: alphanumeric, dash, underscore, dot, forward slash, equals, plus
    if ($arg =~ /^[-\w.\/=+]+\z/) {
        return $arg;
    }
    # Otherwise, use single-quote escaping (replace ' with '\'' )
    $arg =~ s/'/'\\''/g;
    return "'$arg'";
}

1;
