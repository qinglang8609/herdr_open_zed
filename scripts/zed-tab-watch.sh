#!/bin/bash
# 跑在 Mac 上：轮询远端 herdr，发现名为 ZED 的 tab 就打开 Zed 并关掉它。
#
# 三步：
#   1. 找当前聚焦的会话（pane current 带 tab_id / workspace_id）
#   2. 该会话的 tabs 里有没有 label = ZED
#   3. 有就判断本地还是远程，打开 Zed，再关掉那个 tab
#
# 用法：zed-tab-watch.sh [机器标签，默认 FNOS] [间隔秒，默认 5]
set -uo pipefail

machine="${1:-FNOS}"
interval="${2:-5}"
herdr_bin="${HERDR_BIN_PATH:-herdr}"
zed_bin="${ZED_CLI:-/Applications/Zed.app/Contents/MacOS/cli}"

[ -x "$zed_bin" ] || { echo "找不到 Zed: $zed_bin" >&2; exit 1; }

log() { echo "[$(date '+%H:%M:%S')] $*"; }

while true; do
  # 1. 当前聚焦会话的 tab 与目录
  cur=$("$herdr_bin" --machine "$machine" pane current 2>/dev/null | python3 -c "
import json,sys
try:
    p=json.load(sys.stdin)['result']['pane']
    print(p.get('tab_id',''), p.get('cwd',''), p.get('workspace_id',''))
except Exception:
    pass
" 2>/dev/null)

  [ -n "$cur" ] || { sleep "$interval"; continue; }
  set -- $cur
  cur_tab=$1; cur_cwd=$2; cur_ws=$3

  # 2. 该会话的 tabs 里找 ZED
  hit=$("$herdr_bin" --machine "$machine" tab list 2>/dev/null | python3 -c "
import json,sys
try:
    for t in json.load(sys.stdin)['result']['tabs']:
        if t.get('label')=='ZED' and t.get('workspace_id')=='$cur_ws':
            print(t['tab_id']); break
except Exception:
    pass
" 2>/dev/null)

  if [ -n "$hit" ]; then
    log "发现 ZED tab: $hit (目录 $cur_cwd)"
    "$zed_bin" "ssh://${machine}${cur_cwd}" >/dev/null 2>&1 &
    sleep 1
    "$herdr_bin" --machine "$machine" tab close "$hit" >/dev/null 2>&1 \
      && log "已关闭 $hit"
  fi

  sleep "$interval"
done
