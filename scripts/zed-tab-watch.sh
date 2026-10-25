#!/bin/bash
# 跑在 Mac 上：只盯「当前聚焦的那个会话」，发现名为 ZED 的 tab 就打开 Zed 并关掉它。
#
# 顺序：先查本机（毫秒级），本机没命中才查远程机器（每次约 2 秒）。
# 远程机器只在真正需要时才碰，避免每轮都白跑几次 SSH。
#
# 用法：zed-tab-watch.sh [间隔秒，默认 5]
set -uo pipefail

interval="${1:-5}"

. "$(dirname "$0")/common.sh"

herdr_bin="${HERDR_BIN_PATH:-herdr}"
zed_bin=$(zed_editor)

# 本机没有 Zed 编辑器，监控没有意义，直接不进循环
if [ -z "$zed_bin" ]; then
  echo "本机无 Zed 编辑器，不启动监控" >&2
  exit 0
fi

log() { echo "[$(date '+%H:%M:%S')] $*"; }
log "Zed 已确认: ${zed_bin}，开始监控"

# 取聚焦 pane 的 workspace_id 与 cwd
pane_info() {
  "$@" pane current 2>/dev/null | python3 -c "
import json,sys
try:
    p=json.load(sys.stdin)['result']['pane']
    print(p.get('workspace_id',''), p.get('cwd',''))
except Exception:
    pass
" 2>/dev/null
}

# 在指定工作区里找 label=ZED 的 tab，输出 tab_id
find_zed_tab() {
  ws=$1; shift
  "$@" tab list 2>/dev/null | python3 -c "
import json,sys
try:
    for t in json.load(sys.stdin)['result']['tabs']:
        if t.get('label')=='ZED' and t.get('workspace_id')==sys.argv[1]:
            print(t['tab_id']); break
except Exception:
    pass
" "$ws" 2>/dev/null
}

# 处理一台目标：命中就开 Zed 并关 tab。返回 0 表示处理掉了。
handle() {
  prefix=$1      # 空串=本机；否则是机器标签
  info=$(pane_info "$herdr_bin" ${prefix:+--machine "$prefix"})
  [ -n "$info" ] || return 1
  set -- $info
  ws=$1; cwd=$2

  hit=$(find_zed_tab "$ws" "$herdr_bin" ${prefix:+--machine "$prefix"})
  [ -n "$hit" ] || return 1

  if [ -n "$prefix" ]; then
    log "远程 $prefix 的 ZED tab $hit (目录 $cwd)"
    "$zed_bin" "ssh://${prefix}${cwd}" >/dev/null 2>&1 &
  else
    log "本机 ZED tab $hit (目录 $cwd)"
    "$zed_bin" "$cwd" >/dev/null 2>&1 &
  fi
  sleep 1
  "$herdr_bin" ${prefix:+--machine "$prefix"} tab close "$hit" >/dev/null 2>&1 \
    && log "已关闭 $hit"
  return 0
}

while true; do
  # 本机先查：本地调用几毫秒，绝大多数情况到这里就结束了
  if ! handle ""; then
    for m in $("$herdr_bin" machine list --json 2>/dev/null | python3 -c "
import json,sys
try:
    for m in json.load(sys.stdin):
        if m.get('enabled', True): print(m['label'])
except Exception:
    pass
" 2>/dev/null || true); do
      handle "$m" && break
    done
  fi

  sleep "$interval"
done
