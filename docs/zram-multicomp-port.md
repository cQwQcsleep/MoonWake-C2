# ZRAM MULTI_COMP 回移

状态：**阶段 1 与手动重压缩已实现**（分支 `feature/zram-multicomp`，未合入 `c2`，未构建、未实机验证）。

## 已实现

| 能力 | 说明 |
|---|---|
| 每页算法记录 | `table[index].flags` 的 bit30–31 存算法索引（`ZRAM_ALGO_SHIFT`），不额外占内存 |
| 主算法 | 新写入一律用 `comp_algorithm`，索引 0 |
| 次算法 | `recomp_algorithm`，必须在 `disksize` 之前设置 |
| 手动重压缩 | `echo 1 > /sys/block/zramX/recompress`，只重压"更小"的页 |
| 读路径 | 按每页记录的算法解密，切换算法不会读错历史页 |

## 配置

`arch/arm64/configs/vendor/perf-c2pn.config`（C2PN 专用片段）：

```
CONFIG_ZRAM_MULTI_COMP=y
```

C2 与 C2P 都不开启，行为完全不变。

## 使用

```bash
# 1. 先设次算法（必须在 disksize 之前）
echo zstdn > /sys/block/zram0/recomp_algorithm

# 2. 正常配置主算法与容量
echo lz4kd > /sys/block/zram0/comp_algorithm
echo 3G > /sys/block/zram0/disksize
swapon /dev/block/zram0

# 3. 空闲时手动触发一次重压缩
echo 1 > /sys/block/zram0/recompress
dmesg | tail -1        # zram0: recompressed N pages
cat /sys/block/zram0/mm_stat
```

`userspace/zram.sh` 也支持这套流程：

```bash
ZRAM_RECOMP_ALGO=zstdn ./zram.sh
```

脚本会先设 `recomp_algorithm`，再设 `disksize`，最后触发一次重压缩。

## 实现要点

| 位置 | 改动 |
|---|---|
| `drivers/block/zram/Kconfig` | 新增 `ZRAM_MULTI_COMP` |
| `drivers/block/zram/zram_drv.h` | `comps[]`、`nr_comps`、`recompressor[]`、算法位定义 |
| `zram_drv.c` | 读路径按页选算法；写路径固定主算法；`disksize` 创建多个 zcomp；`reset` 全部销毁 |
| `zram_drv.c` | `zram_recompress_slot()`：锁内只做快照，压缩与分配的慢路径在锁外，提交前校验 handle/size 未变 |
| `zram_drv.c` | 新增 `recomp_algorithm`、`recompress` 两个 sysfs |

安全设计：

- 重压缩**跳过**已回写（`ZRAM_WB`）、同值页（`ZRAM_SAME`）、大页（`ZRAM_HUGE`）
- 提交时原子校验 `handle` 与 `obj_size`，不匹配就丢弃新句柄，避免与并发写冲突
- 只有新长度小于原长度才替换，且同步修正 `compr_data_size` 统计
- 失败路径统一 `zs_free` 新句柄，不会泄漏

## 验证情况

- `ZRAM_MULTI_COMP=y`：`drivers/block/zram/zram_drv.o` 用 clang 18 + C2P 真实合并配置编译通过
- `ZRAM_MULTI_COMP=n`：同一份源码编译通过，C2 路径无回归

未做：

- 未做自动触发（上游的 idle 扫描 + 阈值）
- 未在真机验证（swap 出问题会直接卡死或损坏数据）
- 未与 writeback 组合做压力测试

## 后续

1. 真机验证：`lz4kd + zstdn`，跑内存压力与循环读写，观察 `mm_stat`、`bd_stat`、OOM
2. 稳定后再评估自动触发（按 idle 页比例或定时）
3. 与 writeback 同时开启时，确认回写页不会被重压缩影响

## 风险

- 4.19 的 `zsmalloc` 与 5.x 差异大，本实现是独立写的，不是 cherry-pick
- `flags` 高位被占用后，任何清除 flags 的路径都必须保留 bit30–31；`zram_free_page` 的 `WARN_ON_ONCE` 掩码已同步更新
- 重压缩是 CPU 密集操作，应在充电/空闲时手动触发，不要放进开机流程
