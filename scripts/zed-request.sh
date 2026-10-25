#!/bin/sh
# 跑在 FNOS 上：把当前工作区路径写进请求文件，等 Mac 侧来取。
# FNOS 无法反向调用 Mac 的 Zed，只能留个文件。
#
# 第一行是时间戳：同一个目录反复按也要能重复触发，Mac 侧靠它判断是新请求。
set -e

json_str() {
  printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//" \
    | sed 's/"$//'
}
dir=$(json_str workspace_cwd)

if [ -z "$dir" ]; then
  echo "zed-request: 没拿到 workspace_cwd" >&2
  exit 1
fi

state="${HERDR_PLUGIN_STATE_DIR:-$HOME/.local/state/herdr/plugins/fanchao.open-with-zed}"
mkdir -p "$state"
{
  date +%s%N
  printf '%s\n' "$dir"
} > "$state/zed-request"
echo "已请求打开: $dir"
