#!/bin/sh
set -eu

GKI_ROOT=$(pwd)
OWNER="cQwQcsleep"
REPO="KernelSU-Next"

display_usage() {
    echo "Usage: $0 [--cleanup | <commit-or-tag>]"
    echo "  --cleanup:              Cleans up previous modifications made by the script."
    echo "  <commit-or-tag>:        Sets up or updates the KernelSU-Next to specified tag or commit."
    echo "  -h, --help:             Displays this usage information."
    echo "  (no args):              Sets up or updates the KernelSU-Next environment to the latest tagged version."
}

initialize_variables() {
    if test -d "$GKI_ROOT/common/drivers"; then
         DRIVER_DIR="$GKI_ROOT/common/drivers"
    elif test -d "$GKI_ROOT/drivers"; then
         DRIVER_DIR="$GKI_ROOT/drivers"
    else
         echo '[ERROR] "drivers/" directory not found.'
         exit 127
    fi

    DRIVER_MAKEFILE=$DRIVER_DIR/Makefile
    DRIVER_KCONFIG=$DRIVER_DIR/Kconfig
}

# Reverts modifications made by this script
perform_cleanup() {
    echo "[+] Cleaning up..."
    if [ -L "$DRIVER_DIR/kernelsu" ]; then
        rm "$DRIVER_DIR/kernelsu" && echo "[-] Symlink removed."
    fi
    if grep -q "kernelsu" "$DRIVER_MAKEFILE"; then
        sed -i '/kernelsu/d' "$DRIVER_MAKEFILE" && echo "[-] Makefile reverted."
    fi
    if grep -q "drivers/kernelsu/Kconfig" "$DRIVER_KCONFIG"; then
        sed -i '/drivers\/kernelsu\/Kconfig/d' "$DRIVER_KCONFIG" && echo "[-] Kconfig reverted."
    fi
}

# Locate an in-repository vendored KernelSU-Next checkout, if there is one.
# Works both in CI (kernel cloned into $GITHUB_WORKSPACE/<name>) and for a local
# build run from the monorepo root.
find_vendored() {
    for candidate in \
        "${GITHUB_WORKSPACE:-/nonexistent}/kernelsu/KernelSU-Next" \
        "$GKI_ROOT/kernelsu/KernelSU-Next" \
        "$GKI_ROOT/../kernelsu/KernelSU-Next"
    do
        if [ -d "$candidate/kernel" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

upstream_field() {
    sed -n "s/^$1=//p" "$1_UPSTREAM_FILE" 2>/dev/null || true
}

# Sets up or update KernelSU-Next environment
setup_kernelsu() {
    echo "[+] Setting up $REPO..."

    if KSU_SRC=$(find_vendored); then
        echo "[+] Using vendored KernelSU-Next: $KSU_SRC"
        _UPSTREAM_FILE="$KSU_SRC/UPSTREAM"
        if [ -f "$_UPSTREAM_FILE" ]; then
            VENDOR_BRANCH=$(sed -n 's/^branch=//p' "$_UPSTREAM_FILE" | head -n1)
            VENDOR_COMMIT=$(sed -n 's/^commit=//p' "$_UPSTREAM_FILE" | head -n1)
            echo "[+] UPSTREAM branch=$VENDOR_BRANCH commit=$VENDOR_COMMIT"
            if [ -n "${1-}" ] && [ -n "$VENDOR_BRANCH" ] && [ "$1" != "$VENDOR_BRANCH" ]; then
                echo "[ERROR] setupArg '$1' does not match vendored UPSTREAM branch '$VENDOR_BRANCH'." >&2
                echo "[ERROR] A vendored tree cannot be re-pointed at another ref; update the vendored" >&2
                echo "[ERROR] checkout and UPSTREAM together, or fix the config's setupArg." >&2
                exit 1
            fi
        else
            echo "[!] $KSU_SRC/UPSTREAM is missing; provenance of the vendored tree is unknown."
        fi
        if [ ! -f "$KSU_SRC/kernel/Kconfig" ]; then
            echo "[ERROR] $KSU_SRC/kernel/Kconfig not found; not a KernelSU-Next kernel tree." >&2
            exit 1
        fi
        ln -sfn "$KSU_SRC" "$GKI_ROOT/$REPO"
        KSU_LINK_SRC="$KSU_SRC/kernel"
    else
        KSU_SRC="$GKI_ROOT/$REPO"
        if [ ! -d "$KSU_SRC" ]; then
            git clone "https://github.com/$OWNER/$REPO" "$KSU_SRC"
        fi
        cd "$KSU_SRC"
        git stash >/dev/null 2>&1 || true

        BRANCH="$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's@^origin/@@' || true)"
        if [ -n "$BRANCH" ] && git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
            git checkout "$BRANCH"
        fi
        git pull || echo "[!] git pull failed; continuing with the existing checkout"

        if [ -z "${1-}" ]; then
            git checkout "$(git describe --abbrev=0 --tags)"
        else
            git checkout "$1" || { echo "[ERROR] cannot check out '$1' in $REPO." >&2; exit 1; }
        fi
        KSU_LINK_SRC="$KSU_SRC/kernel"
        cd "$GKI_ROOT"
    fi

    cd "$DRIVER_DIR"
    ln -sfn "$(realpath --relative-to="$DRIVER_DIR" "$KSU_LINK_SRC")" "kernelsu" && echo "[+] Symlink created."

    if ! grep -q "kernelsu" "$DRIVER_MAKEFILE"; then
        printf '\nobj-$(CONFIG_KSU) += kernelsu/\n' >> "$DRIVER_MAKEFILE"
        echo "[+] Modified Makefile."
    fi

    if ! grep -q 'source "drivers/kernelsu/Kconfig"' "$DRIVER_KCONFIG"; then
        sed -i '/endmenu/i\source "drivers/kernelsu/Kconfig"' "$DRIVER_KCONFIG"
        echo "[+] Modified Kconfig."
    fi
    echo '[+] Done.'
}

# Process command-line arguments
if [ "$#" -eq 0 ]; then
    initialize_variables
    setup_kernelsu
elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    display_usage
elif [ "$1" = "--cleanup" ]; then
    initialize_variables
    perform_cleanup
else
    initialize_variables
    setup_kernelsu "$@"
fi
