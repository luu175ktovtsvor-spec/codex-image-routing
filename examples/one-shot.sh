#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
output_root="${CODEX_IMAGE_ROOT:-$repo_root/out/example-images}"
mkdir -p "$output_root"

prompt="${*:-生成一张 16:9 的极简插画：深青色背景，中央一个黄色圆点}"

CODEX_IMAGE_ROOT="$output_root" \
  "$repo_root/scripts/codex-openai-image" \
    exec --json --ephemeral --skip-git-repo-check -C "$repo_root" "$prompt"
