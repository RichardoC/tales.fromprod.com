---
layout: post
title:  "How Slack and Discord prevent you scanning Infrastructure with link previews"
date:   2021-08-11 19:00:00
categories: [Slack, APIs,  Discord, Security]
---
# How Slack and Discord prevent you scanning Infrastructure with link previews


**NOTE**
This is based on conjecture for Discord, and reading some Slack docs. This is not based on statements from them.


## Why should I care about these nice previews?
They're running an HTTP GET from some machine somewhere, and then presenting some returned data from any source in a webpage... Sounds ripe for stored XSS/SSRF/recon/general shenanigans, doesn't it? [1](https://elbs.medium.com/1-000-ssrf-in-slack-7737935d3884),[2](https://hackerone.com/reports/381129
),[3](https://hackerone.com/reports/61312
),[4](https://gitlab.com/gitlab-org/gitlab/-/issues/28487)

## How they prevent you scanning the network around the receiver

They do the link loading server side, and then cache it for all clients [[5](https://api.slack.com/robots#link-expanding)]. This means the network calls come from the service servers, not the receiver which rules this out, phew!

This is different to client side link loading (which is a *bad* idea, see [part 3](https://www.perimeterx.com/tech-blog/2020/whatsapp-fs-read-vuln-disclosure/))

## How do they prevent you scanning their own infra?
Say for example they are on AWS, you can get their servers to run any GET commands you want, even to the [AWS metadata service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) which can be used for [kill chains](https://www.shellntel.com/blog/2019/8/27/aws-metadata-endpoint-how-to-not-get-pwned-like-capital-one). That sounds fun right? (Not actually, please don't do this without permission)

So, why doesn't this matter? They only return the information they found in specific tags [5](https://api.slack.com/robots#link-expanding) which rules out (probably) every interesting internal API, so you can run a GET but never get the information back.

They may also be running a deny-list but these are never perfect.

## How do they stop you injecting random code into the page
Same protections as when you send a message, [Content Security Policies](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) and setting context using [innerHTML](https://developer.mozilla.org/en-US/docs/Web/API/Element/innerHTML#security_considerations) (in the case of Discord.)

## TLDR
They don't run the preview HTTP requests from your machine, and only provide a well documented but uncommon (for infrastructure) set of tags.

