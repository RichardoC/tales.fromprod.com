---
layout: post
title: "Migrate cloudformation to opentofu with LLMs"
date: 2024-09-23 15:00:00 -0000
categories: [ChatGPT, APIs]
---

# Migrate cloudformation to opentofu with LLMs

I discovered that Cloudformation won't override manual changes so decided to migrate a typescript CDK stack over to openTofu. This means I now get to the delta between reality and what I requested.

However, migrating between these technologies can be fiddly so figured I should get some help generating the bulk of the required changes and I can then manually tweak as required.

## First attempt - cf2tf

<https://github.com/DontShaveTheYak/cf2tf> - A nice tool, but requires quite a lot of manual changes to the resulting Terraform in my experience.

### Steps

- npx cdk synth MyStack
- cf2tf MyStack.template.json
- manually fix the openTofu to cover all resources
- run `tofu init`
- manually write all the required `tofu import` statements to ensure all resources governed by openTofu
- Check in AWS Cloudformation Console that every `resource` has an openTofu entry
- In the AWS Cloudformation Console manually update the cloudformation template in Application Composer to ensure all resources have a DeletionPolicy: Retain
- Delete the Cloudformation Stack via the console
- Delete the stack from the local repo

## Second attempt - OpenAI's o1-preview LLM

The steps listed are similar to the first attempt, but far fewer manual changes were required and typically the import commands were writen correctly. This worked well for stacks with small numbers of resources (~10) and less well on large stacks (~80 resources)

Just change any terraform commands to `tofu`

### Steps

- npx cdk synth MyStack
- Add files to the template prompt
- run prompt via chatgpt or API
- run `tofu init`
- Check the required `tofu import` statements provided, and run them to ensure all resources governed by openTofu
- Check in AWS Cloudformation Console that every `resource` has an openTofu entry
- In the AWS Cloudformation Console manually update the cloudformation template in Application Composer to ensure all resources have a DeletionPolicy: Retain
- Delete the Cloudformation Stack via the console
- Delete the stack from the local repo

#### Prompt

Add the relevant files between the [START FILE: XXX] and [END FILE] tags, then send this over via the openAI API, or via ChatGPT.

Do **NOT** use the file upload function of chatgpt, it performs much worse on the details which mean the imports don't work. I suspect this is because it's using RAG on the files, rather than including them in their entirety in the context.

I tested this with `o1-preview-2024-09-12`

```text

Convert this cloudformation cdk in typescript to terraform. It's infrastructure as code for an AWS environment. It already exists so I'll have to do terraform imports of the existing resources. Include the import statements.

Here is the cloudformation template

[START FILE: MyStack.assets.json]

[END FILE]

[START FILE: MyStack.template.json]

[END FILE]

[START FILE: library.ts]
// some actual cloudformation stacks

[END FILE]

[START FILE: manifest.json]

[END FILE]

```
