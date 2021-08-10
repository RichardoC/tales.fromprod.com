---
layout: post
title:  "Managing Google Groups via the API, aka what they don't want you to do!"
date:   2021-08-10 2:00:00
categories: [Google, APIs,  Golang, Go]
---
# Managing Google Groups via the API, despite their best efforts
Google have made it difficult to do this, they somewhat document two different APIs to achieve this, with limited success. This is especially true if you want to use a service account rather than a user API token for the management.

* [Using the directory API](https://developers.google.com/admin-sdk/directory/v1/guides/manage-groups)
* [Using the Cloud Identity APIs - newer and seems to be preferred going forward](https://cloud.google.com/identity/docs/how-to/create-dynamic-groups)

At the time of writing, this are not sufficiently detailed to do more than work out those are the APIs to use. That's where this guide comes in.

## What you'll achieve by the end of this //rephrase

A google group who's membership is managed (via email address) by a Golang binary. The steps will apply to the other language client libraries

## Prerequisites
* Google Cloud Identity Premium
* A paid for Google Workspace
* A Google cloud Service Account (SA)
  * An API key for that SA
  * To record the email address of that SA
* The magic "Customer ID"
  * This can only be obtained through the steps on https://support.google.com/a/answer/10070793?hl=en by a workspace admin
* The google group you wish to manage



