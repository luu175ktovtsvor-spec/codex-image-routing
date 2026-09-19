#!/usr/bin/env bash
# 读取图片内嵌的 C2PA 署名，判断产出像素的软件。
#
# 用法: verify-image-provenance.sh <图片文件> [更多图片...]
#
# 注意: 署名说明的是产出像素的软件，与调用它的语言模型无关。
#       转码、二次编辑、截图都会破坏或剥离署名。

set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "用法: $0 <图片文件> [更多图片...]" >&2
  exit 2
fi

for file in "$@"; do
  if [ ! -f "$file" ]; then
    echo "跳过（文件不存在）: $file" >&2
    continue
  fi

  # C2PA 的字段在二进制里是连在一起的，例如 name/gpt-image/version/2.0，
  # 所以按固定片段切，而不是按引号切。
  software="$(strings -a "$file" 2>/dev/null | grep -o 'gpt-image' | head -1 || true)"
  # 二进制里的形如 gversionc2.0q：g=键分隔，version=键名，c=字符串标记，2.0=值，q=结束
  version="$(strings -a "$file" 2>/dev/null | grep -o 'gversionc[0-9][0-9.]*q' | head -1 | sed 's/^gversionc//; s/q$//' || true)"
  source_type="$(strings -a "$file" 2>/dev/null | grep -o 'trainedAlgorithmicMedia' | head -1 || true)"
  llm_mentions="$(strings -a "$file" 2>/dev/null | grep -ci -e 'luna' -e 'gpt-5' || true)"

  echo "文件: $file"
  echo "生成软件: ${software:-未找到}"
  echo "版本: ${version:-未找到}"
  echo "数字来源类型: ${source_type:-未找到}"
  echo "是否出现语言模型名（luna/gpt-5）: $([ "${llm_mentions:-0}" -gt 0 ] && echo 是 || echo 否)"
  echo
done
