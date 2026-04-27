#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // .model.id // "unknown"')
model_id=$(printf '%s' "$input" | jq -r '.model.id // ""')
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // ""')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // ""')

dir_name=$(basename "${cwd:-$PWD}")

if [[ "$model_id" == *"[1m]"* ]]; then
  context_max=1000000
else
  context_max=200000
fi

context_pct="0.0"
if [[ -n "$transcript" && -f "$transcript" ]]; then
  usage_tokens=$(jq -r '
    select(.type == "assistant" and (.message.usage // null) != null)
    | .message.usage
    | (.input_tokens // 0)
      + (.cache_creation_input_tokens // 0)
      + (.cache_read_input_tokens // 0)
  ' "$transcript" 2>/dev/null | tail -n 1)
  if [[ -n "$usage_tokens" && "$usage_tokens" != "null" ]]; then
    context_pct=$(awk -v u="$usage_tokens" -v m="$context_max" \
      'BEGIN { printf "%.1f", (u / m) * 100 }')
  fi
fi

printf '%s | %s | Context %s%%' "$model" "$dir_name" "$context_pct"
