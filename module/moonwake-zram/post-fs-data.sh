#!/system/bin/sh
# post-fs-data: only touch non-destructive runtime switches.
# Never reset an already initialized zram here.

MODDIR=${0%/*}
/data/adb/modules/moonwake-zram/bin/mwk-zram runtime
