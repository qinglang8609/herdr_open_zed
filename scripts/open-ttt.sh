#!/bin/sh
# 新建一个名为 TTT 的 tab，并在其中启动 ttt。
set -e

herdr="${HERDR_BIN_PATH:-herdr}"

# 目标目录沿用当前工作区
json_str() {
  printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//" \
    | sed 's/"$//'
}
dir=$(json_str workspace_cwd)

if ! command -v ttt >/dev/null 2>&1; then
  echo "open-ttt: 找不到 ttt 命令" >&2
  exit 1
fi

# tab create 没有 --command，只能先建 tab 拿到 root pane，再往里 run
created=$("$herdr" tab create --label "TTT" --focus ${dir:+--cwd "$dir"})
pane_id=$(printf '%s' "$created" \
  | grep -o '"pane_id":"[^"]*"' | head -1 | sed 's/.*:"//; s/"$//')

if [ -z "$pane_id" ]; then
  echo "open-ttt: 解析新 tab 的 pane_id 失败: $created" >&2
  exit 1
fi

exec "$herdr" pane run "$pane_id" ttt
