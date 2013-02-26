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

If you find an issue then you are welcome to fix it and contribute your fix via a GitHub pull request.
