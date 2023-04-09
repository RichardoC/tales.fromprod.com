---
layout: post
title:  "Getting started with LLMs locally"
date:   2023-04-09 19:00:00
categories: [ML, Python, Docker]
---
# Getting started with LLMs locally

So you've heard all the hype about Large Language Models (LLM) and want to run one yourself locally. This guide details how

## Why would I want to run it locally?

* You want to peer behind the curtain of what's actually happening
* You don't want you prompts to be sent to a third party
* You want to test the LLM with sensitive intellectual property
* Why not?

## Prerequisites

* Ubuntu (ish)
* Huge amounts of ram, or a huge [swapfile/swap](https://help.ubuntu.com/community/SwapFaq) partition. 32GB+ is commonly required
* Python experience
* A fast internet connection
* 50GB+ free storage space

## Getting started guide

Install [Docker](https://docs.docker.com/engine/install/debian/) 

If you have an nvidia GPU configured with cuda you might be able to follow <https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/user-guide.html> to use GPU acceleration.

Install git and git lfs and set it up. 

```bash
sudo apt install git git-lfs
git lfs install
```

Download the docker image with all the tools you need, this is ~ 10GB

```bash
docker pull huggingface/transformers-all-latest-gpu
```

Discover the model you want to play with on Hugging Face such as <https://huggingface.co/cerebras/Cerebras-GPT-2.7B>

You can download it by cloning the git repo (~11GB)

```bash
git clone https://huggingface.co/cerebras/Cerebras-GPT-2.7B
```

Now to run the model
```bash
docker run -it --rm  -v $(pwd):/model docker.io/huggingface/transformers-all-latest-gpu
# From now all commands are inside the container
cd /model
# start a python interpreter to use
python3
# from now all commands are inside the python interpreter
```

### Actually playing with the model

Now for the Python, in the REPL terminal. 

```python
# This stage will take a while as it loads the model into ram, and may lead to it getting OOMK
from transformers import AutoTokenizer, AutoModelForCausalLM
tokenizer = AutoTokenizer.from_pretrained("./Cerebras-GPT-2.7B")
model = AutoModelForCausalLM.from_pretrained("./Cerebras-GPT-2.7B")

# convenience function to wrap the steps from prompt to reponse
def model_on_prompt(text):
    inputs = tokenizer(text, return_tensors="pt")
    outputs = model.generate(**inputs, num_beams=5,
                        max_new_tokens=50, early_stopping=True,
                        no_repeat_ngram_size=2)
    text_output = tokenizer.batch_decode(outputs, skip_special_tokens=True)
    print(text_output[0])

# Now to run the model on your prompt
model_on_prompt("What can I use LLMs for?")
```
