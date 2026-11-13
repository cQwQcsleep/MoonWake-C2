# Third-Party Notices

本仓库是 Linux 内核衍生作品与多个第三方组件的组合分发，**不是单一许可证作品**。

本文记录各组件的来源、版权与许可证状态。工程记录，不构成法律意见。

## 1. Linux kernel

- 来源：Linux 4.19 / MoonWake 上游内核
- 许可证：`GPL-2.0 WITH Linux-syscall-note`
- 仓库内依据：`COPYING`、`LICENSES/`
- 状态：明确

## 2. MoonWake upstream

- 来源：`DXRN-MoonWake/moonwake_kernel_xiaomi_ruby`
- 基线：`73774526`（MoonWake 2.7.0）
- 许可证：GPL-2.0（Linux 内核部分）
- 状态：明确

## 3. SuSFS

- 来源：`simonpunk/susfs4ksu`
- 上游根目录 `LICENSE`：**GPL-3.0**
- 本仓库使用位置：`fs/susfs.c`、`include/linux/susfs.h`、`include/linux/susfs_def.h`、`fs/proc_namespace.c`、`fs/namei.c`、`fs/readdir.c` 等
- 状态：**未完全明确**
- 说明：GPL-3.0 与 Linux 内核的 `GPL-2.0-only` 直接组合存在兼容性问题；需要 SuSFS 作者对内核补丁部分作出明确授权，或将其作为独立组件处理。

## 4. KernelSU-Next

- 来源：`cQwQcsleep/KernelSU-Next`
- 分支：`legacy-susfs-v2-susmount`
- 固定提交：`75143d56970811a9bb7a008dec40832155000c17`
- `kernel/LICENSE`：GPL-2.0（内核内组件）
- 根目录 `LICENSE`：GPL-3.0（管理器/用户态）
- 状态：内核组件明确；管理器作为独立用户态程序分发
- 本仓库位置：`kernelsu/KernelSU-Next/`

## 5. AnyKernel3

- 来源：`DXRN-MoonWake/AnyKernel3`
- 许可证：BSD-3-Clause
- 附带二进制：Magisk `magiskboot` / `magiskpolicy` 为 GPL-3.0+
- 本仓库位置：`anykernel3/`
- 状态：明确

## 6. HybridMount / NoMount

- 来源：fork 自 `maxsteeel/nomount`
- 许可证：GPL-2.0
- 本仓库位置：`fs/hybridmount/`
- 状态：明确
- 参见：`fs/hybridmount/LICENSE`、`fs/hybridmount/PROVENANCE`

## 7. 压缩算法代码

### 7.1 Zstdn

- 来源：Zstandard / Linux `lib/zstd` 系代码
- 文件头：`Copyright (c) Yann Collet, Facebook, Inc.`
- 许可证：**BSD-3-Clause OR GPL-2.0**（可任选其一）
- 本仓库位置：`lib/zstdn/`
- 状态：明确；本仓库选择 GPL-2.0 兼容路径

### 7.2 LZ4K / LZ4KD（华为）

- 来源：华为厂商内核代码
- 文件头：`Copyright (c) Huawei Technologies Co., Ltd.`
- 未找到明确的 SPDX 标识或独立 LICENSE 文件
- 本仓库位置：`lib/lz4k/`、`lib/lz4kd/`、`crypto/lz4k.c`、`crypto/lz4kd.c`、`include/linux/lz4k.h`、`include/linux/lz4kd.h`
- 状态：**来源已记录，授权状态未确认**
- 说明：不能仅凭“来自厂商内核”推定其许可证；在取得明确授权前，不应宣称这些文件为 GPL-2.0。

### 7.3 LZ4K_OPLUS（OPPO 系）

- 来源：OPPO 系厂商内核代码
- 文件未找到明确的 SPDX 标识或独立 LICENSE 文件
- 本仓库位置：`lib/lz4k_oplus/`
- 状态：**来源已记录，授权状态未确认**
- 说明：同上，不应在授权澄清前宣称其为 GPL-2.0。

### 7.4 F2FS compression wrappers

- 来源：本项目编写
- 许可证：`SPDX-License-Identifier: GPL-2.0`
- 本仓库位置：`fs/f2fs/compress_lz4kd.c`、`fs/f2fs/compress_oplus.c`、`fs/f2fs/compress_zstdn.c`、`fs/f2fs/compress_ops.h`
- 状态：明确

## 8. 其他

- `ci/`、`configs/`、README、构建脚本：本项目原创，GPL-2.0-only
- 如有遗漏或错误，请通过 Issue 指出；如你是权利持有人并认为某项 inclusion 未经授权，请联系维护者，我们会移除或替换相关代码。
