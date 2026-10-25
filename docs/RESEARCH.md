# herdr 插件调研：工作区右键「Open with Zed」

结论：**可行**。herdr 插件声明 `contexts = ["workspace"]` 的 action 就会出现在工作区上；action 命令里拿得到工作区根目录，调 `zed <目录>` 即可打开。

## 一、需求拆解

| 要求 | 是否满足 | 靠什么 |
|---|---|---|
| 工作区上出现菜单项 | 可行（有旁证，见风险） | manifest `[[actions]]` + `contexts = ["workspace"]` |
| 点击后执行自定义程序 | 可行 | action 的 `command` argv |
| 拿到当前工作区路径 | 可行，已实测 | `HERDR_PLUGIN_CONTEXT_JSON` 的 `workspace_cwd` |
| 打开系统 Zed | 可行，已实测 | `/Applications/Zed.app/Contents/MacOS/cli <目录>` |

## 二、验证过的证据

本机 `herdr 0.9.5`，以下全部实跑。

### 1. action 上下文里有工作区根目录

临时建一个 `probe.ctx` 插件，action 打印环境变量，`herdr plugin action invoke probe.ctx.dump` 输出：

```
HERDR_PLUGIN_CONTEXT_JSON={"workspace_id":"w1T","workspace_label":"herdr_open_zed",
"workspace_cwd":"/Users/fanchao/Code/herdr_open_zed","tab_id":"w1T:t1",
"focused_pane_id":"w1T:p1","focused_pane_cwd":"/Users/fanchao/Code/herdr_open_zed",...}
```

- `workspace_cwd` = 工作区根目录，**正是要打开的目录**。
- `focused_pane_cwd` = 当前聚焦 pane 的目录，可能比工作区更深（实测 `w14` 工作区里 pane 停在 `~/Code/faxuehui/官网/service`）。
- 另有 `HERDR_WORKSPACE_ID` 等独立环境变量，`HERDR_PLUGIN_CONTEXT_JSON` 是完整来源。

### 2. `workspace get` 拿不到路径，不能替代上下文

```
herdr workspace get w1T
{"workspace":{"active_tab_id":"w1T:t1","agent_count":...,"label":"herdr_open_zed","workspace_id":"w1T"}}
```

只有 worktree 类型的工作区才带 `worktree.checkout_path`。普通工作区没有路径字段，所以路径必须从 `workspace_cwd`（或 `herdr pane list` 的 `cwd`）取。

### 3. Zed 命令行可用，但不在 PATH

- `which zed` → 找不到。
- `/Applications/Zed.app/Contents/MacOS/cli` 存在，`cli --help` 明确支持 `zed path-to-your-project`。
- 实跑 `cli /Users/fanchao/Code/herdr_open_zed`，退出码 0，Zed 进程起来了。

所以插件内部不能假设 `zed` 在 PATH，要走应用包内的 `cli`，并留可配置入口。

### 4. 已有同类插件可作范本

本机装了 `ttt.editor`（`eugenioenko/ttt`），manifest 就是：

```toml
[[actions]]
id = "open"
title = "Open TTT"
contexts = ["workspace"]
command = ["sh", "scripts/open-worktree.sh"]
```

它的脚本从 `HERDR_PLUGIN_CONTEXT_JSON` 里依次取 `checkout_path` → `focused_pane_cwd` → `workspace_cwd`，然后打开编辑器。这是「工作区右键开编辑器」的现成实现，结构直接照搬即可。

## 三、实现方案

### 插件结构

```
herdr_open_zed/
├── herdr-plugin.toml
└── scripts/open-zed.sh
```

### manifest 要点

- `platforms = ["macos"]`：Zed 应用包路径是 macOS 专有，先只声明 macOS。
- `contexts = ["workspace"]`：决定 action 出现在工作区上。
- `command = ["sh", "scripts/open-zed.sh"]`：argv 数组，herdr 不走 shell。

### 脚本要点

1. 从 `HERDR_PLUGIN_CONTEXT_JSON` 取 `workspace_cwd`；取不到再退到 `focused_pane_cwd`。
2. 目录不存在就报错退出，不要静默打开插件目录。
3. 找 Zed：先试配置的环境变量，再试 `/Applications/Zed.app/Contents/MacOS/cli`，最后试 PATH 里的 `zed`。
4. 后台启动，不阻塞 herdr：action 命令是同步跑的，等 Zed 退出会一直挂着。
5. 脚本要在多路径下都稳定，`set -e` + 明确 exit code。

### 命令组装示意

```
cli 路径 = ZED_CLI 环境变量 或 /Applications/Zed.app/Contents/MacOS/cli 或 PATH 中的 zed
执行 cli <workspace_cwd> &
```

## 四、风险与未验证项

| 项 | 状态 | 说明 |
|---|---|---|
| 右键菜单里出现插件 action | **未直接验证** | 文档只说「herdr 右击有上下文菜单」，没说菜单是否列出插件 action。旁证：`ttt.editor` 声明 `contexts=["workspace"]` 且被本机正常使用；`plugin_action` 是 config 里的一等类型。仍需装好后实测一次。 |
| action 是否在子进程里同步阻塞 | 未验证 | 需实测确认打开 Zed 后菜单立刻关闭、不卡住 herdr。 |
| Windows / Linux 支持 | 未做 | Zed 应用包路径为 macOS 形态，暂不声明。 |
| `min_herdr_version` 取多少 | 待定 | 需确认 `workspace_cwd` 字段从哪个版本开始有；本机 0.9.5 有。 |

## 五、触发方式：快捷键（右键菜单不可行）

**右键菜单走不通。** `herdr --default-config` 全文核对过：挂自定义命令只有 `[[keys.command]]` 一种配置，没有任何「往右键菜单加插件项」的配置项。所以插件 action `contexts = ["workspace"]` 不会出现在工作区右键菜单里，这一点已由用户实测确认。

改用快捷键绑定同一个 action：

```toml
[[keys.command]]
key = "prefix+shift+z"
type = "plugin_action"
command = "fanchao.open-with-zed.open"
description = "用 Zed 打开当前工作区"
```

不占用 `prefix+z`：那是 Herdr 默认的「缩放窗格」（zoom），保留原样。

实测：`herdr config check` 通过，`herdr server reload-config` applied 无诊断；切换聚焦工作区后触发，Zed 打开的目录也跟着变（`herdr_open_zed` → `herdr_pendant`），证明取的是当前工作区而非固定路径。

## 六、下一步

1. 写 manifest 与脚本。
2. `herdr plugin link <目录>`。
3. 在左侧工作区右键确认菜单项出现（这是唯一还没实证的环节）。
4. 点击确认 Zed 打开的是工作区根目录，不是插件目录、不是深一级的 pane 目录。

## 七、参考资料

- 插件文档：https://herdr.dev/docs/plugins/
- CLI 参考：https://herdr.dev/docs/cli-reference/
- Socket API：https://herdr.dev/docs/socket-api/
- 范本插件：`eugenioenko/ttt` 的 `herdr-plugin` 子目录
