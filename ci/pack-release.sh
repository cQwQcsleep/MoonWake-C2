#!/bin/bash
# Pack downloaded artifacts into flashable zips and select the release assets.
#
# Nothing is published unless at least one _ak3.zip exists and every one of them
# actually contains a kernel image.
#
# Inputs (env): GITHUB_ENV (KERNEL_BUILD_LIST for the Telegram uploader)
set -euo pipefail

mkdir -p packed_kernels release_assets
rm -f packed_kernels/*.zip release_assets/*

for dir in downloaded_kernels/*; do
    [ -d "$dir" ] || continue
    folder_name=$(basename "$dir")
    case "$folder_name" in
        verify-*)
            echo "[=] skip verification bundle: $folder_name"
            continue
            ;;
    esac
    echo "[+] pack $folder_name"
    (
        cd "$dir"
        zip -qr "$OLDPWD/packed_kernels/${folder_name}.zip" .
    )
done

cp packed_kernels/*_ak3.zip release_assets/
find downloaded_kernels -type f \
    \( -name '*_System.map' -o -name '*_config.txt' -o -name '*_ksu.txt' \) \
    -exec cp {} release_assets/ \;

count=$(ls -1 release_assets/*_ak3.zip 2>/dev/null | wc -l)
echo "[pack-release] ak3 zips: $count"
[ "$count" -gt 0 ] || { echo '[pack-release] no _ak3.zip produced, refusing to publish' >&2; exit 1; }

for z in release_assets/*_ak3.zip; do
    unzip -l "$z" | grep -q 'Image' || { echo "[pack-release] $z holds no kernel image" >&2; exit 1; }
done

{
    echo 'KERNEL_BUILD_LIST<<EOF'
    ls -1 "$PWD"/packed_kernels/*.zip
    echo 'EOF'
} >> "$GITHUB_ENV"

ls -lh release_assets
