#!/usr/bin/env bash
# PostToolUse hook: 編集後に ESLint --fix と Prettier --write を実行する。
#
# stdin: Claude Code から JSON が渡される
#   { "tool_name": "Edit", "tool_input": { "file_path": "..." }, ... }
# stdout: Claude にフィードバックするテキスト
# exit code: 0 = 成功、非 0 = エラー（Claude に伝達）

set -euo pipefail

# jq が無いなら何もしない（環境依存を避ける）
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

# file_path が取れなかった、ファイルが存在しない場合は何もしない
[ -z "$file_path" ] && exit 0
[ ! -f "$file_path" ] && exit 0

# 対象拡張子のみ処理
case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) ;;
  *) exit 0 ;;
esac

errors=()

# ESLint --fix
if [ -f package.json ] && command -v npx >/dev/null 2>&1; then
  if npx --no-install eslint --version >/dev/null 2>&1; then
    if ! npx --no-install eslint --fix "$file_path" 2>/tmp/claude-eslint.log; then
      errors+=("ESLint failed for $file_path:")
      errors+=("$(cat /tmp/claude-eslint.log)")
    fi
  fi
fi

# Prettier --write
if [ -f package.json ] && command -v npx >/dev/null 2>&1; then
  if npx --no-install prettier --version >/dev/null 2>&1; then
    if ! npx --no-install prettier --write "$file_path" 2>/tmp/claude-prettier.log; then
      errors+=("Prettier failed for $file_path:")
      errors+=("$(cat /tmp/claude-prettier.log)")
    fi
  fi
fi

if [ ${#errors[@]} -gt 0 ]; then
  printf '%s\n' "${errors[@]}" >&2
  exit 1
fi

exit 0
