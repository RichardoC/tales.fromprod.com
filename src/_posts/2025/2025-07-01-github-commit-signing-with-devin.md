---
layout: post
title: "Github commit signing with Devin"
date: 2025-07-01 12:00:00 -0000
categories: [APIs, LLMs]
---

# Github commit signing with Devin

If you're using Github, and want to use Devin with a repo that requires (signed commits)[https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits] then this guide is for you.

It assumes that you've installed Devin as a (Github App)[https://docs.devin.ai/integrations/gh] with write permissions to the relevant repo

## Why should I follow this guide by some person online?

(The Devin guide)[https://docs.devin.ai/integrations/gh#commit-signing] requires

- a separate Github account (which probably needs a company email account) ($)
- Generation of a GPG key, which is added to that Github account ($)
- a Github license for that account, so it can contribute to your repos ($$)
- extensive configuration of the Devin machine for each repo, with that special GPGP key ($$)

My process doesn't.

## I'm sold, how do I do this?

- Set up Devin for a repo as usual
- During "install deps" run `gh extension install kassett/gh-commit` to install the Github cli extension that will make the api calls to make the signed commits
- During `Repo Note` add the following notes, replacing YOUR_USER/YOUR_REPO with the real values

```
When creating a new branch, ensure to mark that it traces a remote branch
e.g.

`git checkout -b feat-123-make-fizzbop && git branch --set-upstream-to=origin/feat-123-make-fizzbop `

When making a commit, use the following commands to make the commit, then pull it down from github. Replace feat-123-make-fizzbop with the real branch name, and the commit message with the desired message. This is required due to github commit signing. If you make commits locally they will *not* be verified and cannot be pushed up.


`export GH_REPO="YOUR_USER/YOUR_REPO" ; gh commit -B feat-123-make-fizzbop -A -m "chore: test commits from Devin"`


If you require assistance with this command, run `gh commit --help` and inspect the output
```

## Why does this work?

Devin's machine has the Github cli installed, and this has the permissions of the github app.
These permissions means that (via the cli) you can ask github to make a commit on your behalf, like the web editor. Github will sign these commits for you by design.

## Useful resources

- The thread that started this all https://github.com/cli/cli/issues/10365#issuecomment-2660677714
- The actual code making this work <https://github.com/kassett/gh-commit>
