#!/bin/bash
# Build the make argument string from the config params block.
#
# Inputs (env): params (params JSON object), OUT_DIR, GITHUB_WORKSPACE, ccache
# Outputs (GITHUB_OUTPUT): args, ARCH
set -euo pipefail

ARCH="$(jq -r '.ARCH // ""' <<< "$params")"
CC="$(jq -r '.CC // ""' <<< "$params")"
KCFLAGS="$(jq -r '.KCFLAGS // ""' <<< "$params")"
KAFLAGS="$(jq -r '.KAFLAGS // ""' <<< "$params")"

args="-j$(nproc --all)"

if [ -n "${OUT_DIR:-}" ]; then
    mkdir -p "$OUT_DIR"
    args="$args O=$OUT_DIR"
fi

if [ -n "$ARCH" ]; then
    args="$args ARCH=$ARCH"
fi

if [ -n "$KCFLAGS" ]; then
    args="$args KCFLAGS=\"$KCFLAGS\""
fi

if [ -n "$KAFLAGS" ]; then
    args="$args KAFLAGS=\"$KAFLAGS\""
fi

if [ -n "$CC" ]; then
    case "$CC" in
        */*) CC="$GITHUB_WORKSPACE/$CC" ;;
    esac
    if [ "${ccache:-false}" = true ]; then
        args="$args CC=\"ccache $CC\""
    else
        args="$args CC=$CC"
    fi
fi

while IFS= read -r kv; do
    [ -n "$kv" ] || continue
    key="${kv%%=*}"
    value="${kv#*=}"
    case "$value" in
        */*) value="$GITHUB_WORKSPACE/$value" ;;
    esac
    args="$args $key=$value"
done < <(jq -r '.externalCommand // {} | to_entries[] | "\(.key)=\(.value)"' <<< "$params")

echo "ARGS: $args"
{
    echo "ARCH=$ARCH"
    echo "args=$args"
} >> "$GITHUB_OUTPUT"
