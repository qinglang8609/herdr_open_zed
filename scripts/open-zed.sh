#!/bin/sh
# 在 Zed 中打开当前工作区目录。目录来自 herdr 注入的 action 上下文。
set -e

json_str() {
  printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//" \
    | sed 's/"$//'
}

dir=$(json_str workspace_cwd)
[ -n "$dir" ] || dir=$(json_str focused_pane_cwd)

if [ -z "$dir" ] || [ ! -d "$dir" ]; then
  echo "open-with-zed: 找不到工作区目录 (workspace_cwd='$dir')" >&2
  exit 1
fi

# ZED_CLI 可覆盖；macOS 上 zed 命令默认不在 PATH，走应用包内的 cli。
if [ -n "${ZED_CLI:-}" ]; then
  zed_bin=$ZED_CLI
elif [ -x /Applications/Zed.app/Contents/MacOS/cli ]; then
  zed_bin=/Applications/Zed.app/Contents/MacOS/cli
else
  zed_bin=$(command -v zed || true)
fi

if [ -z "$zed_bin" ]; then
  echo "open-with-zed: 找不到 Zed，请安装 Zed 或设置 ZED_CLI" >&2
  exit 1
fi

# action 命令是同步阻塞的，放后台避免 herdr 等 Zed 退出。
nohup "$zed_bin" "$dir" >/dev/null 2>&1 &
exit 0
