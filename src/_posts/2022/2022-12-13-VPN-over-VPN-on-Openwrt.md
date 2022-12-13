---
layout: post
title:  "VPN over VPN on OpenWrt"
date:   2022-12-13 19:00:00
categories: [OpenWrt, VPN, WireGuard]
---

# VPN over VPN on Openwrt on one device

OpenWrt has reasonable [guides](https://openwrt.org/docs/guide-user/services/vpn/wireguard/client) on using your router as a WireGuard client but it's missing a how to on running VPN over VPN. This article will close that gap

## Why run VPN over VPN?

This guide exists because a certain UK ISP has terrible peering with another continent. A mitigation for this issue was to send traffic first to a UK VPN server with much better peering connections, and then send the actual VPN traffic to that other continent to appear there for the "first time"


### Terminology

* OuterVPN - innervpn.example.com - The VPN closest to you, that you're using to take advantage of the better peering. The traffic exiting here is for the second VPN server.
* InnerVPN - outervpn.example.com - The VPN on another continent. The traffic existing here is the normal traffic you wanted to go over a VPN.

### Why do VPN over VPN on one device?

VPN over VPN is most commonly done by having one device do the connection to Outer VPN, and another (having the lan of the first device as its WAN) do the connection do the connection to InnerVPN. This is common because most routers are fairly slow and doing VPN over VPN slows the network performance too much. It's also simpler to configure and debug.

However, there are now reasonably powerful devices like the Raspberry Pi 4 which can do this VPN over VPN (WireGuard) and achieve > 200Mb/s. This means rather than needing so many devices you can do it all on one and only have to maintain one device.

## How to set up the initial WireGuard connection?

Follow this guide from [azirevpn](https://www.azirevpn.com/support/guides/router/openwrt/wireguard) as it's one of the better ones.

## Now I have my inital connection, how to do I do VPN over VPN?

Assuming you have your Wireguard.conf file, you can follow that guide again but naming the new interface differently. Then, you should obtain the IP address of the InnerVPN server. These can be obtained via the following

``` bash
$ dig outervpn.example.com

; <<>> DiG 9.18.1-1ubuntu1.2-Ubuntu <<>> outervpn.example.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 49846
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;vpn.example.com.	IN	A

;; ANSWER SECTION:
outervpn.example.com. 60 IN	A	192.0.2.240
outervpn.example.com. 60 IN	A	192.0.0.240

;; Query time: 32 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Tue Dec 13 18:56:44 GMT 2022
;; MSG SIZE  rcvd: 89
```

Once you have the IP addresses, you should edit the `Allowed IPs` of the peer of OuterVPN to remove `0.0.0.0/0` and add the IPs obtained via the DNS lookup, each suffixed with `/32`

Hit Save and Save and Apply, and you should be in business.

You can confirm this is working as expected by pinging the `innervpn.example.com` and seeing that this has a faster response than pinging `outervpn.example.com` and that both of these are faster than pinging a random server. If this isn't true, something's configured wrong.

## Why does this work?

Routers send traffic to the most specific route in their routing table, and then fall back to their default route.

In the configuration above, we have a `/32` (exact IP address) route for the `outervpn.example.com` IPs, which is over the OuterVPN tunnel.

For your normal traffic, it will go over the `0.0.0.0/0` route which goes over the InnerVPN tunnel.

Your traffic to `innervpn.example.com` will go via the default route and out over your normal internet.

## Gotchas

* `Route Allowed IPs` is actually in the `Peer Configuration` of the WireGuard interface settings on Luci rather than the interface itself. This must be set to true for the routes to be created properly
* `MTU` being misconfigured on each interface is a common reason for slowdowns/random latency. Ensure that the MTU of your first tunnel is at most (line MTU - 80) and the second tunnel is at most (first tunnel MTU - 80). 80 obtained from [here](https://projectcalico.docs.tigera.io/networking/mtu#determine-mtu-size). This is particularly relevant as WireGuard sets the `Don't Fragment` bit on its packets, which can cause high packetloss.
