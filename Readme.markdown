DTCoreText
==========

This project aims to duplicate the methods present on Mac OSX which allow creation of `NSAttributedString` from HTML code on iOS. Previously we referred to it as NSAttributedString+HTML (or NSAS+HTML in short) but this only covers about half of what this framework does. 

Please support us so that we can continue to make DTCoreText even more awesome!

<a href='http://www.pledgie.com/campaigns/16615'><img alt='Click here to lend your support to: Migrate DTCoreText to libxml2 and make a donation at www.pledgie.com !' src='http://www.pledgie.com/campaigns/16615.png?skin_name=chrome' border='0' /></a>

The project covers two broad areas:

1. Layouting - Interfacing with CoreText, generating NSAttributedString instances from HTML code
2. UI - several UI-related classes render these objects

This is useful for drawing simple rich text like any HTML document without having to use a `UIWebView`.

Please read the [Q&A](http://www.cocoanetics.com/2011/08/nsattributedstringhtml-qa/).

Your help is much appreciated. Please send pull requests for useful additions you make or ask me what work is required.

If you find brief test cases where the created `NSAttributedString` differs from the version on OSX please send them to us!

Follow [@cocoanetics](http://twitter.com/cocoanetics) on Twitter.

License
-------

It is open source and covered by a standard BSD license. That means you have to mention *Cocoanetics* as the original author of this code. You can purchase a Non-Attribution-License from us.

Documentation
-------------

Documentation can be [browsed online](http://cocoanetics.github.com/DTCoreText) or installed in your Xcode Organizer via the [Atom Feed URL](http://cocoanetics.github.com/DTCoreText/DTCoreText.atom).

Usage
-----

DTCoreText needs a minimum iOS deployment target of 4.3 because of:

- NSCache
- GCD-based threading and locking
- Blocks
- ARC

The best way to use DTCoreText with Xcode 4.2 is to add it in Xcode as a subproject of your project with the following steps.

1. Download DTCoreText as a subfolder of your project folder
2. Open the destination project and drag `DTCoreText.xcodeproj` as a subordinate item in the Project Navigator
3. In your prefix.pch file add:
	
		#import "DTCoreText.h"

4. In your application target's Build Phases add all of the below to the Link Binary With Libraries phase (you can also do this from the Target's Summary view in the Linked Frameworks and Libraries):

		The "Static Library" target from the DTCoreText sub-project
		ImageIO.framework
		QuartzCore.framework
		libxml2.dylib

5. Go to File: Project Settings… and change the derived data location to project-relative.
6. Add the DerivedData folder to your git ignore. 
6. In your application's target Build Settings set the "User Header Search Paths" to the directory containing your project with recrusive set to YES. Set the Header Search Paths to `/usr/include/libxml2`. Set "Always Search User Paths" to YES.

If you do not want to deal with Git submodules simply add DTCoreText to your project's git ignore file and pull updates to DTCoreText as its own independent Git repository. Otherwise you are free to add DTCoreText as a submodule.

*You also have these other installation options instead:*

- Copy all classes and headers from the Core/Source folder to your project.
- Link your project against the libDTCoreText static library. Note that the "Static Library" target does not produce a universal library. You will also need to add all header files contained in the Core/Source folder to your project.
- Link your project against the universal static library produced from the "Static Framework". 

When linking you need` to add the -ObjC and -all_load to your app target's "Other Linker Flags". If your app does not use ARC yet (but DTCoreText does) then you also need the -fobjc-arc linker flag.

The project has been changed to use libxml2 for parsing HTML, so you need to link in the libxml2.dylib, and, if you're copying all files from Core/Source, you must add the path "/usr/include/libxml2" to your header search paths as well.

Known Issues
------------

CoreText has a problem prior to iOS 5 where it takes around a second on device to initialize its internal font lookup table. You have two workarounds available:

- trigger the loading on a background thread like shown in http://www.cocoanetics.com/2011/04/coretext-loading-performance/
- if you only use certain fonts then add the variants to the DTCoreTextFontOverrides.plist, this speeds up the finding of a specific font face from the font family

Some combinations of fonts and unusual list types cause an extra space to appear. e.g. 20 px Courier + Circle

In many aspects DTCoreText is superior to the Mac version of generating NSAttributedStrings from HTML. These become apparent in the MacUnitTest where the output from both is directly compared. I am summarizing them here for references.

In the following "Mac" means the initWithHTML: methods there, "DTCoreText" means DTCoreText's initWithHTML and/or DTHTMLAttributedStringBuilder.

- Mac does not support the video tag, DTCoreText does.
- DTCoreText is able to synthesize small caps by putting all characters in upper case and using a second smaller font for lowercase characters.
- I suspect that Mac makes use of the -webkit-margin-* CSS styles for spacing the paragraphs, DTCoreText only uses the -webkit-margin-bottom and margin-bottom at present.
- Mac supports CSS following addresses, e.g. "ul ul" to change the list style for stacked lists. DTCoreText does not support that and so list bullets stay the same for multiple levels.
- Mac outputs newlines in PRE tags as \n, iOS replaces these with Unicode Line Feed characters so that the paragraph spacing is applied at the end of the PRE tag, not after each line. (iOS wraps code lines when layouting)
- Mac does not properly encode a double list start. iOS prints the empty list prefix.
- Mac seems to ignore list-style-position:outside, iOS does the right thing.

If you find an issue then you are welcome to fix it and contribute your fix via a GitHub pull request.
