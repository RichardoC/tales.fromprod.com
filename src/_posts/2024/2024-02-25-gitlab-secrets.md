---
layout: post
title:  "Finding secrets on GitLab"
date:   2024-02-25 11:00:00 -0000
categories: [APIs, git]
---
# Finding secrets on GitLab

Everyone's been there before, you included something you shouldn't have in a commit so you undo the commit and force push.

This data's gone, right?(!)

This blog post is about finding those mistakenly published commits, and to serve as a reminder that you should always rotate potentially exposed credentials even if you think you've deleted them.


## How can these "missing commits" still exist?

When you force pushed your branch you rewrote the branch history to no longer reference those commits. This doesn't remove those commits though, it just detached them from the chain of commits that represents the branch.  commits still exist on the GitLab server despite being inaccessible via the branches.

Here's a writeup of how this works [locally](https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery)


## How do we find these missing commits

In theory GitLab have an API for getting commits from a repository, and there's a parameter for getting `all` commits.

As of the time of writing, this API fails to return these dangling commits <https://gitlab.com/gitlab-org/gitlab/-/issues/443263> which I consider a bug.

However, every time a commit is pushed a `pushed to` [event](https://docs.gitlab.com/ee/api/events.html) is generated by GitLab. An example of this is below.

```json
{
    "id": 3182909502,
    "project_id": 55263882,
    "action_name": "pushed to",
    "target_id": null,
    "target_iid": null,
    "target_type": null,
    "author_id": 20255114,
    "target_title": null,
    "created_at": "2024-02-24T21:29:08.711Z",
    "author": {
      "id": 20255114,
      "username": "RichardoC",
      "name": "Richard Tweed",
      "state": "active",
      "locked": false,
      "avatar_url": "https://secure.gravatar.com/avatar/3af3c4bc67b146186dbd2ef852f8faa16c91d9268e81b7b292168e7dc1fdc7b6?s=80&d=identicon",
      "web_url": "https://gitlab.com/RichardoC"
    },
    "push_data": {
      "commit_count": 1,
      "action": "pushed",
      "ref_type": "branch",
      "commit_from": "31ed8bb6dd627bd38fba1aa350a15136c636c932",
      "commit_to": "7faedfa06dd7dda69ca94169c9ec01aa605da08b",
      "ref": "main",
      "commit_title": "Tidy readme",
      "ref_count": null
    },
    "author_username": "RichardoC"
}
```

These events reference the `commit_from` and `commit_to` commits. These can be used to generate a set of all commits that actually happened over the last 3 years (they're only retained for 3 years)

By comparing that set with the official history (the all commits API above) we can find dangling commits, and generate the URL where they can be seen.


## Very cool, where's the code?

<https://github.com/RichardoC/gitlab-secrets>

An example Gitlab repo with dangling commits can be found at <https://gitlab.com/gitlab-secrets/gitlab-secrets> for you to test this out with


## Original idea

This was based on the work by Neodyme where they used this technique to find secrets on [GitHub](https://neodyme.io/en/blog/github_secrets/)