#!/bin/sh
# herdr [[startup]] 钩子：本机有 Zed 就把监控拉起来，然后立刻退出。
#
# herdr 的 startup hook 是一次性命令，不能常驻，所以这里只负责把
# 监控进程脱离出去。
#
# 防重靠 pid 文件：写入监控进程的 pid，下次启动前检查它还活着没。
# 不用 pgrep -f（会匹配到自己这条 shell），也不用 mkdir 锁（清理时机难掌握）。
set -e

. "$(dirname "$0")/common.sh"

zed_bin=$(zed_editor)
[ -n "$zed_bin" ] || exit 0

state="${HERDR_PLUGIN_STATE_DIR:-/tmp}"
mkdir -p "$state" 2>/dev/null || true
pidfile="$state/zed-tab-watch.pid"
log="$state/zed-tab-watch.log"

# 已在跑就不重复启动
if [ -f "$pidfile" ]; then
  old=$(cat "$pidfile" 2>/dev/null || echo "")
  if [ -n "$old" ] && kill -0 "$old" 2>/dev/null; then
    exit 0
  fi
  rm -f "$pidfile"
fi

# 日志超过 1MB 就轮转一份旧的，避免无限增长
if [ -f "$log" ] && [ "$(wc -c < "$log")" -gt 1048576 ]; then
  mv -f "$log" "$log.1" 2>/dev/null || true
fi

script_dir=$(cd "$(dirname "$0")" && pwd)

# nohup 让监控脱离 herdr 进程组；$! 就是它的 pid
nohup "$script_dir/zed-tab-watch.sh" 3 > "$log" 2>&1 &
echo $! > "$pidfile"
exit 0
