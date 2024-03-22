---
layout: post
title:  "Using a video as a Google Meet background"
date:   2024-03-22 20:00:00 -0000
categories: [Google,  Nonsense]
---
# Using a video as a Google Meet background

**Warning**
This is not officially supported by Google, and could be considered against their [terms of service (specifically "System interference")](https://support.google.com/meet/answer/9847091) so follow this guide at your own risk.

**I accept no responsibility for how anyone chooses to use this. As always - Don't be a pain**


## Requirements

* An mp4 video which you have the rights to use
* A browser where you can edit a page's HTML
* Some patience

## Guide

- Join a Google Meet call
- click the menu (three vertical dots)
- select Apply visual effects
- Use inspector on the `Add your own personal background` button
- You should then see something like `<input type="file" jsname="tif8Pe" jsaction="change:E7zRc" accept="image/jpeg, image/png, image/webp" style="display: none;">` in the HTML
    - edit this to include `video/mp4`
- Click the `Add your own personal background` button
- Select your mp4 video

Congratulations, you've now set a video as your background

## Dirty javascript hacks to do this

** Warning ** This is GPT generated, run at your own risk

```javascript
// Find the first <input> element with the specific attributes
const inputFile = document.querySelector('input[type="file"][accept*="image/jpeg"], input[type="file"][accept*="image/png"], input[type="file"][accept*="image/webp"]');

if (inputFile) {
    // Get the current accept attribute value
    const currentAcceptValue = inputFile.getAttribute('accept');
    // Check if "video/mp4" is already included, if not, add it
    if (!currentAcceptValue.includes('video/mp4')) {
        inputFile.setAttribute('accept', `${currentAcceptValue}, video/mp4`);
    }
}
```

## Steps to using this javascript

- Join a Google Meet call
- Open the developer console
- paste in that javascript and run it
- Click the `Add your own personal background` button
- Select your mp4 video

Congratulations, you've now set a video as your background

