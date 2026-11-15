#!/bin/bash
# Resolve the *_link entries of a config to audited local copies under ci/.
#
# The workflow never executes a script fetched from a moving branch. Every link
# is mapped to a committed file in ci/ by basename; if the link points into this
# repository, the remote bytes must match the local copy (drift fails the build).
#
# Inputs (env): KSU_SETUP_LINK, ADDITIONAL_LINK, ADDITIONAL_POST_LINK,
#               GITHUB_WORKSPACE, GITHUB_REPOSITORY, GITHUB_ENV
# Outputs (GITHUB_ENV): KSU_SETUP_SCRIPT, ADDITIONAL_SCRIPT, ADDITIONAL_POST_SCRIPT
set -euo pipefail

: > /tmp/resolved-scripts.env

resolve() {
    url="$1"
    out_var="$2"

    case "$url" in
        ''|null|disabled)
            echo "$out_var=" >> /tmp/resolved-scripts.env
            echo "[-] $out_var: not configured"
            return 0
            ;;
    esac

    base="$(basename "$url")"
    local_copy="${GITHUB_WORKSPACE}/ci/$base"
    [ -f "$local_copy" ] || {
        echo "ERROR: $url has no audited copy at ci/$base" >&2
        return 1
    }

    case "$url" in
        *"/${GITHUB_REPOSITORY}/"*)
            curl -fsSL -o "/tmp/$base.remote" "$url"
            if ! cmp -s "/tmp/$base.remote" "$local_copy"; then
                echo "ERROR: $url drifted from audited ci/$base" >&2
                diff -u "$local_copy" "/tmp/$base.remote" | head -n 40 >&2 || true
                return 1
            fi
            echo "[+] $base: remote bytes match audited ci/$base"
            ;;
        *)
            echo "[+] $base: external URL, executing audited local copy"
            ;;
    esac

    echo "$out_var=$local_copy" >> /tmp/resolved-scripts.env
}

resolve "${KSU_SETUP_LINK:-}" KSU_SETUP_SCRIPT
resolve "${ADDITIONAL_LINK:-}" ADDITIONAL_SCRIPT
resolve "${ADDITIONAL_POST_LINK:-}" ADDITIONAL_POST_SCRIPT

cat /tmp/resolved-scripts.env >> "$GITHUB_ENV"
