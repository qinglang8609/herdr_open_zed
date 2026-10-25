#!/bin/sh
# 键按下后：
#   - 本机有 Zed 编辑器 → 直接打开，不建 tab
#   - 本机没有 Zed → 建一个名为 ZED 的 tab 当信号，等本地 Mac 来取
#
# 注意：不能用 `command -v zed` 判断。Linux 上 /usr/sbin/zed 是 Zenoss 组件，
# 不是 Zed 编辑器，会误判。
set -e

herdr="${HERDR_BIN_PATH:-herdr}"

json_str() {
  printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//" \
    | sed 's/"$//'
}

dir=$(json_str workspace_cwd)
[ -n "$dir" ] || dir=$(json_str focused_pane_cwd)

# 认编辑器只看这三个：显式配置、macOS 应用包、PATH 上的 zed（排除系统同名程序）
if [ -n "${ZED_CLI:-}" ]; then
  zed_bin=$ZED_CLI
elif [ -x /Applications/Zed.app/Contents/MacOS/cli ]; then
  zed_bin=/Applications/Zed.app/Contents/MacOS/cli
else
  zed_bin=""
fi

if [ -n "$zed_bin" ] && [ -n "$dir" ] && [ -d "$dir" ]; then
  nohup "$zed_bin" "$dir" >/dev/null 2>&1 &
  echo "已用本机 Zed 打开: $dir"
  exit 0
fi

# 本机没有 Zed：留一个 ZED tab 给本地 Mac
"$herdr" tab create --label "ZED" --focus ${dir:+--cwd "$dir"} >/dev/null
echo "本机无 Zed，已留 ZED tab 等本地处理: ${dir:-当前目录}"
