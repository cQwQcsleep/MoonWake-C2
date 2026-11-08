# F2FS 压缩与挂载参数

## 这棵树实际支持的挂载选项

`fs/f2fs/super.c` 里能解析的（节选）：

```
background_gc=on|off|sync
discard|nodiscard
inline_xattr / inline_data / inline_dentry
flush_merge|noflush_merge
extent_cache|noextent_cache
data_flush
lazytime|nolazytime
checkpoint=disable|enable|disable:<n>|disable:<n>%
compress_algorithm=lzo|lz4|zstd|lz4k|lz4kd|lz4k_oplus|zstdn
compress_log_size=<n>
compress_extension=<ext,ext,...>
```

**不支持**（不要照搬新版教程）：`compress_mode=user`、`nocompress_extension=`、`discard_unit=`、`gc_merge`、`atgc`。

## 白名单方式

内核侧已关闭 `F2FS_FS_COMPRESSION_ALL`（只影响 C2P；C2 保持全量压缩）。在 fstab 的 `/data` 行追加：

```
compress_algorithm=lz4,compress_log_size=2,compress_extension=txt,log,json,db,sqlite,doc,docx,pdf
```

注意：

- 不要放 `so/apk/zip/mp4/jpg/png`，这些高熵或随机读的文件压缩只会增加写放大与解压延迟
- 改 fstab 属于 vendor 侧改动，内核侧不需要重新构建
- `compress_algorithm` 只能用本树编译进去的算法，见 `arch/arm64/configs/vendor/compression.config`

## sysfs 调优

```bash
# 目录预读（默认已是 1）
cat /sys/fs/f2fs/dm-*/readdir_ra

# 空闲时触发 GC，不要在正常使用时常开
echo 1 > /sys/fs/f2fs/dm-*/gc_urgent
echo 0 > /sys/fs/f2fs/dm-*/gc_urgent

# 观测（仅调试用，本身有开销）
echo 1 > /sys/fs/f2fs/dm-*/iostat_enable
cat /sys/fs/f2fs/dm-*/iostat
```

## 验证压缩是否生效

```bash
# 1. 超级块特性
adb shell su -c 'cat /sys/fs/f2fs/dm-*/features'   # 应含 compression

# 2. 新文件是否带压缩标志
adb shell su -c 'dd if=/dev/zero of=/data/local/tmp/t.bin bs=1M count=20'
adb shell su -c 'lsattr /data/local/tmp/t.bin'      # 应含 c
adb shell su -c 'du -h /data/local/tmp/t.bin'       # 应明显小于 20M
```

白名单模式下，只有扩展名匹配的文件会带 `c` 标志，其他文件应当没有。

## A/B 方法

- 指标：`am start -W` 的冷启动 P50/P95、`f2fs iostat` 的写放大、`/data` 占用
- 顺序：C2（全量压缩）vs C2P（白名单）vs C2P（关闭压缩）
- 只看磁盘占用会得出错误结论，必须同时看启动时间与写放大
