#!/bin/sh
# 跑在 FNOS 上（herdr action）：建一个名为 ZED 的 tab 作为信号。
# Mac 侧的 zed-tab-watch.sh 看到这个 tab 就打开 Zed，然后把它关掉。
set -e

herdr="${HERDR_BIN_PATH:-herdr}"

json_str() {
  printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//" \
    | sed 's/"$//'
}

dir=$(json_str workspace_cwd)
[ -n "$dir" ] || dir=$(json_str focused_pane_cwd)

# tab 是给 Mac 看的信号，里面不需要跑东西，用 true 让它立刻结束
"$herdr" tab create --label "ZED" --focus ${dir:+--cwd "$dir"} >/dev/null
echo "已请求本地 Zed 打开: ${dir:-当前目录}"
