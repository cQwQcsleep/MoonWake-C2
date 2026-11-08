# LZ4 内核镜像实验

当前产物是 `Image.gz-dtb`（gzip）。AOSP 的启动时间文档建议用 LZ4：解压更快、体积略大。

CI 的打包步骤里已经有 `.lz4` 分支（`output_image` 以 `.lz4` 结尾时走 `lz4 -l`），所以实验只需要改配置，不需要改代码。

## 怎么做

1. 复制一份配置，只改 `output_image`：

```json
"output_image": "Image.lz4-dtb"
```

2. 单独构建（不要覆盖 C2/C2P）
3. 刷入前确认 bootloader 支持 LZ4 内核

## 风险

- **MTK bootloader 是否支持 LZ4 必须实机验证**，不支持会直接开不了机
- 需要保留 gzip 版本作为回退，并确保能进 fastboot / recovery
- 4.19 的 `lz4` 解压器用的是 `lib/lz4`，本树已编译（`CONFIG_HAVE_KERNEL_LZ4`），但 boot 镜像格式由 bootloader 决定，与内核配置无关

## 测量

```bash
adb shell logcat -b events | grep -E 'boot_progress|sf_stop_bootanim'
```

- 对比 gzip 与 lz4 的 `boot_progress_start` 到 `sf_stop_bootanim`
- 至少 3 次冷启动取中位数
- 同时确认 `dmesg` 无解压相关错误

## 结论

属于低收益实验项：只在启动时间上有差别，日常运行无影响。建议放在 C2P 之后，单独验证。
