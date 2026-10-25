#!/bin/sh
# herdr [[startup]] 钩子：本机有 Zed 就把监控拉起来，然后立刻退出。
#
# herdr 的 startup hook 是一次性命令，不能常驻，所以这里只负责把
# 监控进程脱离出去。
#
# 防重不用 pgrep：pgrep -f 会匹配到执行它自己的那条 shell 命令，
# 且 hook 短时间连续触发时两个实例可能都查到「没在跑」。
# 改用 mkdir 原子锁：只有一个能建成目录。
set -e

zed_bin="${ZED_CLI:-/Applications/Zed.app/Contents/MacOS/cli}"
[ -x "$zed_bin" ] || exit 0

state="${HERDR_PLUGIN_STATE_DIR:-/tmp}"
lock="$state/zed-tab-watch.lock"

if ! mkdir "$lock" 2>/dev/null; then
  # 已存在：持有者活着就退出，是残留就清掉重来
  owner=$(cat "$lock/pid" 2>/dev/null || echo "")
  if [ -n "$owner" ] && kill -0 "$owner" 2>/dev/null; then
    exit 0
  fi
  rm -rf "$lock" 2>/dev/null || true
  mkdir "$lock" 2>/dev/null || exit 0
fi

touch "$lock/pid" 2>/dev/null || true

script_dir=$(cd "$(dirname "$0")" && pwd)

# 监控自己负责删锁：把它作为参数传进去，进程退出时 trap 清理
nohup "$script_dir/zed-tab-watch.sh" 3 "$lock" \
  > "$state/zed-tab-watch.log" 2>&1 &
echo $! > "$lock/pid"
exit 0
