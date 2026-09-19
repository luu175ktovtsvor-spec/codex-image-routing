# 调用模型和图片模型不是一回事

一次图片生成调用通常有两个模型角色：

| 角色 | 责任 | 是否由本项目选择 |
| --- | --- | --- |
| Codex 调用模型 | 读取提示词、决定是否调用图片工具、提交工具参数。 | 包装器通过 `model` 覆盖值影响它。 |
| 图片生成模型 | 根据工具请求生成像素，并可能写入来源信息。 | 由 Codex/Provider 的图片能力决定。 |

调用链可以简化为：

```text
prompt
  -> Codex model
  -> image tool
  -> provider service
  -> image model
  -> PNG on disk
```

这两个角色解决不同的问题。日志里的模型名通常是 Codex 的调用模型，不一定是产出 PNG 的图片模型。反过来，PNG 里的来源信息也不能证明调用模型是否按原文提交了提示词。

## 为什么 Provider 会影响图片生成

图片能力以工具形式出现在请求链路中。一个 Provider 可以支持文本对话，却没有实现这个工具，结果就可能是 `404` 或其他能力不支持错误。

包装器只改变当前进程的 Provider 和模型配置：

```bash
codex -c model_provider="openai" -c model="<openai-model>" \
  -c model_reasoning_effort="low" exec ...
```

它不会改变图片模型的算法，也不会提升图片质量。问题如果来自额度、账号权限、模型容量或提示词，只改路由解决不了。
