#!/bin/sh
# herdr [[startup]] 钩子：本机有 Zed 就把监控拉起来，然后立刻退出。
#
# herdr 的 startup hook 是一次性命令，不能常驻，所以这里只负责把
# 监控进程脱离出去。已经在跑就不重复启动。
set -e

zed_bin="${ZED_CLI:-/Applications/Zed.app/Contents/MacOS/cli}"
[ -x "$zed_bin" ] || exit 0

# 已在运行就什么都不做
if pgrep -f "zed-tab-watch.sh" >/dev/null 2>&1; then
  exit 0
fi

script_dir=$(cd "$(dirname "$0")" && pwd)
log="${HERDR_PLUGIN_STATE_DIR:-/tmp}/zed-tab-watch.log"

# setsid/nohup 让它脱离 herdr 进程组，herdr 退出不会带走它
nohup "$script_dir/zed-tab-watch.sh" 3 > "$log" 2>&1 &
exit 0
