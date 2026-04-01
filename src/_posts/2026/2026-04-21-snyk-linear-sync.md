---
layout: post
title: "Snyk issues in linear"
date: 2026-04-01 11:00:00 -0000
categories: [APIs, Security]
---

# Snyk issues in linear

At the time of writing (2025-04-01) Snyk doesn't support syncing found issues into [Linear](https://linear.app/), , only [Jira](https://docs.snyk.io/integrations/jira-and-slack-integrations/jira-integration) so I decided to make a cli to do this automatically.

## Requirements

- Uses the snyk priorities, and maps them on to due dates based on our compliance SLAs
- auto-close issues when Snyk detects the issue is fixed
- unsubscribes the sync user, so they don't get thousands of notifications
- Caching where possible, to reduce the odds of rate limiting
- simple to install/run (just `go run` from github)
- headless-first, aka you can run it to completion in a cronjob somewhere without needing manual intervention
- Label issues with the snyk tool, and an overarching label (all configurable) to enable clearer dashboards

### Show me

All of this, and more is implemented in <https://github.com/RichardoC/snyk-linear-sync> so give it a go
