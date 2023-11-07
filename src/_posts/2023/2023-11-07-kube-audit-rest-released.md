---
layout: post
title:  "kube-audit-rest officially released as 1.0.0"
date:   2023-06-26 20:00:00 -0000
categories: [Kubernetes, auditing, cost-reduction, public-releases]
---
# kube-audit-rest officially released as 1.0.0

After almost a year, I'm happy to announce [kube-audit-rest](https://github.com/RichardoC/kube-audit-rest/tree/main) is ready for use by anyone who wants to give it a go.

It's an API call logger, for use for auditing mutation/creation API requests to Kubernetes where you cannot control the kube-api-server. These can be ingested into your chosen Security information and event management (SIEM) system.

## How can I play with it?

Try following the [demo](https://github.com/RichardoC/kube-audit-rest/tree/main/examples/full-elastic-stack) with elastic search to get a feel for the capabilities and read the [README](https://github.com/RichardoC/kube-audit-rest/tree/main) which documents the functionality.

## Backstory

While stuck on a train I decided to reduce our considerable Kubernetes auditing cost. At the time we were paying thousands a year per cluster, and we'd a lot of clusters.

The reasons for this high cost was
- You can only turn on/off audit logging, rather than opt in to the events you want
- They're ingested into the cloud vendor's logging solution, which we don't use and thus has to extract paying both the high ingestion and extraction costs
- Our clusters are rather "busy"

After some thinking I realised that we could use [Kubernetes Dynamic Admission Control](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) to get a webhook on [every*](https://github.com/RichardoC/kube-audit-rest#known-limitations-and-warnings) API call I wanted to listen to, rather than having to listen to all of them and directly send these to a log store that I wanted to use.

## How can I be sure this is safe to use?

[Trivy](https://aquasecurity.github.io/trivy/) is run on every pull request, commit and nightly to check for vulnerable libraries.

[renovate](https://github.com/renovatebot/renovate) is configured to automatically raise PRs for any library or container image updates

[distroless containers] are available and recommended for production usage, to reduce the attack surface

[Open source] - all the code is avaiable for you to audit and rebuild yourself if required.

[no egress traffic] - the kube-audit-rest container makes no outbound connections so can be fully isolated if required
