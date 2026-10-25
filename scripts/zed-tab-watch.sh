#!/bin/bash
# 跑在 Mac 上：只盯「当前聚焦的那个会话」，发现名为 ZED 的 tab 就打开 Zed 并关掉它。
#
#   1. 取当前聚焦会话（pane current → tab_id / cwd / workspace_id）
#   2. 只看这个会话的 tabs 里有没有 label = ZED
#   3. 有就打开 Zed（本地或远程），再关掉那个 tab
#
# 不遍历所有机器、不看非聚焦的会话。
# 用法：zed-tab-watch.sh [间隔秒，默认 5]
set -uo pipefail

interval="${1:-5}"
herdr_bin="${HERDR_BIN_PATH:-herdr}"
zed_bin="${ZED_CLI:-/Applications/Zed.app/Contents/MacOS/cli}"

# 本机没有 Zed 编辑器，监控没有意义，直接不进循环
if [ ! -x "$zed_bin" ]; then
  echo "本机无 Zed 编辑器（$zed_bin 不存在），不启动监控" >&2
  exit 0
fi

log() { echo "[$(date '+%H:%M:%S')] $*"; }
log "Zed 已确认: ${zed_bin}，开始监控"

# 解析 pane current → "tab_id workspace_id cwd"
pane_info() {
  "$@" pane current 2>/dev/null | python3 -c "
import json,sys
try:
    p=json.load(sys.stdin)['result']['pane']
    print(p.get('tab_id',''), p.get('workspace_id',''), p.get('cwd',''))
except Exception:
    pass
" 2>/dev/null
}

while true; do
  found=""

  # 本机先看；本机没有 ZED tab 再看各台远程机器
  targets=""
  for label in $("$herdr_bin" machine list --json 2>/dev/null | python3 -c "
import json,sys
try:
    for m in json.load(sys.stdin):
        if m.get('enabled', True): print(m['label'])
except Exception:
    pass
" 2>/dev/null || true); do
    targets="$targets $label"
  done

  # 本机（无 --machine）
  info=$(pane_info "$herdr_bin")
  if [ -n "$info" ]; then
    set -- $info
    tab_id=$1; ws=$2; cwd=$3
    hit=$("$herdr_bin" tab list 2>/dev/null | python3 -c "
import json,sys
try:
    for t in json.load(sys.stdin)['result']['tabs']:
        if t.get('label')=='ZED' and t.get('workspace_id')=='$ws':
            print(t['tab_id']); break
except Exception:
    pass
" 2>/dev/null)
    if [ -n "$hit" ]; then
      log "本机 ZED tab $hit (目录 $cwd)"
      "$zed_bin" "$cwd" >/dev/null 2>&1 &
      sleep 1
      "$herdr_bin" tab close "$hit" >/dev/null 2>&1 && log "已关闭 $hit"
      found=1
    fi
  fi

  # 远程机器
  if [ -z "$found" ]; then
    for m in $targets; do
      info=$(pane_info "$herdr_bin" --machine "$m")
      [ -n "$info" ] || continue
      set -- $info
      tab_id=$1; ws=$2; cwd=$3
      hit=$("$herdr_bin" --machine "$m" tab list 2>/dev/null | python3 -c "
import json,sys
try:
    for t in json.load(sys.stdin)['result']['tabs']:
        if t.get('label')=='ZED' and t.get('workspace_id')=='$ws':
            print(t['tab_id']); break
except Exception:
    pass
" 2>/dev/null)
      if [ -n "$hit" ]; then
        log "远程 $m 的 ZED tab $hit (目录 $cwd)"
        "$zed_bin" "ssh://${m}${cwd}" >/dev/null 2>&1 &
        sleep 1
        "$herdr_bin" --machine "$m" tab close "$hit" >/dev/null 2>&1 && log "已关闭 $hit"
        found=1
        break
      fi
    done
  fi

  sleep "$interval"
done
