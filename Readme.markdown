# NSAttributedString HTML Additions

This project aims to duplicate the methods present on Mac OSX which allow creation of `NSAttributedString` from HTML code on iOS.

This is useful for drawing simple rich text like any HTML document without having to use a `UIWebView`.

Please read the [Q&A](http://www.cocoanetics.com/2011/08/nsattributedstringhtml-qa/).

Your help is much appreciated. Please send pull requests for useful additions you make or ask me what work is required.

If you find brief test cases where the created `NSAttributedString` differs from the version on OSX please send them to us!

Follow [@cocoanetics](http://twitter.com/cocoanetics) on Twitter.


KNOWN ISSUES

CoreText has a problem prior to iOS 5 where it takes around a second on device to initialize its internal font lookup table. You have two workarounds available:

- trigger the loading on a background thread like shown in http://www.cocoanetics.com/2011/04/coretext-loading-performance/
- if you only use certain fonts then add the variants to the DTCoreTextFontOverrides.plist, this speeds up the finding of a specific font face from the font family
