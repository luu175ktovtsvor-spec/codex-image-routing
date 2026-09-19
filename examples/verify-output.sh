#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  printf 'usage: %s STREAM_JSONL\n' "$0" >&2
  exit 2
fi

saved_path="$(sed -n 's/.*"saved_path":"\([^"]*\)".*/\1/p' "$1" | tail -1)"
if [ -z "$saved_path" ]; then
  echo 'no saved_path event found' >&2
  exit 1
fi

scripts_dir="$(cd "$(dirname "$0")/../scripts" && pwd)"
"$scripts_dir/verify-image-provenance.sh" "$saved_path"
