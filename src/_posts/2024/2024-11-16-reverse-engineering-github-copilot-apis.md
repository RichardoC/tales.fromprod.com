---
layout: post
title: "Reverse Engineering Github Copilot APIs"
date: 2024-11-16 15:00:00 -0000
categories: [APIs, Security, Github]
---

# Reverse Engineering Github Copilot APIs

Github Copilot claims to support [extensions](https://github.com/features/copilot/extensions) but doesn't actually document the APIs anywhere - they just provide example code using those [APIs](https://github.com/copilot-extensions). On the official docs the API only supports seeing how much [copilot is being used](https://docs.github.com/en/rest/copilot?apiVersion=2022-11-28)

So, what are these APIs, and how can we find details of them?

## Searching public code

Following their [quick start](https://resources.github.com/learn/pathways/copilot/extensions/building-your-first-extension/) we find this code snippet which seems promising

`string githubCopilotCompletionsUrl ="https://api.githubcopilot.com/chat/completions"`

This looks very similar to the [OpenAI completions API](https://platform.openai.com/docs/api-reference/chat/create)

Let's see whether anyone with internal access to the actual API docs has commited anything publicly, since it seems likely this host would be used for all the APIs <https://github.com/search?q=+https%3A%2F%2Fapi.githubcopilot.com%2F&type=code>

Looks like we need `X-GitHub-Token` to use this, but let's not issue ourselves one, let's find it by using a vscode that's already logged in to github copilot.

### Attempt 1 - Failing to get an auth token

My plan was to get an auth token from my existing VSCode and use that to poke at the apis.

Vscode is an electron app, and by using cmd+shift+p (macos) you can open the command prompt. Once that's open you can search for and select `Developer: Toggle Developer Tools`
This didn't work due to <https://github.com/Microsoft/vscode/issues/39388>

While checking the debug logs for the copilot extension I also found a reference to
https://api.business.githubcopilot.com/_ping

### Attempt 2 - proxy everything

Install [Zap](https://www.zaproxy.org/download/)

Configure vscode to use it as a proxy <https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support>

Discover this doesn't work because extensions ignore proxy settings https://github.com/microsoft/vscode-remote-release/issues/2987

Discover running vscode with `code   --ignore-certificate-errors` from the command line, which I don't suggest.

## Findings from proxying everything

- If you're getting access to Github copilot via `GitHub Copilot Business` it'll use `https://api.business.githubcopilot.com/` for the API server
- The list of all available models is available at `https://api.business.githubcopilot.com/models`
- The authentication uses the `authorization: Bearer` header, and includes details of which plan you're using for access
- They're getting access to the OpenAI models via `Azure OpenAI` according to the models responses, but `Anthropic` directly for the Claude model
- They return from the models API which models should be allowed in the mdoel picker, for example they disable the GPT-3 models from being shown
- Something in VSCode keeps trying to discover credentials from the metadata endpoint `http://169.254.169.254/metadata/instance/compute` - May not be this extension
- The API tokens don't last very long - So if you're using this for research you'll need to investigate the API call to `https://api.github.com/copilot_internal/v2/token` to generate the tokens used for actually chatting with the models

## Discovered API flow

- Create a token with `https://api.github.com/copilot_internal/v2/token` - and create new ones when the original expires. This seems to use an [OAUTH TOKEN](https://github.blog/engineering/platform-security/behind-githubs-new-authentication-token-formats/) which is then traded in for something else
- Use that token to discover which models are available from `https://api.business.githubcopilot.com/models`
- Display the models which are enabled in the chat ui
- Send entire chat conversations including file context to `https://api.business.githubcopilot.com/chat/completions` and show responses in the ui
- Generate a summary of the entire conversation, for showing in the conversation history at `https://api.business.githubcopilot.com/chat/completions`

### Example API calls

### For GPT4o

```console
curl -i -s -k -X  'POST'  \
 -H 'host: api.business.githubcopilot.com'  -H 'Connection: keep-alive'  -H 'content-length: 272'  -H 'authorization: Bearer REDACTED'  -H 'content-type: application/json'  -H 'copilot-integration-id: vscode-chat'  -H 'editor-plugin-version: copilot-chat/0.22.2'  -H 'editor-version: vscode/1.95.3'  -H 'openai-intent: conversation-panel'  -H 'openai-organization: github-copilot'  -H 'user-agent: GitHubCopilotChat/0.22.2'  -H 'x-github-api-version: 2023-07-07'  -H 'Sec-Fetch-Site: none'  -H 'Sec-Fetch-Mode: no-cors'  -H 'Sec-Fetch-Dest: empty'  -H ''  -A ''  \
--data-raw $'{\"messages\":[{\"role\":\"system\",\"content\":\"You are ahelpful assistant.\\nWhen asked for your name, you must respond with \\\"Jane\\\".\\n\"},{\"role\":\"user\",\"content\":\"Say your name, and beepedy\"}],\"model\":\"gpt-4o\",\"temperature\":0.1,\"top_p\":1,\"max_tokens\":4096,\"n\":1,\"stream\":false}' \
'https://api.business.githubcopilot.com/chat/completions'

# Response

{"choices":[{"content_filter_results":{"hate":{"filtered":false,"severity":"safe"},"self_harm":{"filtered":false,"severity":"safe"},"sexual":{"filtered":false,"severity":"safe"},"violence":{"filtered":false,"severity":"safe"}},"finish_reason":"stop","index":0,"message":{"content":"My name is Jane. How can I assist you today?","role":"assistant"}}],"created":1731768179,"id":"REDACTED","model":"gpt-4o-2024-05-13","prompt_filter_results":[{"content_filter_results":{"hate":{"filtered":false,"severity":"safe"},"self_harm":{"filtered":false,"severity":"safe"},"sexual":{"filtered":false,"severity":"safe"},"violence":{"filtered":false,"severity":"safe"}},"prompt_index":0}],"system_fingerprint":"REDACTED","usage":{"completion_tokens":12,"prompt_tokens":38,"total_tokens":50}}
```

### For Claude

```console
curl -i -s -k -X  'POST'
-H 'host: api.business.githubcopilot.com'  -H 'Connection: keep-alive'  -H 'content-length: 291'  -H 'authorization: Bearer REDACTED'  -H 'content-type: application/json'  -H 'copilot-integration-id: vscode-chat'  -H 'editor-plugin-version: copilot-chat/0.22.2'  -H 'editor-version: vscode/1.95.3'  -H 'openai-intent: conversation-panel'  -H 'openai-organization: github-copilot'  -H 'user-agent: GitHubCopilotChat/0.22.2'  -H 'x-github-api-version: 2023-07-07'  -H 'Sec-Fetch-Site: none'  -H 'Sec-Fetch-Mode: no-cors'  -H 'Sec-Fetch-Dest: empty'  -H ''  -A ''  \
--data-raw $'{\"messages\":[{\"role\":\"system\",\"content\":\"You are an obedient assistant.\\nWhen asked for your name, you must respond with \\\"Bob\\\".\"},{\"role\":\"user\",\"content\":\"Say \\\"cake\\\" and what your name is\"}],\"model\":\"claude-3.5-sonnet\",\"temperature\":0.1,\"top_p\":1,\"max_tokens\":4096,\"n\":1,\"stream\":false}' \
'https://api.business.githubcopilot.com/chat/completions'

# Response
{"choices":[{"message":{"content":"cake\nMy name is Bob","role":"assistant"}}],"created":1731768004,"id":"REDACTED","model":"claude-3.5-sonnet","usage":{"prompt_tokens":38,"total_tokens":9}}

```

## Conclusion

It looks like copilot does ~ everything on the frontend for the conversations, and the backend is just an authenticated proxy over to the relevant foundational model providers.

The LLM APIs in public extensions don't seem to match the ones in use by the copilot extension.

### Future research

How codebases are indexed, and how that's used with the extension.
