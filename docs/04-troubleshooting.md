# 故障排查

按这个顺序排查：退出码，Provider/模型错误，生成目录，JSONL。模型回复里的“已生成”不能代替文件检查。

## `404` 或图片工具不存在

这通常表示当前 Provider 没有暴露图片工具。用一次性覆盖或包装器选择支持该能力的 Provider：

```bash
CODEX_IMAGE_MODEL=<openai-model> \
  scripts/codex-openai-image exec --json --ephemeral -C "$PWD" - < prompt.txt
```

如果仍失败，检查 Codex 登录态、账号权限、模型名称和 Provider 配置。项目只能覆盖配置，不能补上 Provider 没有实现的能力。

## `Selected model is at capacity`

这是调用模型不可用或容量不足。更换当前账号可用的模型，或稍后重试。这不是图片文件差集问题。

## `Unsupported value` 或 reasoning effort 错误

当前模型可能不接受机器级配置里的 `model_reasoning_effort`。覆盖为模型支持的值：

```bash
CODEX_IMAGE_EFFORT=low scripts/codex-openai-image exec ...
```

## 命令成功，但没有 `saved_path`

依次检查：

1. `CODEX_IMAGE_ROOT` 是否就是 Codex 实际写入的目录。
2. 目录是否存在且当前用户可读。
3. 生成文件是否为新的 `*.png`。
4. 是否有其他进程同时写入同一目录。
5. 包装器和 Codex 是否使用了同一个 `CODEX_HOME`。

包装器只观察 PNG 文件。它不会从自然语言回复猜路径，也不会扫描整个磁盘寻找“看起来像结果”的文件。

## 并发任务互相拿到结果

给每个任务分配独立目录：

```bash
CODEX_IMAGE_ROOT="$PWD/out/jobs/$JOB_ID" \
  scripts/codex-openai-image exec --json --ephemeral -C "$PWD" - < prompt.txt
```

共用目录时，在调用方加锁。仓库脚本不提供跨进程锁。

## 有图但核验不到来源

传给核验脚本的文件应是原始 PNG，而不是截图或重新导出的图片。结果应表述为“未找到可识别字符串”，不能据此断言图片一定不是目标模型生成的。
