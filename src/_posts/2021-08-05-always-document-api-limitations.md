---
layout: post
title:  "Slack-mojis, and why documenting API limitations helps!"
date:   2021-08-04 20:00:00 -0000
categories: slack api nonsense
---
# Slackmojis and API limits
During a "discussion" on our slack channel about long... thonks, a question occurred - "Just how many slackmojis can be sent in a slack message?"

## To the docs!
Slack [document](https://api.slack.com/changelog/2018-04-truncating-really-long-messages) that the max message length is *40,000 characters*.

Given this, and that you can declare a slackmoji with `:slackmoji:` we should be able to send 40,000/(len(:slackmoji:)) right...?

Okay, let's generate that message, and then paste it in the text box

```bash
python3 -c 'print(":longthonk1:" + ":longthonk2::longthonk3::longthonk4:" * ((40000- len(":longthonk1:") - len(":longthonk5:") )// len(":longthonk2::longthonk3::longthonk4:")) + ":longthonk5:")'
```

Also, turns out `xargs -J` can't interpolate 40k characters, and `xargs -I` can only do even fewer. The `-J` doesn't error, it'll only put the characters afterwards as if that flag is ignored. Who knew?

### What happened
So, you can paste this in and wait a *long* time, as the slack client seems to parse the message for each slackmoji and then render it leading to the following great video in real time

<video width="610" controls>
  <source src="/assets/2021-08-05-always-document-api-limitations/slow-decoding.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>

Once it renders the message, nothing happens if you click the send button.

### Now what?
Well, let's assume that the web client wasn't up to the challenge of our message (sorry devs). Why don't we try the API ourselves?

## Having fun at the expense of the slack API
I didn't want to create an app for this, so what do to? Using use API tokens for the API is no longer supported.... Or is it?

### Getting API calls to work with user tokens
I got the network calls while sending a message and started stripping piece of it until I found the minimum that works...

Turns out all you need is the user token, and the cookies. If you don't include the cookie you'll get an unauthorised response.

```{"ok": false, "error": "invalid_auth"}```

### How are slackmojis represented?

After further experimentation, it turns out the API actually considers slackmojis to be emojis, and they have to be in a list of blocks. This makes it a bit harder to work out the max message size (and meet it)

## Findings

### Request failed successfully or "Unexpected Errors"
If you try to send too many slackmojis in a message, you'll get a 200 and a response of `{"ok":false,"error":"msg_blocks_too_long"}` which is frustrating. At least give me a `400` error!

This error has the wonderful explanation in the [docs](https://api.slack.com/methods/chat.postMessage#errors).
```msg_blocks_too_long [hidden]	msg blocks too long (generated)```

Slack support were lovely, but essentially wondering why would I do such a thing, and suggested I just don't send as many emojis 😔

### Max length != max length
The number of slackmojis you can send seems to vary, though on what I'm not sure. The message needs to be less than 40k characters long, but it also seems to depend on which slackmoji you want to send. It seems that you can only send about half as many animated slackmojis... Which seems to be for the best given how slow the client gets when you send 5 messages, each with ~20k animated slackmojis.


## TLDR
You should put sensible limits and validation on your API requests (+1 Slack) and document them (-1 Slack)

Why? Someone will try to push them at some point, and it's not always someone wanting to have a bit of innocent fun in a slack thread...

Here's a video of the laggy aftermath

<video width="720" controls>
  <source src="/assets/2021-08-05-always-document-api-limitations/laggy-rendering.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>


## Sample code
Please only use this for innocent fun, where you have permission as it can really slow a slack client if it has to render too many slackmojis.

This is provided under an [MIT license](https://github.com/git/git-scm.com/blob/main/MIT-LICENSE.txt) and I hold no responsibility for how you choose to use it.

```python
import http.client, urllib.parse

# Replace
# TOKEN with your bearer token like xoxc-
# COOKIE with your browser cookies, you can get this from the network tab
# CHANNEL with the channel, something like DD95R8TDY, it'll be the second level in your browser ie $2 in https://app.slack.com/client/$1/$2

# If you want to reply to a thread replace
# THREAD with the thread_ts from inspecting the URL of the thread it'll be the fourth level in your browser ie $3 in  https://app.slack.com/client/$1/$2/thread/$2-$3
# otherwise remove "thread_ts": "THREAD",

conn = http.client.HTTPSConnection("slack.com")

headers = { "Content-type": "application/json; charset=utf-8", "Authorization": "Bearer TOKEN", "cookie": "COOKIE"}

extrathonk = ',{"type":"emoji","name":"thonking-intensifies"},' * ((40600 - len('{"type":"emoji","name":"thonking-intensifies"}') - len(',{"type":"emoji","name":"thonking-intensifies"}') ) // len(',{"type":"emoji","name":"thonking-intensifies"},')) + ',{"type":"emoji","name":"thonking-intensifies"}'
body = '{"channel": "CHANNEL", "thread_ts": "THREAD",  "blocks": [{"type":"rich_text","elements":[{"type":"rich_text_section","elements":[{"type":"text","text":"‎"}, %s]}]}]}' % extrathonk
body = body.encode('utf-8')

conn.request("POST", "/api/chat.postMessage", body=body, headers=headers)

response = conn.getresponse()

# response.reason Required as Slack will return a 200, even if your message fails due to "msg_blocks_too_long".
print(response.status, response.reason)

```

