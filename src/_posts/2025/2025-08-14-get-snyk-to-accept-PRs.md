---
layout: post
title: "Get Snyk Code to accept PRs"
date: 2025-08-14 12:00:00 -0000
categories: [Security]
---

# Get Snyk Code to accept PRs

Sometimes you need to merge a PR that uses an HTTP server for a test, and Snyk code is configured to block you. Here's a bad way to convince Snyk "no really, this one is fine" in a way that robs your reviewer of making an informed choice about whether to accept the vulnerability.

## How to make ignore specific issues via .snyk?

Tough luck, you can't. You can _only_ ignore files, not snyk code findings. <https://docs.snyk.io/manage-risk/prioritize-issues-for-fixing/ignore-issues/exclude-files-and-ignore-issues-faqs#how-do-i-ignore-issues-and-vulnerabilities-in-code-sast-scans>

```yaml
# Snyk (https://snyk.io) policy file, patches or ignores known vulnerabilities.
# unhelpful docs about this file format at https://docs.snyk.io/manage-risk/policies/the-.snyk-file#syntax-of-the-.snyk-file
version: v1.25.1
ignore: {} # Can't be used as snyk don't support snyk code findings here
patch: {}
exclude:
  global:
    - scripts/bad-code.py # You just have to hope there are no other issues in this file
```

## Another bad alternative

An admin can open the failed Snyk PR check, and click the "Mark as successful in SCM" button. If anything changes in the PR, any issues will be re-detected and an admin will have to click the button _again_
