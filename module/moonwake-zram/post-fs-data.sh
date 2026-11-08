#!/system/bin/sh
# Runs in the post-fs-data stage: apply the saved zram profile.

MODDIR=${0%/*}
/data/adb/modules/moonwake-zram/bin/mwk-zram apply
