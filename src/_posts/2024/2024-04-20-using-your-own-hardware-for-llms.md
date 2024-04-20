---
layout: post
title:  "Using your own hardware for llms"
date:   2024-04-20 10:00:00 -0000
categories: [ML,  LLMs, Jan.ai]
---
# Using your own hardware for llms

Things have come a long way since [this post]({% post_url 2023/2023-04-09-getting-started-with-llms-locally%})

This article assumes you have a powerful machine (referred to as "server") and you want to use that for running the models (inference) and want to actually interact with them from another machine (referred to as "client").

## Prerequisites

- Jan.ai installed on both the server and client machines
- A specific model of your choice downloaded on the server
- Network connectivity possible between the client and server (e.g., firewalls configured correctly)


## Setting up the server

After installing the models in Jan.ai on the server, click on "Local API Server" located near the bottom left corner of the window.

On the hosting page use the following settings
- Set the host IP to "0.0.0.0"
- Choose any desired port number
- In Model Settings, select the model you have already downloaded
- Click "Start Server" to initiate the local API server.


## Setting up the client

* Navigate to the Jan.ai configuration folder, which can be found in Settings -> Advanced Settings -> Jan Data Folder.
* Create a file named `model.json` at the path `models/local-local/model.json`.
* Add the following content to the `model.json` file, replacing `$MODEL_ID` with your server's model ID such as `hermes-pro-7b`:

```json

{
  "sources": [
    {
      "url": "https://jan.ai"
    }
  ],
  "id": "$MODEL_ID",
  "object": "model",
  "name": "local test",
  "version": "1.0",
  "description": "Test server",
  "format": "api",
  "settings": {},
  "metadata": {
    "author": "test",
    "tags": ["remote"]
  },
  "engine": "openai",
  "state": "ready"
}
```

1. Restart the Jan.ai application on the client machine.
2. Access Settings -> OpenAI Inference Engine and enter `http://$IP:$PORT/v1/chat/completions` in the "Chat Completions Endpoint" field, replacing $IP with your server's IP address and $PORT with the chosen port number on the server. Leave the API key blank or it won't work.

## Using the model running on your server

Using the Model Running on Your Server:
1. Create a new thread in the Jan.ai application on the client machine.
2. In the model dropdown menu on the right, select "remote" and then choose "local test".
3. Start sending messages as usual and (hopefully) have a faster experience.

Congratulations, you're now performing inference on another machine!

## Conclusion

By following these steps, you can utilise your own hardware for LLM usage and enjoy the benefits of running models and interacting with them from a remote machine. Enjoy the improved performance, privacy and flexibility offered by this setup.
