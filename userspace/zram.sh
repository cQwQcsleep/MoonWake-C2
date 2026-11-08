#!/system/bin/sh
# MoonWake C2P: zram configuration + writeback over a loop file.
#
# Install: copy to /data/adb/post-fs-data.d/ (preferred) or
#          /data/adb/service.d/ and chmod 0755.
#
# Tunables (environment or edit below):
#   ZRAM_ALGO=lz4kd            compression algorithm
#   ZRAM_DISKSIZE_PCT=50       swap size as % of MemTotal
#   ZRAM_ENABLE_WRITEBACK=1    1 = enable writeback, 0 = skip
#   ZRAM_BACKING_FILE=/data/adb/zram_backing.img
#   ZRAM_BACKING_MB=2048       backing file size
#   ZRAM_WB_LIMIT_MB=1024      max bytes written back
#
# Notes:
# - backing_dev must be set BEFORE disksize, otherwise -EBUSY.
# - reconfiguring a live zram requires swapoff + reset, which drops any
#   pages currently in swap. At boot time that is harmless.
# - every boot the loop device is recreated, so this script sets it up again.

LOG=/data/adb/moonwake-zram.log
ZRAM_DEV=/dev/block/zram0
ZRAM_SYS=/sys/block/zram0

ZRAM_ALGO=${ZRAM_ALGO:-lz4kd}
ZRAM_RECOMP_ALGO=${ZRAM_RECOMP_ALGO:-}
ZRAM_DISKSIZE_PCT=${ZRAM_DISKSIZE_PCT:-50}
ZRAM_ENABLE_WRITEBACK=${ZRAM_ENABLE_WRITEBACK:-1}
ZRAM_BACKING_FILE=${ZRAM_BACKING_FILE:-/data/adb/zram_backing.img}
ZRAM_BACKING_MB=${ZRAM_BACKING_MB:-2048}
ZRAM_WB_LIMIT_MB=${ZRAM_WB_LIMIT_MB:-1024}

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

wait_for_zram() {
    i=0
    while [ ! -e "$ZRAM_SYS/disksize" ] && [ $i -lt 50 ]; do
        sleep 0.2 2>/dev/null || sleep 1
        i=$((i + 1))
    done
    [ -e "$ZRAM_SYS/disksize" ]
}

memtotal_kb() {
    awk '/^MemTotal:/ {print $2}' /proc/meminfo
}

setup_backing() {
    # 1. backing file (sparse, grows on demand)
    if [ ! -f "$ZRAM_BACKING_FILE" ]; then
        log "create backing file $ZRAM_BACKING_FILE (${ZRAM_BACKING_MB}MB)"
        mkdir -p "$(dirname "$ZRAM_BACKING_FILE")"
        if ! fallocate -l "${ZRAM_BACKING_MB}M" "$ZRAM_BACKING_FILE" 2>/dev/null; then
            dd if=/dev/zero of="$ZRAM_BACKING_FILE" bs=1M count=1 2>/dev/null
            truncate -s "${ZRAM_BACKING_MB}M" "$ZRAM_BACKING_FILE" 2>/dev/null
        fi
    fi

    # 2. loop device
    LOOP=$(losetup -f 2>/dev/null)
    if [ -z "$LOOP" ]; then
        log "no free loop device"
        return 1
    fi
    if ! losetup "$LOOP" "$ZRAM_BACKING_FILE" 2>/dev/null; then
        log "losetup failed on $LOOP"
        return 1
    fi
    log "backing $ZRAM_BACKING_FILE on $LOOP"
    BACKING_DEV=$LOOP
    return 0
}

apply_zram() {
    want_bytes=$(( $(memtotal_kb) * 1024 / 100 * ZRAM_DISKSIZE_PCT ))
    cur_bytes=$(cat "$ZRAM_SYS/disksize" 2>/dev/null || echo 0)
    cur_algo=$(cat "$ZRAM_SYS/comp_algorithm" 2>/dev/null | sed 's/.*\[\(.*\)\].*/\1/')

    need_reset=0
    [ "$cur_bytes" != "$want_bytes" ] && need_reset=1
    [ "$cur_algo" != "$ZRAM_ALGO" ] && need_reset=1
    [ "$ZRAM_ENABLE_WRITEBACK" = "1" ] && need_reset=1

    if [ "$need_reset" = "1" ]; then
        swapoff "$ZRAM_DEV" 2>/dev/null
        echo 1 > "$ZRAM_SYS/reset" 2>/dev/null
        log "reset zram0 (was ${cur_bytes} bytes, $cur_algo)"
    fi

    if [ "$ZRAM_ENABLE_WRITEBACK" = "1" ]; then
        if setup_backing; then
            echo "$BACKING_DEV" > "$ZRAM_SYS/backing_dev" || log "backing_dev write failed"
        else
            log "writeback requested but backing setup failed"
        fi
    fi

    # secondary algorithm must be set before disksize
    if [ -n "$ZRAM_RECOMP_ALGO" ] && [ -w "$ZRAM_SYS/recomp_algorithm" ]; then
        echo "$ZRAM_RECOMP_ALGO" > "$ZRAM_SYS/recomp_algorithm" \
            && log "recomp_algorithm=$ZRAM_RECOMP_ALGO" \
            || log "recomp_algorithm write failed (CONFIG_ZRAM_MULTI_COMP?)"
    fi

    echo "$want_bytes" > "$ZRAM_SYS/disksize" || log "disksize write failed"
    echo "$ZRAM_ALGO" > "$ZRAM_SYS/comp_algorithm" 2>/dev/null || log "comp_algorithm write failed"
    swapon "$ZRAM_DEV" 2>/dev/null || log "swapon failed"

    if [ "$ZRAM_ENABLE_WRITEBACK" = "1" ]; then
        echo 1 > "$ZRAM_SYS/writeback_limit_enable" 2>/dev/null
        echo $(( ZRAM_WB_LIMIT_MB * 1024 * 1024 )) > "$ZRAM_SYS/writeback_limit" 2>/dev/null
        log "writeback limit ${ZRAM_WB_LIMIT_MB}MB"
    fi

    if [ -n "$ZRAM_RECOMP_ALGO" ] && [ -w "$ZRAM_SYS/recompress" ]; then
        echo 1 > "$ZRAM_SYS/recompress" 2>/dev/null \
            && log "recompress pass triggered" \
            || log "recompress trigger failed"
    fi
}

main() {
    wait_for_zram || { log "zram0 not available, abort"; exit 0; }
    apply_zram
    log "disksize=$(cat $ZRAM_SYS/disksize 2>/dev/null) algo=$(cat $ZRAM_SYS/comp_algorithm 2>/dev/null)"
    log "mm_stat=$(cat $ZRAM_SYS/mm_stat 2>/dev/null)"
    [ -e "$ZRAM_SYS/bd_stat" ] && log "bd_stat=$(cat $ZRAM_SYS/bd_stat 2>/dev/null)"
    exit 0
}

main
