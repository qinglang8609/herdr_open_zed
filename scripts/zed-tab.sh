#!/bin/sh
# 键按下后：
#   - 本机有 Zed 编辑器 → 直接打开，不建 tab
#   - 本机没有 Zed → 建一个名为 ZED 的 tab 当信号，等本地 Mac 来取
set -e

. "$(dirname "$0")/common.sh"

herdr="${HERDR_BIN_PATH:-herdr}"

dir=$(json_str workspace_cwd)
[ -n "$dir" ] || dir=$(json_str focused_pane_cwd)

zed_bin=$(zed_editor)

if [ -n "$zed_bin" ] && [ -n "$dir" ] && [ -d "$dir" ]; then
  nohup "$zed_bin" "$dir" >/dev/null 2>&1 &
  echo "已用本机 Zed 打开: $dir"
  exit 0
fi

# 本机没有 Zed：留一个 ZED tab 给本地 Mac
"$herdr" tab create --label "ZED" --focus ${dir:+--cwd "$dir"} >/dev/null
echo "本机无 Zed，已留 ZED tab 等本地处理: ${dir:-当前目录}"
