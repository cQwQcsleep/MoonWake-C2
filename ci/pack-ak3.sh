#!/bin/bash
# Fold out_kernel/ into the AnyKernel3 payload: compress the image and attach the
# DTB when the configured output image is a *-dtb variant.
#
# Inputs (env): OUTPUT_IMAGE
set -euo pipefail

cp -a ./out_kernel/. ./AnyKernel3/
cd AnyKernel3

base="$OUTPUT_IMAGE"
dtb_required=false
if [[ "$base" == *-dtb ]]; then
    base="${base%-dtb}"
    dtb_required=true
fi

case "$base" in
    *.gz)
        echo '[pack-ak3] compress with gzip'
        gzip -c Image > "$base"
        rm -f Image
        ;;
    *.lz4)
        echo '[pack-ak3] compress with lz4'
        lz4 -B6 --favor-decSpeed Image "$base"
        rm -f Image
        ;;
esac

if [ "$dtb_required" = true ]; then
    echo '[pack-ak3] attach dtb'
    cat "$base" dtb > "$base-dtb"
    rm -f "$base" dtb
fi

ls -l
