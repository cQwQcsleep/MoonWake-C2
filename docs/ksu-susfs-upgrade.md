# KernelSU-Next / SuSFS 升级评估

## 现状

| 项 | 值 |
|---|---|
| vendored 位置 | `kernelsu/KernelSU-Next/` |
| 分支 | `legacy-susfs-v2-susmount` |
| 分支头 | `75143d56`（2026-11-01） |
| SuSFS | v2.3.0（`include/linux/susfs.h`） |
| 上游最新 Release | KernelSU-Next `v3.4.2`（2026-10-13） |
| ABI 对照 | `CMD_SUSFS_ADD_SUS_MAP 0x60020` 与上游 `kernel/susfs/susfs_abi.h` 的 v2.3.0 一致 |

## 已确认的问题：死符号

`susfs.config` 里有 6 个符号在本仓库的 Kconfig/源码中**完全不存在**，写了也不会生效：

```
AUTO_ADD_SUS_KSU_DEFAULT_MOUNT
AUTO_ADD_SUS_BIND_MOUNT
AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT
SUS_OVERLAYFS
HAS_MAGIC_MOUNT
SUS_SU
```

影响：

- 依赖“自动隐藏 bind mount”的行为不会发生，需要手工 `sus_path` / mount 规则
- 若使用 overlayfs 类模块，`SUS_OVERLAYFS` 的隐藏不会生效
- `SUS_SU` 在非 GKI 上游已弃用，保持 n 是正确的

## 升级步骤（建议单独分支）

1. 建分支 `next-susfs-upgrade`，不直接改 `c2`
2. 拉上游对应 legacy/4.19 分支，先只做**只读 diff**：
   - `kernel/Kconfig` 的符号表
   - `kernel/supercall/` 的命令分发
   - `include/linux/susfs.h` / `susfs_def.h` 的结构体与 cmd 号
3. 先补 Kconfig 符号，再决定是否启用；每启用一个都要有对应验证项
4. 保持 supercall ABI 不变（`0x55550`/`0x60020` 这一套），否则 SuSFS 用户态工具与 Zygisk Next 会失配
5. 逐项回归：
   - `uname -r`、`/proc/version`
   - `ksu_susfs show version` / `show enabled_features`
   - `sus_path` / `sus_mount` / `try_umount`
   - `sus_map`（Zygisk Next「隐藏」内存方式）
   - `open_redirect`
   - 模块挂载与卸载

## 风险

- SuSFS v2.3.0 的 ABI 与当前工具链匹配；升级到更新 ABI（`0x55555` 系列）会同时要求用户态工具升级，**不能只升级内核**
- KSU-Next v3.4.x 的 `kernel/susfs/` 是 LKM 形态，本仓库是内置形态，不能直接照搬
- 升级后需要重新验证 hook 方式（manual hook）是否仍被支持

## 结论

- 不建议现在直接合并上游：ABI 稳定性优先，当前 v2.3.0 与主流工具匹配
- 建议先做两件事：删掉 6 个死符号（或明确标注“未实现”），以及评估是否真的需要 `AUTO_ADD_*`；如果需要，只能升级或改 mount namespace 方案
