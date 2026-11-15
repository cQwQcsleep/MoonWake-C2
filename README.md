# MoonWake C2

Xiaomi ruby（MT6877）的 Linux 4.19.325 内核，包含 KernelSU-Next + SuSFS、F2FS/ZRAM 压缩，可直接在本仓库构建。

## 版本

| 项 | 值 |
|---|---|
| 设备 | Xiaomi ruby |
| 内核 | Linux 4.19.325，non-GKI |
| Root | KernelSU-Next + SuSFS v2.3.0 |
| KernelSU 版本 | `33226`（`legacy-susfs-v2-susmount@75143d5`） |
| 版本名 | `4.19.325-MoonWake-2.7.0-C2` 至 `-C2K` |
| Release 标识 | `mwk-2.7.0-<run_number>`（每次构建一个 Release） |
| 构建配置 | `configs/release/compression-c2*.json` |

### 命名规则

按 `C2A`、`C2B` … `C2Z` 顺序递增；26 个字母用完后进位为 `C3`，再从 `C3A`、`C3B` 继续。

### C2 系列变体

| 版本 | GPU | CPU A78 | 额外配置 |
|---|---|---|---|
| C2A | 原厂 950MHz | 原厂 2600MHz | 无 |
| C2B | 1100MHz | 原厂 2600MHz | `gpu_oc` |
| C2C | 原厂 950MHz | 2800MHz | `cpu_oc_2800` |
| C2D | 1100MHz | 2800MHz | `gpu_oc` + `cpu_oc_2800` |
| C2E | 原厂 950MHz | 2800/3000MHz | `cpu_oc_2800` + `cpu_oc_3000` |
| C2F | 1100MHz | 2800/3000MHz | `gpu_oc` + `cpu_oc_2800` + `cpu_oc_3000` |
| C2G | 1100MHz | 2800/3000MHz | 完整插档：GPU 40 档、CPU A78 18 档（MCUPM 只有 16 槽，18 档索引会被截断，实际不可用） |
| C2H | 1100MHz | 2800/3000MHz | 修正版：GPU 40 档、CPU 16 档（3.0/2.8GHz 与 2.2/2.1GHz 替换两个原厂中频，同步修正 MCUPM/PVT 表） |
| C2H-V1 | 1100MHz | 3000…650MHz | 纯重排：A78 最低 650MHz@550mV，A55 最低 500MHz@550mV，低风险 |
| C2H-V2 | 1100MHz | 3000…400MHz | 激进下探：A78 最低 400MHz@500mV，A55 最低 300MHz@500mV，PLL 1.2GHz 临界，高风险 |
| C2H-V3 | 1100MHz | 3000…500MHz | 温和下探：A78 最低 500MHz@525mV，A55 最低 400MHz@525mV，PLL ≥1.6GHz，中风险 |
| C2K | 1100MHz | 2800/3000MHz | schedutil 升级版（C2H 基线频点）：uclamp 封顶修复、iowait boost 重写、固定参考频率、`effective_cpu_util()` 统一口径 |

C2A–C2F 作为多版本批次并行构建，合并发布到一个 Release；C2G 使用同一套报告调频参数单独构建；C2H 修正 C2G 的 CPU 档位与 MCUPM 索引不匹配问题；C2H-V1/V2/V3 共用 `compression-c2h-plans.json` 一次性并行构建并合并发布；C2K 在独立 `c2k` 分支上构建。

三套 C2H 频点方案的 OPP 表、PLL 分频和 MCUPM/PVT 表由 `CONFIG_MTK_CPU_FREQ_V1/V2/V3` 切换，三个变体互斥；未选择时回落到 C2H 基线表。

C2K 的 schedutil 变更（相对 C2H）：

- `uclamp_rq_is_capped()`：`uclamp_max` 封顶后不再被 `sugov_hold_freq()` 的保持逻辑或 iowait boost 突破
- iowait boost 改为在 `effective_cpu_util()` 结果上叠加并受 `max` 夹紧，不再用 `max(boost, util)` 覆盖
- `sugov_cpu_is_busy()` 重构为 `sugov_hold_freq()`，`need_freq_update` 时强制下发
- `get_next_freq()` 的线性路径改用固定参考频率 `policy->cpuinfo.max_freq`；C2K 仍启用 MTK `CONFIG_NONLINEAR_FREQ_CTL`，该平台走 `mtk_map_util_freq()` 的 OPP 表映射，此项仅在关闭非线性调频时生效
- `schedutil_cpu_util()` 移到 `kernel/sched/core.c` 并重命名为 `effective_cpu_util()`，EAS 能耗计算与 governor 共用同一套 util 口径
- `map_util_freq()` 改为 64 位乘法，消除 3.0GHz 档位的 32 位溢出风险
- cpufreq 核心新增 governor `flags` 与 `CPUFREQ_NEED_UPDATE_LIMITS`，limits 变化时保证驱动被调用
- `sched_runtime`/`sched_deadline`/`sched_period` 改用 `NSEC_PER_MSEC`（仅可读性）
- 未纳入：runnable boosting、reduced capacity、thermal pressure、`adjust_perf`、sched_ext。前四项依赖 5.7+/6.x 的 PELT/EM/驱动框架或本平台未实现 `adjust_perf` 回调，sched_ext 在 4.19 无对应框架；强行回迁会改动调度器核心，风险远大于收益

## 包含的内容

- **F2FS 压缩**：LZO / LZ4 / ZSTD / LZO-RLE / LZ4K / LZ4KD / LZ4K_OPLUS / ZSTDN
- **ZRAM 算法**：lzo / lzo-rle / lz4 / lz4hc / lz4k / lz4k_oplus / lz4kd / zstd / zstdn
- **KernelSU-Next + SuSFS**：SUS_MOUNT / TRY_UMOUNT / SUS_PATH / SUS_MAP / SUS_KSTAT / SPOOF 等
- **HybridMount**
- **MGLRU**
- **FPSGO / TouchBoost**
- **UFS blk-mq**
- **HyperMoon 日志配置**

## 仓库结构

```text
.github/workflows/build.yml
configs/release/compression-c2.json
anykernel3/
kernelsu/KernelSU-Next/
ci/
arch/ fs/ mm/ drivers/ ...
```

AnyKernel3 和 KernelSU-Next 已放在仓库内，构建时直接使用。只有 clang 工具链是外部下载。

KernelSU-Next 的上游来源与固定版本记录在 `kernelsu/KernelSU-Next/UPSTREAM`，构建时通过 `KSU_VERSION_OVERRIDE` 固定版本号，避免因仓库内无 `.git` 元数据导致版本回退。

## 构建

GitHub Actions → `Build MoonWake Kernel` → Run workflow：

| 参数 | 值 |
|---|---|
| 批量构建 | `config_type=release`，`config_file` 留空 |
| C2G 构建 | `config_type=release`，`config_file=compression-c2g.json` |
| C2H 构建 | `config_type=release`，`config_file=compression-c2h.json` |
| C2H 三方案 | `config_type=release`，`config_file=compression-c2h-plans.json`（V1/V2/V3 并行，合并发布） |
| `full_dump` | `false` |
| `send_to_telegram` | `false` |

批量构建时，workflow matrix 会并行构建 `configs/release/` 下所有未标记 `deprecated` 的配置（`max-parallel: 10`），所有变体产物合并发布到**同一个 Release**。

产物：

- `MoonWake_2.7.0_C2_ak3.zip`：AnyKernel3 刷机包（workflow artifact）
- `verify-<kernel>-<run_number>`：每个变体独立的验证产物，包含该变体的 config、System.map 和 ksu 元数据

每次成功构建只创建一个 GitHub Release，tag 形如 `mwk-2.7.0-<run_number>`，包含该次构建所有变体的 ak3 zip、`System.map`、config 和 ksu 元数据。

超频说明：

- GPU OC 在 `C2B/C2D/C2F` 中把 OPP 顶部两档替换为 1.1GHz/1.05GHz，使用 `POSDIV_POWER_2`，只改三套 GPU segment 表的顶部两档，不改变表长度、PTPOD 索引或 aging table。
- CPU 2.8GHz 变体把 A78 顶档 2600MHz 替换为 2800MHz；3.0GHz 变体把顶部两档替换为 3000/2800MHz，保持频率表降序，避免报告原方案中 2600→2800→3000 的升序问题。
- C2G 使用完整插档：GPU 由 38 档扩展为 40 档（插入 1.1GHz/1.05GHz，并同步 PTPOD 与 aging table）；CPU 曾尝试扩为 18 档，但 MCUPM/PVT 只有 16 个 OPP 槽位，索引 16/17 会被截断成 1，导致待机锁在第二高频，因此 C2H 起改回 16 档。
- C2H 的 CPU 16 档：A78 为 3.0/2.8/2.6/2.4/2.0/1.9/1.8/1.66/1.54/1.43/1.3/1.14/1.04/0.91/0.74/0.65GHz，A55 为 2.2/2.1/2.0/1.903/1.8/1.6/1.407/1.31/1.26/1.15/1.053/0.98/0.9/0.74/0.65/0.5GHz；同时把 `FY_6833Tbl` 的 MCUPM 表改成同一组频率和电压，超频才会真正生效。
- 电压使用最终降压表（GPU 1.1GHz@818.75mV、CPU 2.8GHz@1031.25mV、3.0GHz@1087.5mV、A55 2.2GHz@1025mV）。
- CPU 3.0GHz 电压余量很小，建议先把 Big Cores 的 `eem_offset` 归零验证，再考虑长期使用；所有 OC 变体都应保留原 boot 镜像以便回滚。

## 刷入后检查

```bash
adb shell su -c 'uname -r'
# 4.19.325-MoonWake-2.7.0-C2

adb shell su -c 'cat /sys/block/zram0/comp_algorithm'
adb shell su -c 'cat /sys/fs/f2fs/dm-10/features'
```

F2FS 需要 `/data` 超级块带有 `compression` 特性才会实际压缩。

## 与上游关系

基于 MoonWake 上游 `73774526`（2.7.0）。

相对上游的内核改动：

- 修改 26 个文件
- 新增 96 个内核文件（不含 vendored KernelSU-Next / AnyKernel3）
- 删除 0 个文件

主要内容为 F2FS/ZRAM 压缩、SUS_MOUNT、MGLRU 修复、HybridMount、UFS blk-mq 和游戏/日志配置。

## License

本项目原创部分采用 `GPL-2.0-only`；Linux 内核部分仍为 `GPL-2.0 WITH Linux-syscall-note`。

本仓库是组合分发，包含多个第三方组件，各自保留其许可证。完整说明：

- `LICENSE`：本项目原创部分与 GPL-2.0 全文
- `THIRD_PARTY_NOTICES.md`：第三方组件来源与授权状态
- `LICENSING.md`：GPL 合规方式与尚未解决的授权问题

注意：SuSFS 上游声明为 GPL-3.0，与 GPL-2.0-only 内核的组合问题尚未完全澄清；华为/OPPO 压缩算法代码的授权状态也未明确。详见 `LICENSING.md`。

## Credits

- DXRN-MoonWake
- KernelSU-Next
- simonpunk/susfs4ksu
- sidex15/ksu_module_susfs
- DXRN-MoonWake/AnyKernel3
- AOSP clang r563880
