# MoonWake ZRAM 模块

KernelSU 模块，用来配置 MoonWake C2PN 内核的 ZRAM 多算法与自动重压缩。

## 依赖

- MoonWake C2PN 内核（`CONFIG_ZRAM_MULTI_COMP=y`、`CONFIG_ZRAM_AUTO_RECOMP=y`）
- KernelSU / KernelSU-Next 管理器（用于 WebUI）

C2 / C2P 内核没有这些节点，模块会提示不支持。

## 结构

```
moonwake-zram/
├── module.prop
├── customize.sh          # 安装：生成默认配置、设置权限
├── post-fs-data.sh       # 开机早期应用配置
├── service.sh            # 开机完成后同步开关，必要时触发一次
├── bin/mwk-zram          # 状态读取 / 配置写入 / 动作触发
├── webui/                # 前端源码（Vue 3 + miuix-vue）
└── webroot/              # 构建产物，KSU 管理器直接加载
```

## 配置

`/data/adb/moonwake-zram.conf`：

```
disksize_pct=50
algo=lz4kd
recomp_algo=zstdn
auto_recomp=1
writeback=0
backing_mb=2048
wb_limit_mb=1024
```

- `recomp_algo=none` 关闭次算法与自动重压缩
- `writeback=1` 会创建 `/data/adb/zram_backing.img` 并挂到 loop，注意闪存写入

## 命令行

```bash
BIN=/data/adb/modules/moonwake-zram/bin/mwk-zram
$BIN status            # JSON 状态
$BIN apply             # 应用配置（可能 reset zram）
$BIN runtime           # 只同步运行时开关，不 reset
$BIN recompress        # 手动触发一轮
$BIN writeback         # 标记空闲并回写
$BIN set algo zstdn    # 改单个键
$BIN logs              # 最近 zram 内核日志
```

## 构建 WebUI

```bash
cd webui
pnpm install
pnpm build      # 输出到 ../webroot
```

## 打包

```bash
cd module/moonwake-zram
zip -r ../moonwake-zram-v1.0.1.zip . -x "webui/*"
```

`webui/` 只是源码，不必打进模块包。

## 界面来源

WebUI 的页面外壳、MD3 主题变量、Snackbar 组件和 Material Symbols 字体取自
[Tricky Addon - Update Target List](https://github.com/KOWX712/Tricky-Addon-Update-Target-List)
（Apache-2.0），组件使用 [@material/web](https://github.com/material-components/material-web)
（Apache-2.0）。许可证副本见 `LICENSE-APACHE-2.0`。

## 说明

- 4.19 的 `comp_algorithm` 只能在未初始化时修改，改算法会重建 zram，当前 swap 内容会丢
- 开机只同步 `auto_recompress` 等运行时开关，不会 reset 已初始化的 zram
- 自动重压缩由内核执行，模块只负责配置和展示
- 模块尚未在真机验证
