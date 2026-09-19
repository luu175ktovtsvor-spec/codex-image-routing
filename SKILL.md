---
name: "codex-image-routing"
description: "Diagnose and explain how a third-party Codex or LLM text route can send only image-generation requests to native OpenAI/Codex ImageGen, using client capability, official authentication, entitlement, provider routing, model, and result evidence without writing scripts or bypassing access controls."
---

# Codex Image Routing Skill

This skill handles routing logic and diagnosis only. It does not generate images, write scripts, install wrappers, or silently change the user's global provider configuration.

Use it when a third-party Codex-compatible client can handle text but native ImageGen is missing, rejected, or unclear, especially when the user has an official OpenAI/Codex membership or login and wants to keep text on a third-party LLM.

## Core model

There are two independent model and provider layers:

```text
text request  -> third-party LLM provider and caller model
image request -> native OpenAI/Codex ImageGen tool and image model
```

Do not infer image capability from text capability. A third-party LLM subscription, API key, or successful text response does not prove native ImageGen access.

Native ImageGen is an official-account route, not a property inherited from the third-party text model. Current CC Switch releases support preserving the official Codex login while routing model traffic through the local proxy, and include Codex image-route fixes. The route still must declare image capability and preserve the native `image_generation` tool; verify a returned `image_generation_call` rather than trusting the account badge. See the [official OpenAI image generation tools guide](https://developers.openai.com/zh-Hans/api/docs/guides/tools-image-generation).

## When to use

- Third-party Codex/LLM text works but image generation returns `404`, unsupported-tool, or provider errors.
- The user wants third-party text plus native OpenAI/Codex ImageGen for images.
- A custom provider accepts ordinary Responses requests but strips or rewrites image-generation tools.
- The user needs to distinguish client capability, membership/entitlement, provider, model, and upstream failures.

## When not to use

- The user only asks to create or edit an image; use the active native ImageGen or explicitly selected Yunshu ImageGen skill.
- The user asks to bypass a membership, entitlement, provider restriction, or account control.
- The user asks for a script, shell wrapper, automatic provider switch, or background monitor.

## Routing decision

1. Identify the client surface: official Codex, third-party Codex-compatible client, IDE integration, or wrapper.
2. Identify the active text provider, caller model, wire/API mode, and authentication source.
3. Check the actual client tool list or request schema for native `image_gen`/`image_generation` exposure.
4. Verify the official OpenAI/Codex account or membership attached to the native route. A third-party LLM membership cannot be converted into native ImageGen access.
5. Verify the CC Switch official-account route/local proxy is enabled and the current Codex provider points to that route.
6. Verify the selected route/model catalog declares image capability. A text-only DeepSeek or other third-party route must not receive the native image tool.
7. Route text requests to the selected third-party provider and image-tool requests to the official image-capable route when the current CC Switch routing configuration supports that split.
8. If the current version or route cannot split them, keep the official route for the image call instead of claiming that the third-party model inherited native ImageGen. Present Yunshu only if the user explicitly chooses it.
9. Before any real request that may consume membership limits or credits, show account/provider route, model, full prompt, references, count, estimated cost or credits, and uncertainty; wait for explicit confirmation when required by the user's workflow.
10. Validate the native result: preserved image tool call, returned image artifact, actual dimensions, format, and requested invariants.

## Evidence levels

Strong evidence:

- native image tool appears in the actual client capability or request schema;
- official OpenAI/Codex authentication and entitlement are verified;
- image request is routed to the official/native provider;
- native tool payload survives unchanged;
- response contains `image_generation_call` and an inspectable image artifact.

Weak evidence that is not sufficient:

- ordinary text completion success;
- a model appearing in a model list;
- a visible ImageGen button alone;
- a custom endpoint accepting the request without returning an image;
- a third-party subscription described as a “membership”.

## Failure classification

- **Tool absent:** client does not expose native ImageGen. This is a client capability problem.
- **Entitlement absent:** official account is not eligible or has no remaining access. Changing the third-party text model does not fix it.
- **Provider mismatch:** native tool exists but the active custom provider strips, rejects, or rewrites it. Use an image-only official route if supported.
- **Official image route unavailable:** the official login is preserved, but the current CC Switch version, route, or model catalog does not expose the image capability. Do not treat the third-party text route as a native image route.
- **Model mismatch:** native provider is reached but the selected image model or option is unavailable. Use only a confirmed supported model and option.
- **Upstream failure:** valid native route returns overload, timeout, or service error. Do not label it a membership failure without evidence.
- **Result missing:** response completes without `image_generation_call` or an image artifact. The route is not proven.

## Reporting format

Report in this order:

1. active text provider and caller model;
2. native client capability status;
3. official account/entitlement status;
4. image-only routing support;
5. selected outcome: native ImageGen, Yunshu ImageGen, or blocked;
6. evidence, uncertainty, and the smallest next action.

## Existing project references

- [Why caller and image models differ](docs/01-why-two-models.md)
- [Routing scope and isolation](docs/02-routing.md)
- [Failure diagnosis](docs/04-troubleshooting.md)
- [Output evidence boundaries](docs/03-verification.md)
