#! /bin/sh

HERE=`dirname $0`

format_sha256()
{
    digest=$1
    file=$2

    printf '%s  %s\n' "${digest%% *}" "$file"
}

validate_filename()
{
    file=$1

    if LC_ALL=C printf '%s' "$file" | grep '[[:cntrl:]]' >/dev/null 2>&1; then
        echo "Refusing filename with control characters" >&2
        exit 1
    fi
}

for f in "$@"; do
    # It's worth nothing that 'openssl sha256 -r' assumes that all input
    # is binary.  This isn't quite true, and we know better, so we convert
    # the '*stdin' marker to the filename preceded by a space.  See the
    # sha1sum manual for a specification of the format.
    validate_filename "$f"

    case "$f" in
        *.c | *.c.in | *.h | *.h.in | *.inc)
            digest=$("$HERE"/lang-compress.pl 'C' < "$f" \
                | unifdef -DFIPS_MODULE=1 \
                | openssl sha256 -r) || exit $?
            format_sha256 "$digest" "$f"
            ;;
        *.pl )
            digest=$("$HERE"/lang-compress.pl 'perl' < "$f" \
                | openssl sha256 -r) || exit $?
            format_sha256 "$digest" "$f"
            ;;
        *.S )
            digest=$("$HERE"/lang-compress.pl 'S' < "$f" \
                | openssl sha256 -r) || exit $?
            format_sha256 "$digest" "$f"
            ;;
    esac
done
