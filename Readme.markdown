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

Usage
-----

DTCoreText needs a minimum iOS deployment target of 4.3 because of:

- NSCache
- GCD-based threading and locking
- Blocks
- ARC

These are your options for adding DTCoreText to your project.

1. Copy all classes and headers from the Core/Source folder to your project.
2. Link your project against the libDTCoreText static library. Note that the "Static Library" target does not produce a universal library. You will also need to add all header files contained in the Core/Source folder to your project.
3. Link your project against the universal static library produced from the "Static Framework". 

When linking you need to add the -ObjC and -all_load to your app target's "Other Linker Flags". If your app does not use ARC yet (but DTCoreText does) then you also need the -fobjc-arc linker flag.

When building from source it is recommended that you at the ALLOW_IPHONE_SPECIAL_CASES define to your PCH, this setting is "baked into" the library and framework targets.

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

If you find an issue then you are welcome to fix it and contribute your fix via a GitHub pull request.
