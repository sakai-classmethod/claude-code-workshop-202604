#!/usr/bin/env bash
# PreToolUse hook (Bash matcher): main / master ブランチへの直接 commit / push を防ぐ。
#
# stdin: { "tool_name": "Bash", "tool_input": { "command": "..." } }

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

[ -z "$cmd" ] && exit 0

# git commit / git push のみ対象
case "$cmd" in
  *"git commit"*|*"git push"*) ;;
  *) exit 0 ;;
esac

# git リポジトリ外なら何もしない
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

case "$current_branch" in
  main|master|develop|release/*)
    reason="保護ブランチ ($current_branch) への直接 commit / push はブロックされました。'git switch -c <feature-branch>' で新規ブランチを切ってから commit してください。"
    jq -nc \
      --arg reason "$reason" \
      '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
    exit 0
    ;;
esac

exit 0
