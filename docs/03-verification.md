# 核验输出

核验分两层：命令是否成功，文件是否保留了可识别的来源信息。

## 1. 看命令结果

包装器的退出码来自 Codex 子进程。退出码为 `0` 只表示子进程成功结束，不表示一定找到了新 PNG。调用方检查 JSONL 中是否出现 `saved_path`，并验证路径指向现有文件。

```bash
examples/jsonl-pipeline.sh prompt.txt > stream.jsonl
examples/verify-output.sh stream.jsonl
```

如果没有 `saved_path`，检查 `CODEX_IMAGE_ROOT`、文件扩展名、退出码和生成目录权限。

## 2. 看来源字符串

```bash
scripts/verify-image-provenance.sh /absolute/path/to/image.png
```

脚本会尝试读取这些字符串：

- `gpt-image` 软件标识；
- 版本字段；
- `trainedAlgorithmicMedia` 来源类型；
- 常见调用模型名是否出现在文件中。

这只是快速检查，不是完整的 C2PA 验证。脚本不验证签名链、证书信任或完整 manifest。

## 结果解释

| 结果 | 说明 |
| --- | --- |
| 找到图片路径，且来源字符串存在 | 文件可能保留了生成来源信息，可以继续做更严格的验证。 |
| 找到图片路径，但来源字符串不存在 | 文件可能被转码、截图、二次编辑，或者服务没有写入这些字段。 |
| 没有图片路径 | 生成目录没有出现可识别的新 PNG，先查命令和目录配置。 |
| 退出码非零 | 先按 Provider、模型或配置错误处理，不要把缺少图片归因给核验脚本。 |

原始文件比截图、社交平台下载文件或重新导出的副本更适合核验；来源信息可能在转换过程中丢失。
