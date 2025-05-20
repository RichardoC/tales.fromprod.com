---
layout: post
title: "Have Claude yell at you with MCP and bash"
date: 2025-05-20 12:00:00 -0000
categories: [APIs, Claude, MCP]
---

# Have Claude yell at you with MCP and bash

There's a lot of excitement currently with Anthropic's Model Context Protocol [MCP](https://modelcontextprotocol.io/introduction) and "servers" to allow language models to do more stuff.

Their tutorials use libraries with a _lot_ of code (the npm one is [5MB!](https://www.npmjs.com/package/@modelcontextprotocol/sdk))

What if there was a simpler way for an infra person to get started?

That's right, which if it could be done with ~ 35 lines of bash?

## What's needed?

You need something that runs, and accepts text on stdin - and fulfils an [API](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/schema/2024-11-05/schema.ts)

## So, how can I get an LLM to yell at me?

First, write the "say-mcp" script, which will use "say" on macos for text to speech (tts) to say whatever string the language model sent to it.

For this example, write the following to `/tmp/say-mcp.sh` and `chmod +x /tmp/say-mcp.sh` it to ensure it can be executed

```bash

#!/bin/bash

echo "Starting mcp_add.sh" >> /tmp/say-mcp-requests.log

while read -r line; do
    echo $line >> /tmp/say-mcp-requests.log
    # Parse JSON input using jq
    method=$(echo "$line" | jq -r '.method' 2>/dev/null)
    id=$(echo "$line" | jq -r '.id' 2>/dev/null)
    if [[ "$method" == "initialize" ]]; then
        echo '{"jsonrpc":"2.0","id":'"$id"',"result":{"protocolVersion":"2024-11-05","capabilities":{"experimental":{},"prompts":{"listChanged":false},"resources":{"subscribe":false,"listChanged":false},"tools":{"listChanged":false}},"serverInfo":{"name":"say","version":"0.0.1"}}}'

    elif [[ "$method" == "notifications/initialized" ]]; then
        : #do nothing

    elif [[ "$method" == "tools/list" ]]; then
        echo '{"jsonrpc":"2.0","id":'"$id"',"result":{"tools":[{"name":"say","description":"Says the provided string with text to speech.\n\nArgs:\n    text\n","inputSchema":{"properties":{"text":{"title":"Text","type":"string"}},"required":["text"],"type":"object"}}]}}'

    elif [[ "$method" == "resources/list" ]]; then
        echo '{"jsonrpc":"2.0","id":'"$id"',"result":{"resources":[]}}'

    elif [[ "$method" == "prompts/list" ]]; then
        echo '{"jsonrpc":"2.0","id":'"$id"',"result":{"prompts":[]}}'

    elif [[ "$method" == "tools/call" ]]; then
        #{"method":"tools/call","params":{"name":"addition","arguments":{"num1":"1","num2":"2"}},"jsonrpc":"2.0","id":20}
        tool_method=$(echo "$line" | jq -r '.params.name' 2>/dev/null)
        speech=$(echo "$line" | jq -r '.params.arguments.text' 2>/dev/null)
        say "${speech}"
        echo '{"jsonrpc":"2.0","id":'"$id"',"result":{"content":[{"type":"text","text":"said ${speech}"}],"isError":false}}'

    else
        echo '{"jsonrpc":"2.0","id":'"$id"',"error":{"code":-32601,"message":"Method not found"}}'
    fi
done || break
```

Now we have our "MCP server" we need to tell Claude to use it.

Open Claude settings, go to developer, then click "Edit Config"

Add the "mcpServers" section, the important part is the "say" object, and the command needs to be the path of the shell script

```json
{
  "mcpServers": {
    "say": {
      "command": "/tmp/say-mcp.sh",
      "args": []
    }
  }
}
```

Restart Claude, and you should now have the ability to ask Claude to say/yell stuff at you.

## Credits

Thanks to <https://github.com/antonum/mcp-server-bash/tree/main> for the original idea
