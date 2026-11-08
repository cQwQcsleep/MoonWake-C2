# 热管理与 GPU 调参

默认策略比较激进：`TRIP_1 = 65°C` 就开始用 ATM 压 CPU/GPU 功率预算，目标 Tj 75°C。对续航友好，对持续性能有限制。

## 先看现状

```bash
adb shell dumpsys thermalservice
adb shell su -c 'for z in /sys/class/thermal/thermal_zone*; do echo "$z $(cat $z/type) $(cat $z/temp)"; done'
adb shell su -c 'cat /sys/class/thermal/thermal_zone*/trip_point_*_temp'
```

## CPU trip

```bash
# 每次只提 3°C，改完观察皮肤温度与充电场景
adb shell su -c 'echo 68000 > /sys/class/thermal/thermal_zoneX/trip_point_1_temp'
```

- `TRIP_0 = 113500` 是硬件保护点，不要动
- 只有 `trip_mask` 标记为可写的 trip 才能改，写入返回 permission denied 说明需要改 dts/驱动
- 需要 `CONFIG_THERMAL_WRITABLE_TRIPS=y`（本树已开）

## GPU / GED

节点在 `/sys/kernel/ged/hal/`：

```bash
adb shell su -c 'cat /sys/kernel/ged/hal/gpu_utilization'
adb shell su -c 'cat /sys/kernel/ged/hal/current_freqency'
adb shell su -c 'cat /sys/kernel/ged/hal/dvfs_margin_value'
adb shell su -c 'cat /sys/kernel/ged/hal/custom_boost_gpu_freq'
adb shell su -c 'cat /sys/kernel/ged/hal/custom_upbound_gpu_freq'
adb shell su -c 'cat /sys/kernel/ged/hal/gpu_boost_level'
```

方向：

| 目标 | 手段 | 风险 |
|---|---|---|
| 帧率更稳 | 提高 boost 频率/等级，或降低 `dvfs_margin_value` | 功耗与发热上升 |
| 日常省电 | 提高 `dvfs_margin_value`，限制 `custom_upbound_gpu_freq` | 高负载掉帧 |
| 排查频点 | `opp_logs=1` + dmesg / `ged_kpi` | 日志开销 |

注意：GED 参数由 MTK 用户态（`libged` / `perfmgr`）与内核共同使用，只改内核节点可能被用户态覆盖。先确认 vendor 侧是否有 GED 配置。

## 测量

- 起始条件一致：静置到电池 < 30°C、固定亮度与刷新率、飞行模式
- 指标：同帧率下的平均功率（`current_now × voltage_now`，30–60s 平均）、最高 Tj、表面温度、throttle 时长
- 至少 3 次取中位数；温度必须作为协变量记录

## 不建议

- 改 GPU OPP 表（超频/降压）：MTK 的 EEM 会做电压校准，风险高收益不确定
- 为了跑分长期关掉 thermal：会触到硬件保护点，损伤电池与屏幕
