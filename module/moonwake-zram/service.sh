#!/system/bin/sh
# Runs in the late_start service stage: keep the runtime switches in sync and
# optionally kick one recompression pass after boot settles.

MODDIR=${0%/*}
BIN=/data/adb/modules/moonwake-zram/bin/mwk-zram

# wait for boot to settle before touching zram again
i=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ] && [ $i -lt 60 ]; do
    sleep 2
    i=$((i + 1))
done

$BIN apply

# give the system a minute, then trigger one pass if the secondary algorithm
# is configured and auto recompression is off
auto=$(cat /sys/block/zram0/auto_recompress 2>/dev/null || echo 0)
recomp=$(cat /sys/block/zram0/recomp_algorithm 2>/dev/null || echo none)
if [ "$auto" = "0" ] && [ "$recomp" != "none" ]; then
    sleep 60
    echo 1 > /sys/block/zram0/recompress 2>/dev/null
fi
