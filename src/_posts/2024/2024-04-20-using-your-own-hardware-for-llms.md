---
layout: post
title:  "Using your own hardware for llms"
date:   2024-04-20 10:00:00 -0000
categories: [ML,  LLMs, Jan.ai]
---
# Using your own hardware for llms

Things have come a long way since [this post]({% post_url 2023/2023-04-09-getting-started-with-llms-locally%})

This article assumes you have a powerful machine (referred to as "server") and you want to use that for running the models (inference) and want to actually interact with them from another machine (referrred to as "client").

## Prerequisites
* You've installed <https://jan.ai> on both machines
* You've downloaded whatever model you want to use on the server
* You have connectivity from your client machine to the server (e.g. firewalls correctly configured)


## Setting up the server

Once you've installed the models, click on "Local API Server" near the bottom left of the window

On the hosting page use these settings
* select "0.0.0.0" as the host IP
* use whatever port you want
* In Model Settings, set the model you wanted to use and have already downloaded

After this, click "Start Server"

## Setting up the client

First you'll need to open your jan configuration folder, its location can be found in Settings -> Advanced Settings -> Jan Data Folder

In that folder create a file at the path `models/local-local/model.json`

With the following content, replacing `$MODEL_ID` with the model id that you're running on the server

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

Next, restart the Jan.ai application, and navigate to Settings -> OpenAI Inference Engine 

In "Chat Completions Endpoint" Put `http://$IP:$PORT/v1/chat/completions` correcting $IP for the IP of your server, and $PORT for the port you chose on the server.

Leave the API key blank or this won't work.


## Using the model running on your server

Create a new thread and from the model drop down on the right Select "remote" and then "local test"

Send your messages as usual

Congratulations, you're now performing inference on another machine!
