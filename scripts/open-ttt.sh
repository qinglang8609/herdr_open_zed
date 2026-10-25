#!/bin/sh
# 新建一个名为 TTT 的 tab，并在其中启动 ttt。
set -e

. "$(dirname "$0")/common.sh"

herdr="${HERDR_BIN_PATH:-herdr}"
dir=$(json_str workspace_cwd)

if ! command -v ttt >/dev/null 2>&1; then
  echo "open-ttt: 找不到 ttt 命令" >&2
  exit 1
fi

# tab create 没有 --command，只能先建 tab 拿到 root pane，再往里 run
created=$("$herdr" tab create --label "TTT" --focus ${dir:+--cwd "$dir"})
# 返回里有多个 pane_id 字段，必须明确取 root_pane 那个
pane_id=$(printf '%s' "$created" | python3 -c "
import json,sys
try:
    print(json.load(sys.stdin)['result']['root_pane']['pane_id'])
except Exception:
    pass
" 2>/dev/null)

if [ -z "$pane_id" ]; then
  echo "open-ttt: 解析新 tab 的 pane_id 失败: $created" >&2
  exit 1
fi

exec "$herdr" pane run "$pane_id" ttt
