# MoonWake C2

Xiaomi ruby（MT6877）的 Linux 4.19.325 内核，包含 KernelSU-Next + SuSFS、F2FS/ZRAM 压缩，可直接在本仓库构建。

## 版本

| 项 | 值 |
|---|---|
| 设备 | Xiaomi ruby |
| 内核 | Linux 4.19.325，non-GKI |
| Root | KernelSU-Next + SuSFS v2.3.0 |
| KernelSU 版本 | `33226`（`legacy-susfs-v2-susmount@75143d5`） |
| 版本名 | `4.19.325-MoonWake-2.7.0-C2` 至 `-C2F` |
| Release 标识 | `mwk-2.7.0-<run_number>`（每次构建一个 Release） |
| 构建配置 | 批量：`configs/release/compression-c2*.json`<br>C2F：`configs/special/compression-c2f.json` |

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
| C2F | 1100MHz | 2800/3000MHz | 独立 special 构建，包含报告中的完整 GPU+CPU 调频组合 |

C2A–C2E 作为多版本批次一次性并行构建，合并发布到一个 Release；C2F 单独构建、单独发布。

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
| C2F 独立构建 | `config_type=special`，`config_file=compression-c2f.json` |
| `full_dump` | `false` |
| `send_to_telegram` | `false` |

批量构建时，workflow matrix 会并行构建 `configs/release/` 下的 C2、C2A–C2E（`max-parallel: 10`），所有变体产物合并发布到**同一个 Release**。

产物：

- `MoonWake_2.7.0_C2_ak3.zip`：AnyKernel3 刷机包（workflow artifact）
- `verify-<kernel>-<run_number>`：每个变体独立的验证产物，包含该变体的 config、System.map 和 ksu 元数据

每次成功构建只创建一个 GitHub Release，tag 形如 `mwk-2.7.0-<run_number>`，包含该次构建所有变体的 ak3 zip、`System.map`、config 和 ksu 元数据。

超频说明：

- GPU OC 在 `C2B/C2D/C2F` 中把 OPP 顶部两档替换为 1.1GHz/1.05GHz，使用 `POSDIV_POWER_2`，只改三套 GPU segment 表的顶部两档，不改变表长度、PTPOD 索引或 aging table。
- CPU 2.8GHz 变体把 A78 顶档 2600MHz 替换为 2800MHz；3.0GHz 变体把顶部两档替换为 3000/2800MHz，保持频率表降序，避免报告原方案中 2600→2800→3000 的升序问题。
- C2F 是独立 special 构建，组合 GPU 1.1GHz 与 CPU 2.8/3.0GHz，并使用报告中的目标电压（GPU 1.1GHz@881.25mV、CPU 2.8GHz@1025mV、3.0GHz@1125mV）。
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
