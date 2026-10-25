#!/bin/bash
# 跑在 Mac 上：每 3 秒去 FNOS 看一次请求文件，有新路径就用本地 Zed 远程打开。
#
#   zz-zed-watch.sh            # 默认看 FNOS
#   zz-zed-watch.sh zj-shop    # 换机器
#
# 后台常驻：nohup zz-zed-watch.sh >/tmp/zed-watch.log 2>&1 &
set -uo pipefail

machine="${1:-FNOS}"
zed_bin="${ZED_CLI:-/Applications/Zed.app/Contents/MacOS/cli}"
state_dir="$HOME/.local/state/zz-zed-watch"
mkdir -p "$state_dir"
seen="$state_dir/last-request.$machine"

[ -x "$zed_bin" ] || { echo "找不到 Zed: $zed_bin" >&2; exit 1; }

while true; do
  req=$(timeout 20 ssh -o BatchMode=yes -o ConnectTimeout=8 "$machine" \
        'cat ~/.local/state/herdr/plugins/fanchao.open-with-zed/zed-request 2>/dev/null' 2>/dev/null)

  # 每次请求都带时间戳，同一个目录也能重复触发；
  # 记录请求行的完整内容，避免一次按键触发两次。
  if [ -n "$req" ] && [ "$req" != "$(cat "$seen" 2>/dev/null)" ]; then
    printf '%s\n' "$req" > "$seen"
    path=$(printf '%s\n' "$req" | tail -1)
    echo "[$(date '+%H:%M:%S')] $machine:$path"
    "$zed_bin" "ssh://${machine}${path}" >/dev/null 2>&1 &
  fi

  sleep 3
done
