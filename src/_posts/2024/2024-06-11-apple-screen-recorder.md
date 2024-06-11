---
layout: post
title:  "Recording what you see on macOS - no external dependencies"
date:   2024-06-11 19:00:00 -0000
categories: [macOS, APIs,  Machine Learning]
---
# Recording what you see on macOS - no external dependencies

Without installing **anything** you can automatically record all text shown on screen on macOS and do whatever you want on it.

This is published for informational purposes, and to illustrate how difficult "data loss prevention" is, when the very OS you're using is working against you.

I wish I'd published this before the whole [Windows Recall thing](https://support.microsoft.com/en-gb/windows/retrace-your-steps-with-recall-aa03f8a0-a78b-4b3e-b0a1-2eb8ac48701c) but hindsight is 20/20.

## AppleScript

Built in to macOS is `script editor` and `automator` which can use a proprietary scripting language called `AppleScript` which can be used to do everything a mac or iOS app can do, with a few extra niceties. In my opinion it's very ugly and hard to use as it tries to act like natural prose rather than be an actual compute  language. One example is using `class's method` rather than class.method.

The [documentation](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/introduction/ASLR_intro.html) is very out of date, though it still works so you'll have to find information on [forums.](https://www.macscripter.net)

## So what?

- Open spotlight
- Open "script editor"
- Paste the code below in the window and save it
- Click "Run this script" button which looks like a play button
- See that all text on your screen is now in the script output window.

Congratulations, without installing *anything* you've managed to make something which can recover all text that shows on your macOS display.

Apple don't give you a way to disable AppleScript so I'm not aware of a way to prevent this functionality.


### Sample code

Please only use this for innocent fun, where you have permission.

This snippet is provided under an [MIT license](https://github.com/git/git-scm.com/blob/main/MIT-LICENSE.txt) and I hold no responsibility for how you choose to use it.

```applescript

use framework "AppKit"
use framework "Foundation"
use framework "Vision"
use scripting additions



-- based on https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/ReadandWriteFiles.html
on writeTextToFile(theText, theFile, overwriteExistingContent)
	try

		-- Convert the file to a string
		set theFile to theFile as string

		-- Open the file for writing
		set theOpenedFile to open for access file theFile with write permission

		-- Clear the file if content should be overwritten
		if overwriteExistingContent is true then set eof of theOpenedFile to 0

		-- Write the new content to the file
		write theText to theOpenedFile starting at eof

		-- Close the file
		close access theOpenedFile

		-- Return a boolean indicating that writing was successful
		return true

		-- Handle a write error
	on error

		-- Close the file
		try
			close access file theFile
		end try

		-- Return a boolean indicating that writing failed
		return false
	end try
end writeTextToFile

-- based on https://www.macscripter.net/t/image-png-to-text-through-applescript/74490/6
on getScreenText()
	do shell script "screencapture -c "
	set thePasteboard to current application's NSPasteboard's generalPasteboard()
	set imageData to thePasteboard's dataForType:(current application's NSPasteboardTypeTIFF)
	set requestHandler to current application's VNImageRequestHandler's alloc()'s initWithData:imageData options:(current application's NSDictionary's alloc()'s init())
	set theRequest to current application's VNRecognizeTextRequest's alloc()'s init()
	requestHandler's performRequests:(current application's NSArray's arrayWithObject:(theRequest)) |error|:(missing value)
	set theResults to theRequest's results()
	set theText to {}
	repeat with observation in theResults
		copy ((first item in (observation's topCandidates:1))'s |string|() as text) to end of theText
	end repeat
	return theText
end getScreenText

on run (argv)
	getScreenText()
end run
```

## Limitations

This version does not continue to run, nor write the captured text to a file or send it to a server so isn't currently much use for much more than a proof of concept.

This version doesn't work in automator for reasons I don't understand, so you can't easily trigger it from a key press.

It uses `screencapture` by shelling out, so this is quite easy to detect. I'm sure there are ways to do a screenshot more directly which would avoid this obvious detection. This can probably be avoided by using [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit/scshareablecontent/3916733-getshareablecontentwithcompletio?language=objc) but I couldn't work out the syntax in AppleScript.
