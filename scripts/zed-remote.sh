#!/bin/sh
# 用本地 Zed 远程打开本机 herdr 工作区（Zed SSH Remoting）。
# 远端不需要装 Zed，本地 Zed 会自动在远端拉一个 headless server。
set -e

json_str() {
  printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//" \
    | sed 's/"$//'
}
dir=$(json_str workspace_cwd)

if [ -z "$dir" ] || [ ! -d "$dir" ]; then
  echo "zed-remote: 找不到工作区目录 (workspace_cwd='$dir')" >&2
  exit 1
fi

# ZED_REMOTE_HOST 必填，指向发起方（本地机器）能 SSH 到的主机名或别名。
if [ -z "${ZED_REMOTE_HOST:-}" ]; then
  echo "zed-remote: 需要设置 ZED_REMOTE_HOST，例如 FNOS 或 user@host" >&2
  exit 1
fi

if [ -n "${ZED_CLI:-}" ]; then
  zed_bin=$ZED_CLI
elif [ -x /Applications/Zed.app/Contents/MacOS/cli ]; then
  zed_bin=/Applications/Zed.app/Contents/MacOS/cli
else
  zed_bin=$(command -v zed || true)
fi

if [ -z "$zed_bin" ]; then
  echo "zed-remote: 找不到 Zed，请设置 ZED_CLI" >&2
  exit 1
fi

# ssh://host/绝对路径 —— 远程连接跑在本地 Zed 上，放后台避免阻塞 herdr。
nohup "$zed_bin" "ssh://${ZED_REMOTE_HOST}${dir}" >/dev/null 2>&1 &
exit 0
