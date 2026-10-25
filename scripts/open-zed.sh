#!/bin/sh
# 按快捷键，用本机 Zed 打开当前工作区目录。
set -e

. "$(dirname "$0")/common.sh"

zed_bin=$(zed_editor)
[ -n "$zed_bin" ] || { echo "open-zed: 找不到 Zed" >&2; exit 1; }

dir=$(json_str workspace_cwd)
[ -n "$dir" ] || dir=$(json_str focused_pane_cwd)

if [ -z "$dir" ] || [ ! -d "$dir" ]; then
  echo "open-zed: 目录不存在 ('$dir')" >&2
  exit 1
fi

# action 命令同步阻塞，放后台避免 herdr 等 Zed 退出。
nohup "$zed_bin" "$dir" >/dev/null 2>&1 &
exit 0
