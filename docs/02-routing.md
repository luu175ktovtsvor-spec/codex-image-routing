# 路由方式

三种方式都只影响当前图片生成调用，区别在于配置作用域：

| 方式 | 作用域 | 适合场景 | 代价 |
| --- | --- | --- | --- |
| 命令行覆盖 | 当前进程 | 手工试一次 | 命令较长 |
| 包装器 | 当前进程 | 脚本和自动化 | 需要安装脚本 |
| 独立 `CODEX_HOME` | 一组进程 | 长期隔离两套环境 | 要维护第二份配置和登录态 |

## 只覆盖当前命令

```bash
codex -c model_provider="openai" \
  -c model="<openai-model>" \
  -c model_reasoning_effort="low" \
  exec --skip-git-repo-check -C "$PWD" \
  '生成一张 16:9 的极简扁平插画'
```

`-c` 只作用于这一条进程，不写回 `config.toml`。模型要显式指定；否则全局配置里的第三方模型名可能继续传给 OpenAI Provider。

## 使用包装器

```bash
install -m 755 scripts/codex-openai-image "$HOME/.local/bin/codex-openai-image"

CODEX_IMAGE_MODEL=<openai-model> \
  "$HOME/.local/bin/codex-openai-image" \
  exec --json --ephemeral --skip-git-repo-check -C "$PWD" - < prompt.txt
```

包装器做三件事：

1. 注入 Provider 和模型覆盖；
2. 注入一个可配置的 `model_reasoning_effort`；
3. 通过生成目录差集补发 `saved_path` 事件。

它不读取、上传或保存凭据；登录态仍由 Codex 管理。

## 使用独立 `CODEX_HOME`

```bash
export CODEX_HOME="$HOME/.codex-openai"
mkdir -p "$CODEX_HOME"
# 在这里准备只指向目标 Provider 的 config.toml 和登录态。
CODEX_HOME="$CODEX_HOME" scripts/codex-openai-image exec ...
```

独立目录适合长期隔离，但配置和登录状态需要单独维护。不要把 `auth.json` 或其他凭据复制进仓库。

## 批量 API

批量调用可以直接使用服务方的图片 API。API 认证、限流、重试和结果保存由其他客户端负责。
