Known Issues
============

### DTCoreText Problems

CoreText has a problem prior to iOS 5 where it takes around a second on device to initialize its internal font lookup table. You have two workarounds available:

- trigger the loading on a background thread like shown in [here](http://www.cocoanetics.com/2011/04/coretext-loading-performance/)
- if you only use certain fonts then add the variants to the DTCoreTextFontOverrides.plist, this speeds up the finding of a specific font face from the font family

Some combinations of fonts and unusual list types cause an extra space to appear. e.g. 20 px Courier + Circle

### Differences between Apple and DTCoreText

In many aspects DTCoreText is superior to the Mac version of generating NSAttributedStrings from HTML. These become apparent in the MacUnitTest where the output from both is directly compared. I am summarizing them here for references.

In the following "Mac" means the initWithHTML: methods there, "DTCoreText" means DTCoreText's initWithHTML and/or <DTHTMLAttributedStringBuilder>.

- Mac does not support the video tag, DTCoreText does.
- DTCoreText is able to synthesize small caps by putting all characters in upper case and using a second smaller font for lowercase characters.
- I suspect that Mac makes use of the -webkit-margin-* CSS styles for spacing the paragraphs, DTCoreText only uses the -webkit-margin-bottom and margin-bottom at present.
- Mac supports CSS following addresses, e.g. "ul ul" to change the list style for stacked lists. DTCoreText does not support that and so list bullets stay the same for multiple levels.
- Mac outputs newlines in PRE tags as \n, iOS replaces these with Unicode Line Feed characters so that the paragraph spacing is applied at the end of the PRE tag, not after each line. (iOS wraps code lines when layouting)
- Mac does not properly encode a double list start. iOS prints the empty list prefix.
- Mac seems to ignore list-style-position:outside, iOS does the right thing.

### Using NS-Style Attributes

You can have DTCoreText produce iOS 6-compatible output. This only covers the functionality that is supported by this platform.

- Support for changing the line height is broken in iOS 6. As soon as you have more than one font in the attributed string the minimum and maximum line height attributes of the paragraph style are being ignored.
- Hyperlinks are not supported. UITextView does not have the NSLink attribute Mac has and there is no delegate protocol to deal with clicking on links.
- Since there is no way to reserve extra space on a glyph there is no way to display custom views or inline images
- Horizontal Rule (hr) is not supported.
- Native lists and text boxes are private to NSParagraphStyle
- The tab stops list is also private in NSParagraphStyle, lists only work by using the first standard tab stop as list indent. This causes additional space to be between the list prefix and the text.

You should only use iOS 6 compatible tags if you are targetting UIKit views.

### Differences between UITextView/UIWebView and DTCoreText

There are also some notable differences between display of an attributed string via DTCoreText versus UITextView or UIWebView (UIKit).

- UIKit always draws a 1 px line for underline and strike-out text, DTCoreText gets the line thickness and position from the CTFont and draws.
- UIKit does not support multiple shadows, DTCoreText does
- UIKit does not support kerning, DTCoreText always kerns
- UIKit does not support embedded text attachments (e.g. images), DTCoreText does

If you find an issue then you are welcome to fix it and contribute your fix via a GitHub pull request.
