# Licensing and GPL Compliance

本文说明 MoonWake C2 的授权结构与 GPL 合规方式。工程记录，不构成法律意见。

## 1. 本项目原创部分

MoonWake C2 的原创修改、构建脚本、配置、README 采用：

```
SPDX-License-Identifier: GPL-2.0-only
```

`LICENSE` 中的 GPL-2.0 全文适用于这些原创部分。

## 2. Linux 内核部分

Linux 内核代码仍按上游声明分发：

```
GPL-2.0 WITH Linux-syscall-note
```

见仓库根目录 `COPYING` 与 `LICENSES/`。

## 3. GPL 合规方式

- 完整对应源码在本仓库公开
- 构建脚本、配置、所需补丁均在仓库内
- 发布二进制（AnyKernel3 zip）时，对应源码可通过同一仓库获取
- 不附加 GPL 之外的限制
- 保留上游版权与许可证声明

## 4. 组合分发说明

本仓库包含多个第三方组件，各自保留自己的许可证：

- SuSFS：GPL-3.0（上游声明）
- KernelSU-Next 管理器：GPL-3.0
- AnyKernel3 / Magisk 二进制：BSD-3-Clause / GPL-3.0+
- HybridMount / NoMount：GPL-2.0
- Zstdn：BSD-3-Clause OR GPL-2.0
- LZ4K / LZ4KD（华为）：授权未明确
- LZ4K_OPLUS（OPPO 系）：授权未明确

因此 **本仓库不是单一 GPL-2.0 作品**。

## 5. 尚未解决的问题

### 5.1 SuSFS 与 GPL-2.0-only 内核

SuSFS 上游根 `LICENSE` 是 GPL-3.0；Linux 内核是 GPL-2.0-only。二者直接组合存在授权兼容性问题。

在 SuSFS 作者对内核补丁部分给出明确 GPL-2.0 授权之前：

- 不宣称整个仓库为“纯 GPL-2.0”
- 再分发二进制前应自行评估授权
- 如需彻底澄清，可选择移除 SuSFS 或替换为 GPL-2.0 兼容实现

### 5.2 华为 / OPPO 压缩代码

`lib/lz4k/`、`lib/lz4kd/`、`lib/lz4k_oplus/` 及相关 crypto 文件带有厂商版权信息，但没有明确的 SPDX 或独立 LICENSE。

在取得明确授权前：

- 记录来源，不推定许可证
- 不宣称这些文件为 GPL-2.0
- 如权利持有人提出异议，维护者将移除或替换

## 6. 联系

如发现授权信息错误、遗漏，或你是权利持有人并认为某项 inclusion 未经授权，请通过仓库 Issue 联系维护者。
