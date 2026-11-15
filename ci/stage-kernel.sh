#!/bin/bash
# Extract the kernel image (and DTB, when the output image carries one) from the
# build tree into out_kernel/.
#
# Inputs (env): OUT_DIR, ARCH, OUTPUT_IMAGE
set -euo pipefail

boot="$OUT_DIR/arch/$ARCH/boot"
mkdir -p out_kernel

if [[ "$OUTPUT_IMAGE" == *-dtb* ]]; then
    cp -f "$boot/$OUTPUT_IMAGE" out_kernel/
    cd out_kernel
    echo "[stage-kernel] locating DTB inside $OUTPUT_IMAGE"
    offset=$(binwalk "$OUTPUT_IMAGE" | grep 'Flattened device tree' | awk '{print $1; exit}')
    [ -n "${offset:-}" ] || { echo "[stage-kernel] no DTB found inside $OUTPUT_IMAGE" >&2; exit 1; }
    echo "[stage-kernel] DTB offset: $offset"
    dd if="$OUTPUT_IMAGE" of=dtb bs=1 skip="$offset" status=none
    cp -f "$boot/Image" .
    rm -f Image.gz "$OUTPUT_IMAGE"
    cd ..
else
    cp -f "$boot/Image" out_kernel/
fi

ls -l out_kernel
