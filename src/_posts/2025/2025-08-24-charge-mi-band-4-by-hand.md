---
layout: post
title: "Charge a Mi Band 4 by hand"
date: 2025-08-24 13:00:00 -0000
categories: [Hardware, Nonsense]
---

# Charge a Mi Band 4 by hand

You're on holiday, and forgot to charge your smartwatch before you left. You also forgot your charger. Now what?

You've tried to source a spare charger but the watch is so old, that you can only get the replacement from China and that won't arrive until you leave.

You've two options

- Do without, and wait until you return home to charge it
- Jerry-rig it

## Disclaimer

I did this for fun, and accepted I might break my watch. I offer no guarantees that this will work - and every expectation it might break your watch.

On your head be it! I accept no responsibility for anything that happens from reading/following this guide!

## Jerry-rigging it

The charger just passes 5V to the watch. There doesn't appear to be any active circuitry in it. Given this, if we know the polarity we can just directly connect 5V

### Polarity

Below is some ascii art of the _bottom_ of the watch
From my testing, the right contact (in this orientation) is where +5V should go, and the left contact (in this orientation) is where the 0V should go

```
    _______
    |     |
    |  _  |
    | | | |
    | |_| |
    |     |
0V  | o o | +5V
    |_____|
```

### What should I use for the charger ports?

Cut the end of an old USB cable, and use the positive/neutral wires... Or in my case use an old PSP charger I found, and put wires in to it to get the 5V/0 since it's labeled nicely.

### How do I hold the wires in place?

Manually, I'm sure there's a better way to do it. I didn't find one with what I had available.
