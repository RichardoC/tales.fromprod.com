---
layout: post
title:  "Backing up Slack-mojis"
date:   2021-08-05 20:00:00 -0000
categories: [Slack, APIs,  Nonsense]
---
# Backing up Slackmojis

Recently a slack instance I'm on broke through the 11,000 slackmoji barrier. Given this was a significant usage of people's time I figured it was worth backing these up in case of a disaster

## To the docs!

Slack [document](https://api.slack.com/methods/emoji.list) an API which returns all slackmoji names and the URL of their images which are accessible without authentication.

Given this it should be pretty easy to download them all.

## Findings

This code downloads several images a second, and is deliberately unthreaded because this is slow enough not to trigger a rate limit.


## Sample code
Please only use this for innocent fun, where you have permission as you are downloading data from the instance.

This snippet is provided under an [MIT license](https://github.com/git/git-scm.com/blob/main/MIT-LICENSE.txt) and I hold no responsibility for how you choose to use it.

```python
import http.client, urllib.parse, json, urllib.request, shutil, glob

# Replace
# TOKEN with your bearer token like xoxc-
# COOKIE with your browser cookies, you can get this from the network tab
# FOLDER with the full path that you want the slackmojis to be backed up in

conn = http.client.HTTPSConnection("slack.com")

folder = "FOLDER"

headers = { "Content-type": "application/json; charset=utf-8", "Authorization": "Bearer TOKEN", "cookie": "COOKIE"}

conn.request("GET", "/api/emoji.list",  headers=headers)

response = conn.getresponse()

jsonRepr = json.loads(response.read())


for emojiname, url in jsonRepr["emoji"].items():
    print(emojiname)
    print(url)
    filename = f"{emojiname}.{url.split('.')[-1]}"
    print(filename)

    if "alias" in url:
        # Ignoring aliases for now
        continue
    with urllib.request.urlopen(url)  as u:
        with open(f"{folder}/{filename}", 'bw+') as f:
            f.write(u.read())

```
