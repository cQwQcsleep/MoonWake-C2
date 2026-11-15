#!/bin/sh
# Compute / verify / pin the digest of the vendored KernelSU-Next kernel tree.
#
# Usage:
#   sh ci/vendor-digest.sh --check   verify the tree against tree_sha256= in UPSTREAM
#   sh ci/vendor-digest.sh --print   print the current digest
#   sh ci/vendor-digest.sh --write   write the current digest into UPSTREAM
#
# --check exits non-zero on drift, and prints the digest plus the pinning command
# when UPSTREAM has no tree_sha256= yet (unpinned, advisory mode).
set -eu

MODE="${1:---check}"
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
KSU_ROOT="$REPO_ROOT/kernelsu/KernelSU-Next"
KERNEL_DIR="$KSU_ROOT/kernel"
UPSTREAM="$KSU_ROOT/UPSTREAM"

[ -d "$KERNEL_DIR" ] || { echo "[vendor-digest] missing $KERNEL_DIR" >&2; exit 1; }
[ -f "$UPSTREAM" ] || { echo "[vendor-digest] missing $UPSTREAM" >&2; exit 1; }

compute() {
    (
        cd "$KERNEL_DIR" || exit 1
        find . -path ./.git -prune -o -path ./.vscode -prune -o -type f -print0 \
            | LC_ALL=C sort -z \
            | xargs -0 -r sha256sum \
            | sha256sum \
            | cut -d' ' -f1
    )
}

ACTUAL="$(compute)"
EXPECTED="$(sed -n 's/^tree_sha256=//p' "$UPSTREAM" | head -n1)"

case "$MODE" in
    --print)
        echo "$ACTUAL"
        ;;
    --write)
        if grep -q '^tree_sha256=' "$UPSTREAM"; then
            sed -i "s|^tree_sha256=.*|tree_sha256=$ACTUAL|" "$UPSTREAM"
        else
            printf 'tree_sha256=%s\n' "$ACTUAL" >> "$UPSTREAM"
        fi
        printf 'tree_digest_scope=kernelsu/KernelSU-Next/kernel\n' >> "$UPSTREAM"
        echo "[vendor-digest] pinned tree_sha256=$ACTUAL"
        ;;
    --check)
        if [ -z "$EXPECTED" ]; then
            echo '[vendor-digest] tree is UNPINNED (no tree_sha256= in UPSTREAM)'
            echo "[vendor-digest] current digest: $ACTUAL"
            echo '[vendor-digest] pin it with: sh ci/vendor-digest.sh --write'
            exit 0
        fi
        if [ "$EXPECTED" != "$ACTUAL" ]; then
            echo '[vendor-digest] DRIFT DETECTED' >&2
            echo "[vendor-digest] expected: $EXPECTED" >&2
            echo "[vendor-digest] actual:   $ACTUAL" >&2
            echo '[vendor-digest] re-audit the vendored tree, then re-pin with --write' >&2
            exit 1
        fi
        echo "[vendor-digest] OK tree_sha256=$ACTUAL"
        ;;
    *)
        echo "usage: $0 [--check|--print|--write]" >&2
        exit 2
        ;;
esac
