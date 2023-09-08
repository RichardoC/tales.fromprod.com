---
categories:
- Jira
- APIs
- Atlassian
date: "2023-06-26T20:00:00Z"
title: Bulk deleting tickets in Jira
---
# Bulk deleting tickets in Jira
For the sake of argument, say your automation developers have a test project for testing their tooling which automatically raises a jira ticket when it finds something a human needs to deal with. This is fantastic, until a few months later when the tooling chnages, and the 10,000s of old tickets are no longer "correct" in the test project.

So, you want to clean up the old tickets, so only the new "valid" tickets exist in this test project.

## Approach 1 - use the bulk edit functionality

Jira has a [bulk edit functionality](https://confluence.atlassian.com/jirasoftwareserver/editing-multiple-issues-at-the-same-time-939938937.html), that can be used for deleting issues. Unfortunately it only allows 1,000 issues at a time but surely running that 10 ish times is fine... right?

### Problem

It takes 12 minutes to delete the 1,000 issues. Sitting here for multiple hours triggering bulk delete through the UI isn't how you want to spend you day.

## Approach 2 - use the APIs

Atlassian have many APIs for Jira, and [reasonable docs](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/#api-rest-api-3-issue-issueidorkey-delete) for them as well!

### The good

* Jira has APIs

### The bad

* Jira doesn't have a [bulk delete API](https://community.developer.atlassian.com/t/jira-rest-api-endpoint-for-bulk-delete-issues/55806)
* Jira won't necessarily give you all matching issues from an issue search API call, depending on how much data is in each issue

### The how

Assuming the following
* Your atlassian cloud instance URL is <https://example.atlassian.net>
* You're using bash on a *nix
* You have issued a JIRA API token from <https://id.atlassian.com/manage-profile/security> and exported it as JIRA_API_TOKEN in your shell
* You've exported your atlassian user email as JIRA_EMAIL
* You have a JQL query that matches the issues you want to delete, and ONLY the issues you want to delete and have exported it (URL encoded) as JIRA_JQL


Example URL encoded JQL is `project%20%3D%20TOY%20AND%20issuetype%20%3D%20Vulnerability%20ORDER%20BY%20created%20DESC` which matches all vulnerabilty issues in a project called TOY

### Final script

OBLIGATORY WARNING - this will delete all issues which match the JQL, and ALL subtasks use with caution!

This script will attempt to delete the issues, with 12 parallel threads. It has zero error handlin or backoff so you are likely to get `429 - Too many requests` and should cancel the script and wait a few minutes before resuming.
During this time your user will be unable to use the Jira webapp as well, as it's your user that gets rate limited, not the API token.

You may also have to rerun this script multiple times if you have more than ~ 10,000 issues, as this doesn't follow any pagination.

```console
curl --request GET \
  --url "https://example.atlassian.net/rest/api/3/search?maxResults=20000&fields=id&jql=$JIRA_JQL"  \
  --user "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  --header 'Accept: application/json' | jq -r '.issues[].id'  | xargs -P12 -I{} bash -c 'curl --request DELETE   --url 'https://example.atlassian.net/rest/api/3/issue/{}?deleteSubtasks=true'  --user "$JIRA_EMAIL:$JIRA_API_TOKEN" && echo "{} completed" || echo "{} failed"'
14054 completed
14050 completed
...
```
