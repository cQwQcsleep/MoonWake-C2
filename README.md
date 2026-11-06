# MoonWake C2 · 单仓库内核构建与发布

面向 **Xiaomi ruby（Redmi Note 12 Pro 5G / Dimensity 1080 / MT6877）** 的 Linux 4.19.325 非 GKI 内核。

本仓库同时承担 **源码、CI 构建、AnyKernel3、KernelSU-Next 与 Release 发布**，不再依赖旧的 CI 仓库或内核仓库即可构建 C2。

- 上游基线：`DXRN-MoonWake/moonwake_kernel_xiaomi_ruby@moon`，提交 `73774526`（MoonWake 2.7.0）
- 当前发布：`mwk-2.7.0-c2`
- 可见内核名：`4.19.325-MoonWake-2.7.0-C2`
- 构建配置：`configs/release/compression-c2.json`

---

## 版本信息

| 项 | 值 |
|---|---|
| 设备 | Xiaomi ruby |
| SoC | MediaTek MT6877 / Dimensity 1080 |
| 内核 | Linux 4.19.325，non-GKI |
| Root | KernelSU-Next `legacy-susfs-v2-susmount` |
| SuSFS | v2.3.0（SUS_MOUNT / TRY_UMOUNT / SUS_PATH / SUS_MAP / SUS_KSTAT / SPOOF 等） |
| 工具链 | AOSP clang r563880 + LTO + CFI |
| `uname -r` | `4.19.325-MoonWake-2.7.0-C2` |
| 发布 Tag | `mwk-2.7.0-c2` |

---

## 功能

### 压缩

- **F2FS 文件压缩**
  - 算法：LZO / LZ4 / ZSTD / LZO-RLE / LZ4K / LZ4KD / LZ4K_OPLUS / ZSTDN
  - `F2FS_FS_COMPRESSION_ALL=y`：新建普通文件自动带压缩标志
  - 透明解压，应用无感
- **ZRAM 多后端**
  - `lzo / lzo-rle / lz4 / lz4hc / lz4k / lz4k_oplus / lz4kd / zstd / zstdn`
  - `ZRAM_WRITEBACK=y`（默认未配置 backing device，需要用户态自行启用）

### Root / 隐藏

- KernelSU-Next + SuSFS v2.3.0
- SUS_MOUNT / TRY_UMOUNT
- SUS_PATH / SUS_MAP / SUS_KSTAT
- OPEN_REDIRECT / SPOOF_UNAME / SPOOF_CMDLINE
- HIDE_KSU_SUSFS_SYMBOLS

### 性能 / 平台

- FPSGO V3、TouchBoost
- MGLRU + 4.19 修复
- UFS 强制 blk-mq
- HybridMount
- HZ=300、SHADOW_CALL_STACK

### 日志

对齐 HyperMoon 的日志配置：

```
DEBUG_INFO
DYNAMIC_DEBUG
MTK_MET / MTK_MET_CORE / MTK_MET_PLF
MTPROF
PM_DEBUG / PM_SLEEP_DEBUG
SCHEDSTATS
SND_DEBUG / SND_DEBUG_VERBOSE / SND_PCM_XRUN_DEBUG
```

> `DEBUG_INFO` 与 `MTK_MET/MTPROF` 会增加构建体积与少量运行时开销。

---

## 与上游的关系

C2 是 MoonWake 上游的 **downstream fork**，基线提交与上游 `moon` 完全一致：

```
73774526  improve: README.md file  (2026-10-15, 2.7.0)
```

截至本 README 更新时，上游 `moon` 没有新提交。

内核代码差异：

| 项 | 数量 |
|---|---|
| 修改文件 | 26 |
| 新增文件 | 93 |
| 删除文件 | 0 |
| 合计 | 119 |

主要改动：

| 类别 | 内容 | 作用 |
|---|---|---|
| F2FS 压缩 | `compress_lz4kd.c`、`compress_oplus.c`、`compress_ops.h`、`compress_zstdn.c` + 6 个修改 | 文件级压缩，省存储 |
| ZRAM 压缩 | `lib/zstdn`、`lib/lz4kd`、`lib/lz4k`、`lib/lz4k_oplus`、`crypto/lz4k*`、`zcomp.c` | 更多压缩算法 |
| MGLRU | `mm/vmscan.c`、`mm/workingset.c`、`mmzone.h`、`memcontrol.h` | 平滑内存回收 |
| SuSFS | `fs/susfs.c`、`fs/proc_namespace.c`、`susfs.h`、`susfs.config` | SUS_MOUNT 挂载隐藏 |
| HybridMount | `fs/hybridmount/` | 模块挂载方案 |
| UFS | `drivers/scsi/ufs/ufshcd.c` | 强制 blk-mq |
| 配置 | `compression.config`、`gaming_balanced.config`、`hybridmount.config`、`logging-hm.config`、`zram_compress.config` | 模块化 profile |

C2 **不包含** PathMask / KPROBES。PathMask 实验版本只存在于旧内核仓库的 C3P 分支，不属于 C2。

---

## 仓库结构

```text
.
├── .github/workflows/build.yml      # 构建 / 验证
├── anykernel3/                      # vendored AnyKernel3
├── kernelsu/KernelSU-Next/          # vendored KernelSU-Next
├── configs/release/compression-c2.json
├── ci/
│   ├── ksun-moonwake.sh             # 本地 KernelSU-Next 集成
│   ├── version-mwk.sh               # uname 版本命名
│   └── README.md
├── arch/arm64/configs/              # 内核 defconfig 与 vendor fragments
├── fs/ mm/ drivers/ ...             # Linux 4.19.325 源码
└── README.md
```

构建时仍会下载 **clang r563880** 编译器二进制（AOSP 工具链），它不是项目源码依赖；AnyKernel3 与 KernelSU-Next 已全部放进本仓库。

---

## 构建

在 GitHub Actions 中手动触发：

```text
Build MoonWake Kernel -> Run workflow
```

参数：

| 参数 | 值 |
|---|---|
| `config_type` | `release` |
| `config_file` | `compression-c2.json` |
| `full_dump` | `false`（需要完整 dump 时设 true） |
| `send_to_telegram` | `false` |

产物：

```text
MoonWake_2.7.0_C2_ak3.zip
MoonWake_2.7.0_C2_config.txt
MoonWake_2.7.0_C2_System.map
MoonWake_2.7.0_C2_ksu.txt
```

验证内容：

- `.config` 关键项
- SuSFS 符号
- KSU-Next commit
- `uname` 版本命名
- `System.map`

---

## 刷入

1. 备份 boot / 确认设备为 ruby
2. 通过 OrangeFox、KernelSU 管理器或 fastboot 刷入 `MoonWake_2.7.0_C2_ak3.zip`
3. 重启
4. 验证：

```bash
adb shell su -c 'uname -r'
# 4.19.325-MoonWake-2.7.0-C2

adb shell su -c 'cat /sys/block/zram0/comp_algorithm'
adb shell su -c 'cat /sys/fs/f2fs/dm-10/features'
```

F2FS 压缩是否生效，需要 `/data` 的 F2FS 超级块本身带 `compression` 特性；没有该特性时不会压缩。

---

## 版本命名

```text
uname -r          4.19.325-MoonWake-2.7.0-C2
AK3 包            MoonWake_2.7.0_C2_ak3.zip
Release Tag       mwk-2.7.0-c2
```

后续变体沿用：

```text
C2V  -> 4.19.325-MoonWake-2.7.0-C2V
C2K  -> 4.19.325-MoonWake-2.7.0-C2K
```

---

## 已知限制

- Linux 4.19 已 EOL，上游没有新的 stable/security 发布；安全维护依赖 Android ACK 与 MoonWake 上游。
- F2FS `COMPRESSION_ALL` 会压缩所有新建普通文件，写入有 CPU 开销；加密目录/特殊文件的兼容性需实测。
- ZRAM 新增算法未做长期数据完整性验证；不同算法 CPU/压缩比差异明显。
- `ZRAM_WRITEBACK=y` 只是能力，默认未配置 backing device。
- `DEBUG_INFO` 会增大构建产物，`MTK_MET/MTPROF` 有少量运行时开销。
- UFS blk-mq 属平台行为改变，极端负载/部分固件下可能需要回退。
- 不包含 PathMask / KPROBES；C3P 实验分支不在本仓库发布。

---

## 维护策略

C2 定位为**稳定基线**：

- 不再持续加新功能
- 只在以下情况重建：
  - MoonWake 上游出现安全/稳定提交
  - KSU-Next / SuSFS 出现需要内核侧改动的更新
  - Android 4.19 ACK 出现安全补丁
  - HyperOS 底包/DTB 变化
- 每次重建执行最小回归：
  - 开机、`uname`
  - ZRAM 算法可用
  - F2FS compression feature + 新文件压缩标志
  - KSU/SuSFS 正常
  - dmesg 无 panic

当前上游检查结果：MoonWake `moon` 无新提交，KSU-Next 与 SuSFS 无 4.19 相关功能更新，因此 C2 暂不需要重建。

---

## Credits

- [DXRN-MoonWake](https://github.com/DXRN-MoonWake) — MoonWake 上游内核
- [KernelSU-Next](https://github.com/KernelSU-Next) / XDL-MoonWake — KernelSU-Next
- [simonpunk/susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu) — SuSFS
- [sidex15/ksu_module_susfs](https://github.com/sidex15/ksu_module_susfs) — SuSFS 用户态模块
- [DXRN-MoonWake/AnyKernel3](https://github.com/DXRN-MoonWake/AnyKernel3) — AnyKernel3
- AOSP clang r563880 — 工具链

---

## 链接

- Releases: https://github.com/cQwQcsleep/MoonWake-C2/releases
- Actions: https://github.com/cQwQcsleep/MoonWake-C2/actions
- 当前 C2: https://github.com/cQwQcsleep/MoonWake-C2/releases/tag/mwk-2.7.0-c2
