# Codex Image Routing

这个项目专门解决一个问题：在 Codex 通过 CC Switch 接入 DeepSeek 等第三方模型后，把图片生成请求路由到原生 OpenAI/Codex ImageGen。

结论如下：

1. CC Switch 可以让 Codex 保留官方登录态，同时把实际文本请求切到 DeepSeek 等第三方 Provider；第三方 Provider 是否支持图片工具，取决于它自己的协议和能力。
2. 第三方 Provider 的文本模型或会员不会自动获得原生 OpenAI/Codex ImageGen。第三方 Provider 即使提供自己的图片模型，也属于另一条图片能力链路。
3. 原生 Codex ImageGen 使用官方 Codex 账号的图片权限和用量。Free 计划也有受限、较慢的图片生成；Plus/Pro 等更高计划提供更多或更快的图片生成。因此“需要官方账号和图片权限”是硬条件，“必须 Plus”不是硬条件。
4. 把日常文本交给第三方模型，可以减少官方 Codex 文本用量，把官方用量优先留给图片任务；实际剩余额度和图片限制必须以 Codex usage dashboard 为准。

网页版 ChatGPT 生图和 Codex 原生 ImageGen 是不同的产品入口和请求路由。网页版能生图，只能证明网页版链路可用，不能证明 CC Switch 接入的第三方 Codex Provider 已经实现原生 ImageGen；两者的具体用量规则也不能自行推断为完全相同或完全独立。

当前版本的正确路由是：保留官方 Codex 登录态，启用 CC Switch 官方账号/本地代理路由，文本请求走第三方 Provider，图片请求走官方 ImageGen 路由。Provider 的模型目录必须声明图片能力；DeepSeek 等纯文本路由不能接收原生图片工具。

如果当前 CC Switch 版本或路由配置没有图片能力，先升级或修正官方图片路由，再验证 `image_generation_call` 和真实图片结果；不能把“Codex 仍显示会员账号”当成图片路由成功。只有在官方图片路由仍不可用时，才把整次图片调用临时切回官方 Provider。

包装器负责两件事：切换当前进程的 Provider，以及交接新生成的文件路径。

![Codex Image Routing architecture](docs/assets/image-routing.svg)

## 适用场景

- 使用 CC Switch 让 Codex 接入 DeepSeek 等第三方模型，同时把原生 ImageGen 路由到官方 Provider。
- 具备官方 Codex 登录态和图片权限，准备把第三方模型用于文本，把官方用量优先留给图片生成。
- 需要确认第三方文本请求、原生图片工具、官方会员权限和真实图片结果分别是否成立。
- 日常 Codex 会话使用自定义 Provider，图片调用切换到官方 Provider。
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
