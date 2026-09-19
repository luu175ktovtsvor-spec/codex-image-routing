# Examples

这些示例展示包装器的调用结构，输出写入任务目录。

## Files

- [`one-shot.sh`](one-shot.sh)：一次性调用包装器，适合手工验证。
- [`jsonl-pipeline.sh`](jsonl-pipeline.sh)：把 prompt 文件交给包装器，并把 JSONL 输出保存下来。
- [`verify-output.sh`](verify-output.sh)：从 JSONL 中取出 `saved_path`，再调用来源核验脚本。

示例使用 `CODEX_IMAGE_ROOT` 指向任务目录，避免把输出混进仓库。
