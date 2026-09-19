#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  printf 'usage: %s PROMPT_FILE\n' "$0" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
output_root="${CODEX_IMAGE_ROOT:-$repo_root/out/example-images}"
stream_file="${CODEX_IMAGE_STREAM:-$repo_root/out/example-images/stream.jsonl}"
mkdir -p "$output_root" "$(dirname "$stream_file")"

CODEX_IMAGE_ROOT="$output_root" \
  "$repo_root/scripts/codex-openai-image" \
    exec --json --ephemeral --skip-git-repo-check -C "$repo_root" - < "$1" \
    | tee "$stream_file"

printf '\nJSONL saved to %s\n' "$stream_file" >&2
