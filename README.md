# herdr 打开 Zed / TTT

[herdr](https://herdr.dev) 插件，两个快捷键：把当前工作区交给 Zed 打开，或新开一个 tab 跑 ttt。

## 快捷键

| 按键 | 作用 | 平台 |
|---|---|---|
| `prefix+shift+z` | 用 Zed 打开当前工作区的目录 | 仅 macOS |
| `prefix+shift+t` | 新建名为 `TTT` 的 tab，并在其中运行 `ttt` | Linux / macOS |

`prefix` 默认是 `ctrl+b`。

Linux 上没有 `Open with Zed` 这个 action（manifest 里限定在 macOS），只绑 `prefix+shift+t` 即可。

## 安装

```bash
git clone https://github.com/qinglang8609/herdr_open_zed.git ~/Code/herdr_open_zed
herdr plugin link ~/Code/herdr_open_zed
```

插件只注册 action，**不会自动生成快捷键**。把下面这段加进 `~/.config/herdr/config.toml`：

```toml
[keys]
# rename_tab 默认占用 prefix+shift+t，腾给「新开 TTT tab」
rename_tab = ""

[[keys.command]]
key = "prefix+shift+z"
type = "plugin_action"
command = "fanchao.open-with-zed.open"
description = "用 Zed 打开当前工作区"

[[keys.command]]
key = "prefix+shift+t"
type = "plugin_action"
command = "fanchao.open-with-zed.ttt"
description = "新开 TTT tab"
```

然后让配置生效：

```bash
herdr config check
herdr server reload-config
```

`config check` 输出 `config: ok`、`reload-config` 返回 `status: applied` 即成功。

注意 `[[keys.command]]` 必须写在 `[experimental]` 等配置段之前，否则会被归进错误的段。

## 依赖

| 依赖 | 用途 | 检查 |
|---|---|---|
| herdr ≥ 0.9.5 | 必需 | `herdr --version` |
| Zed | `prefix+shift+z`（仅 macOS） | 装在 `/Applications/Zed.app` 即可，不需要 `zed` 在 PATH |
| ttt | `prefix+shift+t` | `command -v ttt` |

Zed 通过应用包内的 `Contents/MacOS/cli` 启动，也可以用 `ZED_CLI` 环境变量指定别的路径。

## 为什么没有右键菜单

herdr 的插件 action **不会**出现在工作区右键菜单里。核对过 `herdr --default-config`：挂自定义命令只有 `[[keys.command]]` 一种配置，没有任何「往右键菜单加插件项」的机制。`contexts = ["workspace"]` 只是声明 action 在哪些上下文可被调用，不是菜单注册。

详细调研与实测记录见 [docs/RESEARCH.md](docs/RESEARCH.md)。
