#!/system/bin/sh
# KernelSU install script for the MoonWake ZRAM module.

LOG=/data/adb/moonwake-zram.log
CONF=/data/adb/moonwake-zram.conf

ui_print "- MoonWake ZRAM 模块"
ui_print "- 需要 MoonWake C2PN 内核（CONFIG_ZRAM_MULTI_COMP）"

mkdir -p /data/adb
if [ ! -f "$CONF" ]; then
    cat > "$CONF" <<'EOF'
disksize_pct=50
algo=lz4kd
recomp_algo=zstdn
auto_recomp=1
writeback=0
backing_mb=2048
wb_limit_mb=1024
EOF
    chmod 600 "$CONF"
    ui_print "- 已生成默认配置 /data/adb/moonwake-zram.conf"
else
    ui_print "- 保留已有配置"
fi

set_perm_recursive "$MODPATH/bin" 0 0 0755 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "- 安装完成，重启后生效"
