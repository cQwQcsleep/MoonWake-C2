#!/system/bin/sh
# MoonWake C2P: verification helper.
#
# The runtime tuning itself is now compiled into the kernel (C2P only), so this
# script only reports the effective values. It changes nothing.
#
# Install: copy to /data/adb/service.d/ and chmod 0755 (optional).

OUT=/data/adb/moonwake-tuning.log

{
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') ==="

    # MGLRU minimum TTL: kernel default is 1000ms under CONFIG_MWK_PERF_PROFILE
    if [ -r /sys/kernel/mm/lru_gen/min_ttl_ms ]; then
        echo "lru_gen.min_ttl_ms=$(cat /sys/kernel/mm/lru_gen/min_ttl_ms)"
    else
        echo "lru_gen: not present"
    fi

    # F2FS readdir readahead: f2fs defaults this to 1 in super.c
    for d in /sys/fs/f2fs/*/; do
        [ -r "${d}readdir_ra" ] && echo "readdir_ra ${d}=$(cat "${d}readdir_ra")"
        [ -r "${d}gc_urgent" ] && echo "gc_urgent ${d}=$(cat "${d}gc_urgent")"
    done

    # dmesg restricted to root (CONFIG_SECURITY_DMESG_RESTRICT sets default 1)
    echo "dmesg_restrict=$(cat /proc/sys/kernel/dmesg_restrict 2>/dev/null)"

    # SELinux must stay enforcing
    command -v getenforce >/dev/null 2>&1 && echo "selinux=$(getenforce 2>/dev/null)"

    # SuSFS: mount hiding for non-su processes is enabled at susfs_init()
    for tool in /data/adb/ksu/bin/ksu_susfs /data/adb/modules/*/bin/ksu_susfs; do
        [ -x "$tool" ] || continue
        "$tool" show enabled_features 2>/dev/null | tr ' ' '\n' | grep -c . >/dev/null
        echo "susfs_tool=$tool"
        break
    done
} >> "$OUT" 2>&1

exit 0
