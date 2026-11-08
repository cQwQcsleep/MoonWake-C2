#!/system/bin/sh
# MoonWake C2P: runtime tuning that does not need a kernel rebuild.
#
# Install: copy to /data/adb/service.d/ and chmod 0755.
# Everything here is best-effort: a missing node is logged, not fatal.

LOG=/data/adb/moonwake-tuning.log

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

# 1. MGLRU: 1000ms minimum TTL, smooths out ~100ms class stalls.
if [ -w /sys/kernel/mm/lru_gen/min_ttl_ms ]; then
    echo 1000 > /sys/kernel/mm/lru_gen/min_ttl_ms 2>/dev/null \
        && log "lru_gen.min_ttl_ms=1000" || log "min_ttl_ms write failed"
else
    log "lru_gen not present"
fi

# 2. F2FS directory read-ahead (helps app enumeration / large dirs).
for d in /sys/fs/f2fs/*/; do
    [ -w "${d}readdir_ra" ] && echo 1 > "${d}readdir_ra" 2>/dev/null \
        && log "readdir_ra=1 ${d}"
done

# 3. dmesg restricted to root.
if [ -w /proc/sys/kernel/dmesg_restrict ]; then
    echo 1 > /proc/sys/kernel/dmesg_restrict 2>/dev/null && log "dmesg_restrict=1"
fi

# 4. SELinux must stay enforcing; log a warning if it is not.
if command -v getenforce >/dev/null 2>&1; then
    mode=$(getenforce 2>/dev/null)
    log "selinux=$mode"
    [ "$mode" = "Enforcing" ] || log "WARNING: selinux is $mode"
fi

# 5. SuSFS: hide module mounts from non-su processes (static key, default off).
for tool in /data/adb/ksu/bin/ksu_susfs /data/adb/modules/*/bin/ksu_susfs; do
    [ -x "$tool" ] || continue
    "$tool" hide_sus_mnts_for_non_su_procs 1 >/dev/null 2>&1 \
        && log "susfs hide_sus_mnts_for_non_su_procs=1 via $tool" \
        || log "susfs hide_sus_mnts failed via $tool"
    break
done

# 6. Optional: keep gc_urgent off during normal use.
for d in /sys/fs/f2fs/*/; do
    [ -w "${d}gc_urgent" ] && echo 0 > "${d}gc_urgent" 2>/dev/null
done

exit 0
