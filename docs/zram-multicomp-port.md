# ZRAM MULTI_COMP 回移评估

## 目标

- 热页用低延迟算法（`lz4` / `lz4kd`）
- 冷页用高压缩比算法（`zstd` / `zstdn`）重压缩
- 保持 4.19 现有 `writeback` 能力不被破坏

## 上游形态

`ZRAM_MULTI_COMP` 在 5.1 引入，核心是：

- `zram` 每个 slot 记录自己的算法 id（`zcomp` 句柄数组）
- `recompress` 逻辑：扫描 slot，用第二算法重压缩，失败则保留原数据
- `CONFIG_ZRAM_MULTI_COMP` + sysfs `comp_algorithm` 支持多值

## 4.19 需要改动的位置

| 文件 | 改动 |
|---|---|
| `drivers/block/zram/zram_drv.c` | slot 表增加 `comp_algorithm` 索引；`zram_bvec_rw` 分派到对应 zcomp；新增 `recompress` 入口 |
| `drivers/block/zram/zram_drv.h` | `struct zram` 增加 `comp_algs[]`、`recomp_algorithm` |
| `drivers/block/zram/zcomp.c` / `zcomp.h` | 支持多后端实例，保持现有 `zcomp_create` 兼容 |
| `drivers/block/zram/Kconfig` | 新增 `ZRAM_MULTI_COMP`、`ZRAM_RECOMPRESS` |
| `drivers/block/zram/Makefile` | 视拆分方式调整 |

注意点：

- 4.19 的 `zram` 是 per-CPU 单流（`max_comp_streams` 无效），多算法要按 slot 查表，不能按 CPU
- `writeback` 与 `recompress` 会互相影响：已回写的页不应再参与重压缩
- `zsmalloc` 的 handle 布局不变，否则会破坏已有 swap 页

## 分阶段

1. **只做多算法**：`comp_algorithm` 支持多个值、按 slot 记录，不实现重压缩。这一步风险最低，可先验证功能正确性。
2. **加重压缩**：扫描 idle slot，用第二算法重压；加 `recompress` sysfs 手动触发，先不做自动。
3. **自动策略**：参考 5.x 的 `idle` + `recompress` 阈值，做按需触发。

## 验证

- 参数：`comp_algorithm`、`mm_stat`、`bd_stat`、`/proc/vmstat`（`pswpout`/`pswpin`）
- 压力：大内存应用循环、相机、游戏；观察 OOM 与卡顿
- 数据完整性：`swapon` 后跑 `memtester` 或循环读写比对
- 回滚：保留单算法配置，出问题直接回 C2/C2P

## 风险

- zram 是 swap，出错直接卡死或数据损坏
- 4.19 的 `zsmalloc` 与 5.x 差异大，不能直接 cherry-pick
- 与 `writeback` 的交互需要单独测试，不能只测单算法场景

## 结论

可行，但属于**测试机专项**，不建议直接进 release。建议先做阶段 1，用独立分支与独立变体验证。
