# Codex Image Routing

当你在 Codex 里通过 CC Switch 接入 DeepSeek 等第三方模型时，文本对话可能正常，但原生 ImageGen 工具可能因为 Provider 没有暴露图片能力而失败，常见表现是 `404` 或 unsupported-tool。

如果你有具备相应权限的 OpenAI/Codex 会员账号，可以把第三方模型用于日常文本，把官方账号的额度尽量保留给原生 ImageGen。这样做的前提是客户端能够把文本请求和图片请求分开路由；第三方模型的会员或 API Key 本身不会自动获得原生 ImageGen 权限。

网页版 ChatGPT 的图片生成和 Codex 里的原生 ImageGen 是两条不同的客户端与请求链路。网页版能生成图片，不等于 CC Switch 接入的第三方 Codex Provider 已经支持原生 ImageGen；反过来也不能仅凭网页状态判断 Codex 路由是否正常。

这个仓库记录路由判断、故障边界和结果核验，并保留一个现有的进程级路由实现：它可以把一次图片调用切到官方 Provider，但不把“整次调用切换”误称为“同一会话内的按请求分流”。

包装器负责两件事：切换当前进程的 Provider，以及交接新生成的文件路径。

![Codex Image Routing architecture](docs/assets/image-routing.svg)

## 适用场景

- 使用 CC Switch 让 Codex 接入 DeepSeek 等第三方模型，同时需要排查原生 ImageGen 的 Provider 路由。
- 具备官方 OpenAI/Codex 会员或登录态，希望把第三方模型用于文本、把官方额度保留给图片生成。
- 需要区分“第三方文本请求成功”“原生图片工具已暴露”“账号具备图片权限”和“图片结果真实返回”这几个不同层次。
- 日常 Codex 会话使用自定义 Provider，图片生成需要临时走 OpenAI Provider。
- 自动化程序调用 `codex exec --json`，需要拿到新生成文件的路径。
- 需要对原始 PNG 做来源信息检查。

如果当前 Provider 已经正确转发图片工具，不需要使用本项目。

## 一次调用发生什么

一次调用按这个顺序运行：

1. 包装器记录生成目录中已有的 PNG。
2. 包装器为本次 Codex 进程覆盖 `model_provider`、`model` 和 `model_reasoning_effort`。
3. Codex 调用图片工具，生成文件写入 `CODEX_HOME/generated_images/`，或写入 `CODEX_IMAGE_ROOT` 指定的目录。
4. 包装器比较调用前后的文件清单，透传原始输出，再补发一条带 `saved_path` 的 JSONL 事件。

数据流见 [架构说明](docs/architecture.md)。

## 快速开始

运行条件：`codex` 已安装，当前 `$CODEX_HOME` 有可用的 OpenAI 登录态。包装器不保存凭据，也不修改全局配置。

```bash
install -m 755 scripts/codex-openai-image "$HOME/.local/bin/codex-openai-image"

printf '%s\n' '生成一张 16:9 的扁平插画：深青色背景，中央一个黄色圆点' \
  | "$HOME/.local/bin/codex-openai-image" exec --json --ephemeral \
      --skip-git-repo-check -C "$PWD" -
```

手工调用也可以直接使用一次性配置覆盖：

```bash
codex -c model_provider="openai" -c model="<openai-model>" \
  -c model_reasoning_effort="low" \
  exec --skip-git-repo-check -C "$PWD" \
  '生成一张 16:9 的扁平插画：深青色背景，中央一个黄色圆点'
```

`<openai-model>` 填写当前账号可用的 OpenAI 模型名。

## 包装器参数

| 环境变量 | 默认值 | 用途 |
| --- | --- | --- |
| `CODEX_IMAGE_MODEL` | `gpt-5.6-luna` | 本次调用使用的 OpenAI 侧模型。按本地可用模型覆盖。 |
| `CODEX_IMAGE_EFFORT` | `low` | `model_reasoning_effort` 覆盖值。 |
| `CODEX_BIN` | `codex` | Codex 可执行文件路径。 |
| `CODEX_IMAGE_ROOT` | `$CODEX_HOME/generated_images` | 生成目录。 |

示例：

```bash
CODEX_IMAGE_MODEL=<openai-model> \
CODEX_IMAGE_ROOT="$PWD/out/images" \
  "$HOME/.local/bin/codex-openai-image" exec --json --ephemeral \
    --skip-git-repo-check -C "$PWD" - < prompt.txt
```

更多调用场景见 [examples/](examples/) 和 [路由方式](docs/02-routing.md)。

## 结果核验

包装器补发的 JSONL 事件记录生成目录中新出现的 PNG，不负责证明图片来源。检查原始文件时运行：

```bash
scripts/verify-image-provenance.sh /absolute/path/to/image.png
```

这个脚本读取 PNG 中可见的 C2PA 相关字符串。转码、截图或二次编辑可能移除来源信息。核验规则和失败含义见 [结果核验](docs/03-verification.md)。

## 限制

- 包装器调用 Codex CLI，不直接调用图片 API。
- 包装器读取 Codex 的生成目录和 `--json` 输出。
- 并发调用时，为每个任务使用独立的 `CODEX_IMAGE_ROOT`，或在上层加锁。

## 文档导航

- [架构说明](docs/architecture.md)：组件、数据流、边界和失败层级。
- [路由方式](docs/02-routing.md)：一次性覆盖、包装器和独立 `CODEX_HOME`。
- [两层模型](docs/01-why-two-models.md)：调用模型与图片模型的职责区别。
- [结果核验](docs/03-verification.md)：读取来源信息和判断核验结果。
- [故障排查](docs/04-troubleshooting.md)：JSONL、文件差集和并发问题。

## 发布说明

仓库只包含脚本、示例和文档。

本项目采用 [MIT License](LICENSE)。
