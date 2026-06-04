#! /bin/sh
# Copyright 2018-2020 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the Apache License 2.0 (the "License").  You may not use
# this file except in compliance with the License.  You can obtain a copy
# in the file LICENSE in the source distribution or at
# https://www.openssl.org/source/license.html

HERE=$(dirname "$0")
VERSION_FILE="$HERE/../VERSION.dat"

version_data_error () {
    echo >&2 "Invalid VERSION.dat: $1"
    exit 1
}

load_version_data () {
    MAJOR=
    MINOR=
    PATCH=
    PRE_RELEASE_TAG=
    BUILD_METADATA=
    RELEASE_DATE=
    SHLIB_VERSION=

    seen_major=
    seen_minor=
    seen_patch=
    seen_pre_release_tag=
    seen_build_metadata=
    seen_release_date=
    seen_shlib_version=

    [ -r "$VERSION_FILE" ] || version_data_error "cannot read $VERSION_FILE"

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|'#'*)
                continue
                ;;
            MAJOR=*)
                [ -z "$seen_major" ] || version_data_error "duplicate key 'MAJOR'"
                value=${line#MAJOR=}
                case "$value" in
                    ''|*[!0-9]*) version_data_error "invalid value for 'MAJOR'" ;;
                esac
                MAJOR=$value
                seen_major=1
                ;;
            MINOR=*)
                [ -z "$seen_minor" ] || version_data_error "duplicate key 'MINOR'"
                value=${line#MINOR=}
                case "$value" in
                    ''|*[!0-9]*) version_data_error "invalid value for 'MINOR'" ;;
                esac
                MINOR=$value
                seen_minor=1
                ;;
            PATCH=*)
                [ -z "$seen_patch" ] || version_data_error "duplicate key 'PATCH'"
                value=${line#PATCH=}
                case "$value" in
                    ''|*[!0-9]*) version_data_error "invalid value for 'PATCH'" ;;
                esac
                PATCH=$value
                seen_patch=1
                ;;
            PRE_RELEASE_TAG=*)
                [ -z "$seen_pre_release_tag" ] || version_data_error "duplicate key 'PRE_RELEASE_TAG'"
                value=${line#PRE_RELEASE_TAG=}
                case "$value" in
                    *[![:alnum:].-]*) version_data_error "invalid value for 'PRE_RELEASE_TAG'" ;;
                esac
                PRE_RELEASE_TAG=$value
                seen_pre_release_tag=1
                ;;
            BUILD_METADATA=*)
                [ -z "$seen_build_metadata" ] || version_data_error "duplicate key 'BUILD_METADATA'"
                value=${line#BUILD_METADATA=}
                case "$value" in
                    *[![:alnum:].-]*) version_data_error "invalid value for 'BUILD_METADATA'" ;;
                esac
                BUILD_METADATA=$value
                seen_build_metadata=1
                ;;
            RELEASE_DATE=*)
                [ -z "$seen_release_date" ] || version_data_error "duplicate key 'RELEASE_DATE'"
                value=${line#RELEASE_DATE=}
                case "$value" in
                    \"*\")
                        value=${value#\"}
                        value=${value%\"}
                        case "$value" in
                            *[![:alnum:] ]*) version_data_error "invalid value for 'RELEASE_DATE'" ;;
                        esac
                        RELEASE_DATE=$value
                        ;;
                    *)
                        version_data_error "invalid value for 'RELEASE_DATE'"
                        ;;
                esac
                seen_release_date=1
                ;;
            SHLIB_VERSION=*)
                [ -z "$seen_shlib_version" ] || version_data_error "duplicate key 'SHLIB_VERSION'"
                value=${line#SHLIB_VERSION=}
                case "$value" in
                    ''|*[!0-9]*) version_data_error "invalid value for 'SHLIB_VERSION'" ;;
                esac
                SHLIB_VERSION=$value
                seen_shlib_version=1
                ;;
            *)
                version_data_error "unexpected line '$line'"
                ;;
        esac
    done < "$VERSION_FILE"

    [ -n "$seen_major" ] || version_data_error "missing key 'MAJOR'"
    [ -n "$seen_minor" ] || version_data_error "missing key 'MINOR'"
    [ -n "$seen_patch" ] || version_data_error "missing key 'PATCH'"
}

load_version_data

if [ -n "$PRE_RELEASE_TAG" ]; then PRE_RELEASE_TAG=-$PRE_RELEASE_TAG; fi
if [ -n "$BUILD_METADATA" ]; then BUILD_METADATA=+$BUILD_METADATA; fi
version=$MAJOR.$MINOR.$PATCH$PRE_RELEASE_TAG$BUILD_METADATA
basename=openssl

NAME="$basename-$version"

while [ $# -gt 0 ]; do
    case "$1" in
        --name=* ) NAME=`echo "$1" | sed -e 's|[^=]*=||'`       ;;
        --name ) shift; NAME="$1"                               ;;
        --tarfile=* ) TARFILE=`echo "$1" | sed -e 's|[^=]*=||'` ;;
        --tarfile ) shift; TARFILE="$1"                         ;;
        * ) echo >&2 "Could not parse '$1'"; exit 1             ;;
    esac
    shift
done

if [ -z "$TARFILE" ]; then TARFILE="$NAME.tar"; fi

# This counts on .gitattributes to specify what files should be ignored
git archive --worktree-attributes -9 --prefix="$NAME/" -o $TARFILE.gz -v HEAD

# Good old way to ensure we display an absolute path
td=`dirname $TARFILE`
tf=`basename $TARFILE`
ls -l "`cd $td; pwd`/$tf.gz"
