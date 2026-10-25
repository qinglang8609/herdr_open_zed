# herdr 打开 Zed / TTT

[herdr](https://herdr.dev) 插件：把当前工作区交给 Zed 打开，或新开一个 tab 跑 ttt。支持本地和远程机器。

## 快捷键

| 按键 | 作用 |
|---|---|
| `prefix+shift+z` | 在 Zed 中打开当前工作区 |
| `prefix+shift+t` | 新建名为 `TTT` 的 tab，并在其中运行 `ttt` |

`prefix` 默认是 `ctrl+b`。

## 三个 action

| action | 跑在哪 | 干什么 |
|---|---|---|
| `open` | macOS | 用本机 Zed 打开工作区（只在本机按有用） |
| `zed-tab` | 任意 | 本机有 Zed 就直接开；没有就建一个 `ZED` tab 当信号 |
| `ttt` | 任意 | 新建 `TTT` tab 跑 ttt |

## 远程机器上怎么工作

herdr 远程连接时，快捷键命令**在远端服务器执行**，本地客户端收不到。远端往往没装 Zed，所以靠一个 tab 当信号传递：

```
远端按 prefix+shift+z
   ↓ zed-tab 检查本机有没有 Zed
   ├─ 有 → 直接打开，结束
   └─ 没有 → 建一个名为 ZED 的 tab（看得见的反馈）
        ↓
本地 Mac 上的监控进程每 3 秒查一次聚焦会话
   ↓ 发现 ZED tab → 判断本地还是远程 → 打开 Zed
   ↓ 关掉那个 ZED tab
```

`ZED` tab 本身就是「按键已收到」的反馈：出现说明信号发出去了，消失说明本地处理完了。

### 监控进程随 herdr 启动

manifest 里的 `[[startup]]` 钩子会在 herdr 启动时调用 `start-watch.sh`：

- 本机没有 Zed → 不启动监控
- 已经在跑（pid 文件里那台还活着）→ 不重复启动
- 日志超过 1MB → 轮转成 `.log.1`

日志在 `$HERDR_PLUGIN_STATE_DIR/zed-tab-watch.log`。

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
command = "fanchao.open-with-zed.zed-tab"
description = "在 Zed 中打开当前工作区"

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

**快捷键必须绑 `type = "plugin_action"`，不能用 `type = "shell"`。** 只有 plugin_action 才有 `HERDR_PLUGIN_CONTEXT_JSON`，shell 模式下这个变量是空的，脚本拿不到工作区路径，表现为按了没反应。

## 依赖

| 依赖 | 用途 | 检查 |
|---|---|---|
| herdr ≥ 0.9.5 | 必需 | `herdr --version` |
| Zed | 打开编辑器 | 装在 `/Applications/Zed.app` 即可，不需要 `zed` 在 PATH |
| ttt | `prefix+shift+t` | `command -v ttt` |
| python3 | 解析 herdr 的 JSON 输出 | 系统自带 |

Zed 通过应用包内的 `Contents/MacOS/cli` 启动，也可以用 `ZED_CLI` 环境变量指定别的路径。

**不要用 `command -v zed` 判断有没有 Zed。** Linux 上 `/usr/sbin/zed` 是 Zenoss 监控组件，会误判。

## 为什么没有右键菜单

herdr 的插件 action **不会**出现在工作区右键菜单里。核对过 `herdr --default-config`：挂自定义命令只有 `[[keys.command]]` 一种配置，没有任何「往右键菜单加插件项」的机制。`contexts = ["workspace"]` 只是声明 action 在哪些上下文可被调用，不是菜单注册。

这是 herdr 的已知限制，上游 [Discussion #3935](https://github.com/herdrdev/herdr/discussions/3935) 有同样诉求。

详细调研与实测记录见 [docs/RESEARCH.md](docs/RESEARCH.md)。
