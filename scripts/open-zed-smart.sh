#!/bin/sh
# 在 Mac 的 herdr 里按快捷键：用 Zed 打开。
#
# herdr 给的 workspace_cwd 可能是远程路径（如 /vol1/1000/docker）。
#   - 本机存在该目录 → 本地打开
#   - 不存在 → 认定为远程工作区，查各台已保存机器当前聚焦的目录，
#     用 Zed SSH 远程打开（Zed 会在远端自动装 headless server）
set -e

json_str() {
  printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//" \
    | sed 's/"$//'
}

if [ -n "${ZED_CLI:-}" ]; then
  zed_bin=$ZED_CLI
elif [ -x /Applications/Zed.app/Contents/MacOS/cli ]; then
  zed_bin=/Applications/Zed.app/Contents/MacOS/cli
else
  zed_bin=$(command -v zed || true)
fi
[ -n "$zed_bin" ] || { echo "open-zed: 找不到 Zed" >&2; exit 1; }

herdr_bin="${HERDR_BIN_PATH:-herdr}"

# 某台机器当前聚焦 pane 的 cwd
focused_cwd() {
  "$herdr_bin" --machine "$1" pane list 2>/dev/null | python3 -c "
import json,sys
try:
    for p in json.load(sys.stdin).get('result',{}).get('panes',[]):
        if p.get('focused'):
            print(p.get('cwd','')); break
except Exception:
    pass
" 2>/dev/null || true
}

dir=$(json_str workspace_cwd)
[ -n "$dir" ] || dir=$(json_str focused_pane_cwd)

if [ -n "$dir" ] && [ -d "$dir" ]; then
  nohup "$zed_bin" "$dir" >/dev/null 2>&1 &
  exit 0
fi

machines=$("$herdr_bin" machine list --json 2>/dev/null | python3 -c "
import json,sys
try:
    for m in json.load(sys.stdin):
        if m.get('enabled', True): print(m['label'])
except Exception:
    pass
" 2>/dev/null || true)

for m in $machines; do
  remote_dir=$(focused_cwd "$m")
  if [ -n "$remote_dir" ]; then
    nohup "$zed_bin" "ssh://${m}${remote_dir}" >/dev/null 2>&1 &
    exit 0
  fi
done

echo "open-zed: 本地无 '$dir'，远程也没找到聚焦工作区" >&2
exit 1
