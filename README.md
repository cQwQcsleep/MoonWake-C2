# MoonWake C2

Xiaomi ruby（MT6877）的 Linux 4.19.325 内核，包含 KernelSU-Next + SuSFS、F2FS/ZRAM 压缩，可直接在本仓库构建。

## 版本

| 项 | 值 |
|---|---|
| 设备 | Xiaomi ruby |
| 内核 | Linux 4.19.325，non-GKI |
| Root | KernelSU-Next + SuSFS v2.3.0 |
| 版本名 | `4.19.325-MoonWake-2.7.0-C2` |
| Release | `mwk-2.7.0-c2` |
| 构建配置 | `configs/release/compression-c2.json` |

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

## 构建

GitHub Actions → `Build MoonWake Kernel` → Run workflow：

| 参数 | 值 |
|---|---|
| `config_type` | `release` |
| `config_file` | `compression-c2.json` |
| `full_dump` | `false` |
| `send_to_telegram` | `false` |

产物：

```text
MoonWake_2.7.0_C2_ak3.zip
MoonWake_2.7.0_C2_config.txt
MoonWake_2.7.0_C2_System.map
MoonWake_2.7.0_C2_ksu.txt
```

## 刷入后检查

```bash
adb shell su -c 'uname -r'
# 4.19.325-MoonWake-2.7.0-C2

adb shell su -c 'cat /sys/block/zram0/comp_algorithm'
adb shell su -c 'cat /sys/fs/f2fs/dm-10/features'
```

F2FS 需要 `/data` 超级块带有 `compression` 特性才会实际压缩。

## KPM 版本（C2K）

`configs/release/compression-c2k.json` 在 C2 的基础上，构建后用 KernelPatch 0.13.9 给内核 Image 打补丁，用于加载 `.kpm` 模块。

- 保留 KernelSU-Next + SuSFS
- kptools / kpimg 已放在 `kernelpatch/`，构建时直接使用
- superkey：`MoonWake-C2K`（公开固定值，可用 `kptools -r` 重置）
- 产物：`MoonWake_2.7.0_C2K_ak3.zip`，`uname -r` 为 `4.19.325-MoonWake-2.7.0-C2K`

KernelPatch 自带一套 SU，与 KernelSU 同时存在可能冲突，需实机验证。

## 与上游关系

基于 MoonWake 上游 `73774526`（2.7.0）。

相对上游的内核改动：

- 修改 26 个文件
- 新增 93 个文件
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
