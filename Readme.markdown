DTCoreText
==========

This project aims to duplicate the methods present on Mac OSX which allow creation of `NSAttributedString` from HTML code on iOS. Previously we referred to it as NSAttributedString+HTML (or NSAS+HTML in short) but this only covers about half of what this framework does. 

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

DTRichText needs a minimum iOS deployment target of 4.3 because of:

- NSCache
- GCD-based threading and locking
- Blocks

These are your options for adding DTCoreText to your project.

1. Copy all classes and headers from the Core/Source folder to your project.
2. Link your project against the libDTCoreText static library. Note that the "Static Library" target does not produce a universal library. You will also need to add all header files contained in the Core/Source folder to your project.
3. Link your project against the universal static library produced from the "Static Framework". 

When linking you need to add the -ObjC and -all_load to your app target's "Other Linker Flags".

When building from source it is recommended that you at the ALLOW_IPHONE_SPECIAL_CASES define to your PCH, this setting is "baked into" the library and framework targets.

Known Issues
------------

CoreText has a problem prior to iOS 5 where it takes around a second on device to initialize its internal font lookup table. You have two workarounds available:

- trigger the loading on a background thread like shown in http://www.cocoanetics.com/2011/04/coretext-loading-performance/
- if you only use certain fonts then add the variants to the DTCoreTextFontOverrides.plist, this speeds up the finding of a specific font face from the font family

Some combinations of fonts and unusual list types cause an extra space to appear. e.g. 20 px Courier + Circle

If you find an issue then you are welcome to fix it and contribute your fix via a GitHub pull request.
