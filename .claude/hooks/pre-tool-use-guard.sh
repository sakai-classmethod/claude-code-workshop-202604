#!/usr/bin/env bash
# PreToolUse hook: 重要な設定ファイルへの編集をブロックする。
#
# stdin: { "tool_name": "Edit"|"Write", "tool_input": { "file_path": "..." } }
# stdout: 拒否時は JSON を返す
#   {"hookSpecificOutput":{"hookEventName":"PreToolUse",
#    "permissionDecision":"deny",
#    "permissionDecisionReason":"..."}}

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

[ -z "$file_path" ] && exit 0

# 保護対象ファイルパターン
protected_patterns=(
  "tsconfig.json"
  "tsconfig.*.json"
  ".eslintrc"
  ".eslintrc.*"
  "eslint.config.*"
  ".prettierrc"
  ".prettierrc.*"
  "prettier.config.*"
  "package-lock.json"
  "pnpm-lock.yaml"
  "yarn.lock"
)

basename=$(basename "$file_path")

for pattern in "${protected_patterns[@]}"; do
  case "$basename" in
    $pattern)
      reason="設定ファイル ($basename) は手動で変更してください。差分を提示するに留めるか、ユーザーに依頼してください。"
      jq -nc \
        --arg reason "$reason" \
        '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
      exit 0
      ;;
  esac
done

# .env / secrets / credentials を念のため二重防御
case "$file_path" in
  *.env|*.env.*|*/secrets/*|*/credentials/*)
    reason="シークレットファイル ($file_path) への変更は禁止されています。"
    jq -nc \
      --arg reason "$reason" \
      '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
    exit 0
    ;;
esac

exit 0
