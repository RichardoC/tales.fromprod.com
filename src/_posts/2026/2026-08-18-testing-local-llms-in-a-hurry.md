---
layout: post
title: "Testing local LLMs in a hurry"
date: 2026-08-18 19:00:00 -0000
categories: [LLMs]
---

# Testing local LLMs in a hurry

In preparation for my [workshop](https://pretalx.com/bsides-bristol-2026/talk/WNZPZ3/) at [Bsides Bristol](https://www.bsidesbristol.org.uk/) later in the week, I want to test out a variety of low parameter open weights models, with the [pi harness](pi.dev) to see which can be used for live demos, on attendees laptops. 

I've previously had issues with tool calling on these sorts of models, so have thrown the VM of Claude Code web (or whatever it's called this week) and running the models at ~ 5 tokens/second to try and make sure this won't happen with the chosen model during the workshop. As you can imagine, this has been *slow*

## Disclaimers

Huggingface have not paid me for this, nor have they given me any credits

## The problems

- I want to use open parameter (preferably actual open source) models, that could fit in ~ 8 GB of ram
- I need to run a lot of inference to test these models out, and my own equipment isn't fast enough
- Noone is offering these models as a serverless offering

## My current approach

Huggingface have <https://endpoints.huggingface.co> and from any gguf model page (e.g. <https://huggingface.co/ibm-granite/granite-4.1-3b>) you can select "Deploy" -> HF Inference Endpoints and run them for ~ $0.5/hr on a gpu somewhere.

This has meant I can run multiple sessions at once, and much faster. It's also using llama.cpp, which is what I'm using locally

## How can I do this for myself?

- Follow <https://huggingface.co/docs/inference-endpoints/quick_start>
