---
layout: post
title: "Minimal cloudflared permissions, for a ngrok alternative"
date: 2026-04-01 10:00:00 -0000
categories: [APIs, Cloudflare, Security]
---

# Minimal cloudflared permissions, for a ngrok alternative

Cloudflare have a product (sometimes) called [cloudflared](https://github.com/cloudflare/cloudflared) which can be used as an ngrok alternative. I wanted to enable developers to use this, but give them the minimal permissions and only allow it to be used with a specific domain.

After reading hundreds of pages of documentation, and spending hours with their support - finally I found the minimum set required, which can be added to a Cloudflare Member Group's permission policy.

Sorry about the lack of details, but cloudflare weren't very specific on why each bit is required

## Account level permissions

- Cloudflare One Connector Read and Monitor: cloudflared; Required so the cli can see if the tunnel is working
- Cloudflare Gateway; Required to actually configure the tunnel
- Cloudflare Zero Trust; Required to actually configure the tunnel
- Load Balancer; Required to actually configure the tunnel
- Cloudflare Access; Required to actually configure the tunnel

## Zone level permissions (scope to the relevant domain)

- Zone Versioning Read; Required so the cli can see current DNS records
- Domain DNS; Required so the cli can create and update records, to allow traffic to actually get to the tunnel
