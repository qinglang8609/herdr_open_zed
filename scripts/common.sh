#!/bin/sh
# 各脚本共用的小工具。用 `. "$(dirname "$0")/common.sh"` 引入。

# 从 HERDR_PLUGIN_CONTEXT_JSON 里取一个字段的值
json_str() {
  printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//" \
    | sed 's/"$//'
}

# 找 Zed 编辑器，找不到输出空。
# 不能用 `command -v zed`：Linux 上 /usr/sbin/zed 是 Zenoss 组件，会误判。
zed_editor() {
  if [ -n "${ZED_CLI:-}" ]; then
    printf '%s' "$ZED_CLI"
  elif [ -x /Applications/Zed.app/Contents/MacOS/cli ]; then
    printf '%s' /Applications/Zed.app/Contents/MacOS/cli
  fi
}
