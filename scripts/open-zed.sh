#!/bin/sh
# 按快捷键，用本机 Zed 打开当前工作区目录。
set -e

json_str() {
  printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//" \
    | sed 's/"$//'
}

if [ -n "${ZED_CLI:-}" ]; then
  zed_bin=$ZED_CLI
elif [ -x /Applications/Zed.app/Contents/MacOS/cli ]; then
  zed_bin=/Applications/Zed.app/Contents/MacOS/cli
else
  zed_bin=$(command -v zed || true)
fi
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
