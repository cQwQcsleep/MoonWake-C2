# ZRAM MULTI_COMP 与自动重压缩

状态：**C2PN 已启用**（`feature/zram-multicomp` 已合入 `c2`），C2 与 C2P 编译时关闭，行为不变。
未在真机验证。

## 能力

| 能力 | 说明 |
|---|---|
| 每页算法记录 | 存在 `table[index].flags` 的 bit30–31，不额外占表内存 |
| 主算法 | 新写入固定用 `comp_algorithm`，C2P/C2PN 内核默认 `lz4kd` |
| 次算法 | 默认自动使用 `zstdn`；需要改则在 `disksize` 之前写 `recomp_algorithm`，写 `none` 可关闭 |
| 手动重压缩 | `echo 1 > /sys/block/zramX/recompress` |
| 自动重压缩 | 内核 delayed_work 按压力与冷热自动执行，默认开启 |
| 读路径 | 按每页记录的算法解压，切换算法不会读错历史页 |

## 自动策略（C2PN）

思路对齐厂商的 hybrid-swap 守护线程（华为 HyperHold / OPPO HybridSWAP / vivo ESwap）：

| 阶段 | 动作 |
|---|---|
| 空闲标记 | 分批把已分配槽位标 `ZRAM_IDLE`，被读写的页会自动清标记 |
| 重压缩 | 只处理仍带 `ZRAM_IDLE` 且算法为主算法的页 |
| 回写（可选） | 内存极紧且配置了 `backing_dev` 时，先做 idle 回写，再重压缩 |

触发与节流：

| 参数 | 值 |
|---|---|
| 开始工作的 MemAvailable 水位 | < 15% |
| 触发 idle 回写的临界水位 | < 6%（且已有 backing_dev） |
| CPU 负载门控 | `avenrun[0]` 高于在线核数时跳过 |
| 单次 CPU 时间片 | 8ms |
| 每次续排间隔 | 50ms |
| 一轮结束冷却 | 10 分钟 |
| refault 回退 | 重压页被读回比例 > 10% 时冷却 30 分钟 |
| 空 swap 轮询 | 30 秒 |

内存充足时 worker 每 30 秒只做一次判断，几乎零开销。

## 内核默认值（仅 C2P/C2PN）

- `default_compressor = "lz4kd"`：即使用户态脚本缺失也不会退回 `lzo`
- `vm_swappiness = 100`：与 Android + zram 的常规取值一致

两者都由 `CONFIG_MWK_PERF_PROFILE` 控制，C2 保持 `lzo` / `60`。

## 使用

默认零配置：内核在 `disksize` 时自动创建 `lz4kd`（主）+ `zstdn`（次）。

想换次算法时才需要手动写，且必须在 `disksize` 之前：

```bash
echo lz4k_oplus > /sys/block/zram0/recomp_algorithm   # 可选
echo none       > /sys/block/zram0/recomp_algorithm   # 关闭自动重压缩
```

之后不用管，内存紧张时内核自己重压缩。可观测：

```bash
cat /sys/block/zram0/mm_stat
dmesg | grep "recompressed"      # 每轮结束打印一次统计
echo 0 > /sys/block/zram0/auto_recompress   # 需要时可关闭
```

脚本方式由 `userspace/zram.sh` 负责建 backing 文件、设算法与触发一次手动重压缩：

```bash
ZRAM_RECOMP_ALGO=zstdn ZRAM_WB_IDLE=0 ./zram.sh
```

`ZRAM_WB_IDLE=1` 会在开机时做一次 idle 回写（会立即搬页，默认关闭）。

## 安全设计

- 跳过已回写（`ZRAM_WB`）、同值页（`ZRAM_SAME`）、大页（`ZRAM_HUGE`）与已重压页
- 锁内只做快照，压缩与分配在锁外，提交前校验 `handle` 与 `obj_size` 未变
- 只有新长度更小才替换，并同步修正 `compr_data_size`
- 失败路径统一释放新句柄
- `zram_free_page` 的 `WARN_ON_ONCE` 掩码已包含算法位

## 编译验证

| 配置 | 结果 |
|---|---|
| `MULTI_COMP=y AUTO_RECOMP=y WRITEBACK=y`（C2PN） | `zram_drv.o` 通过 |
| `MULTI_COMP=n`（C2/C2P） | `zram_drv.o` 通过 |
| `AUTO_RECOMP=y WRITEBACK=n` | 代码已加 `#ifdef` 保护，未单独构建 |

## 已知局限

- 冷热判断依赖 `ZRAM_IDLE`，是“自上次标记后被访问过”的近似，不是精确 LRU
- 首次标记 pass 要遍历全表（786k 槽位），已拆成 8192/次分片
- 与 userspace 的 `idle`/`writeback` 共用标记位，同时使用时要串行
- 未做真机验证；swap 路径出错会直接卡死或损坏数据
