# userspace scripts

这些脚本不属于内核构建，是在设备上用 KernelSU 的脚本目录执行。

## 安装

```bash
# zram 配置 + 回写：越早越好
cp zram.sh /data/adb/post-fs-data.d/zz-moonwake-zram.sh
chmod 0755 /data/adb/post-fs-data.d/zz-moonwake-zram.sh

# 运行时调优
cp mwk-tuning.sh /data/adb/service.d/zz-moonwake-tuning.sh
chmod 0755 /data/adb/service.d/zz-moonwake-tuning.sh
```

脚本也可以放进 KSU 模块的 `post-fs-data.d` / `service.d` 目录，随模块分发。

## zram.sh

在 loop 文件上做 zram 回写，并统一设置算法与容量。

| 变量 | 默认 | 说明 |
|---|---|---|
| `ZRAM_ALGO` | `lz4kd` | 压缩算法 |
| `ZRAM_DISKSIZE_PCT` | `50` | swap 大小占 MemTotal 的百分比 |
| `ZRAM_ENABLE_WRITEBACK` | `1` | 0 = 只调容量与算法，不建回写 |
| `ZRAM_BACKING_FILE` | `/data/adb/zram_backing.img` | 回写文件 |
| `ZRAM_BACKING_MB` | `2048` | 文件大小 |
| `ZRAM_WB_LIMIT_MB` | `1024` | 最大回写量 |

行为要点：

- 先 `swapoff` + `reset`，再设 `backing_dev`，最后设 `disksize`（顺序错了会 `-EBUSY`）
- 已存在且配置一致时不重置
- 每次开机重建 loop（内核重启后 loop 设备不保留）
- 日志：`/data/adb/moonwake-zram.log`，包含 `mm_stat` 与 `bd_stat`

风险：回写目标是闪存，`/data` 若是 f2fs 且开了 `COMPRESSION_ALL`，回写数据会被二次压缩，写入量与时延都会上升。建议先用 `ZRAM_ENABLE_WRITEBACK=0` 只跑容量/算法，确认稳定后再开回写。

## mwk-tuning.sh

运行时调优已经做进内核（仅 C2P），这个脚本只做**只读核对**，不修改任何值：

- `lru_gen.min_ttl_ms`（C2P 内核默认 1000）
- F2FS `readdir_ra`（f2fs 本身默认 1）、`gc_urgent`
- `kernel.dmesg_restrict`（C2P 通过 `CONFIG_SECURITY_DMESG_RESTRICT` 默认 1）
- SELinux 当前模式
- `ksu_susfs` 工具是否就位

日志：`/data/adb/moonwake-tuning.log`。

内核侧对应实现：

| 项 | 位置 |
|---|---|
| MGLRU 1000ms 默认 | `mm/vmscan.c` 的 `lru_gen_min_ttl`，由 `CONFIG_MWK_PERF_PROFILE` 控制 |
| SuSFS 挂载隐藏默认开启 | `fs/susfs.c` 的 `susfs_init()`，同一开关 |
| `dmesg_restrict=1` | C2P 片段里的 `CONFIG_SECURITY_DMESG_RESTRICT=y` |
| F2FS `readdir_ra=1` | f2fs 上游默认已是 1，无需改 |

## 热管理与 GPU

这两类没有写成脚本，避免误改导致发热/掉帧。手动方式见报告：

```bash
# 热 trip（单位 m°C，先确认 zone）
for z in /sys/class/thermal/thermal_zone*; do echo "$z $(cat $z/type) $(cat $z/temp)"; done
echo 72000 > /sys/class/thermal/thermal_zoneX/trip_point_1_temp

# GED
cat /sys/kernel/ged/hal/gpu_utilization
cat /sys/kernel/ged/hal/dvfs_margin_value
cat /sys/kernel/ged/hal/custom_boost_gpu_freq
```
