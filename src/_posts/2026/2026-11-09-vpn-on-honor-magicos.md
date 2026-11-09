---
layout: post
title: "Working, always on, VPN on Honor MagicOS"
date: 2026-11-09 19:00:00 -0000
categories: [VPN, Android]
---

# Working, always on, VPN on Honor MagicOS

## Why?

Ad blocking

## What issues happen by default?

If you're using "Always-on VPN" and "Only allow connections through VPN" - then the default MagicOS will kill off the VPN in the background to save power, and you won't be able to do anything on the internet until you open up the VPN app again.

## How to fix it

- Open Settings -> Apps -> Manage apps -> ${VPN app name} -> Power usage details -> Launch Settings
Then
- turn off "Manage automatically"
- turn on "Auto-launch"
- turn on "Secondary launch"
- turn on "Run in background"

** THEN **

- Open the app switcher (swipe up from the bottom of the screen with gesture controls) 
- Swipe down on the app window of ${VPN app name}, there hould now be a padlock on the level of the app name, to the top right

Only after all of this, will it stop killing off the damn vpn app.


Tested on MagicOS 10.0