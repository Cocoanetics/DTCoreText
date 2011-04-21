# NSAttributedString HTML Additions

This project aims to duplicate the methods present on Mac OSX which allow creation of `NSAttributedString` from HTML code on iOS.

This is useful for drawing simple rich text like any HTML document without having to use a `UIWebView`.

## Features

At present the following tags are supported:

* Headers H1 - H6
* Paragraphs: P
* Bold: B, STRONG
* Italic: I, EM
* Underline: U
* Superscript: SUP
* Subscript: SUB, e.g. e = mc<sup>2</sup>
* Styling: FONT (face and color, not size). It would be great if we could support many more styles
* Unordered Lists: UL, LI
* Ordered Lists: OL, LI

Currently attributes are inherited by enclosed tags via 'brute force'. I don't know if this is accurate.

## To Do

### NSAttributedString+HTML

* Decode HTML Entities
* A HREF tags, to format links
* More styles, as far as supported by CoreText

### DTAttributedTextView

* Caret Positioning
* Hit Detection on strings attributed with HREF
* Text Insertion
* Editing!

There is still quite a few more things to do on the project. DEL, possibly CSS styles as they related to fonts and text formatting.

## Please Help!

If you find brief test cases where the created `NSAttributedString` differs from the version on OSX please send them to us!

Follow [@cocoanetics](http://twitter.com/cocoanetics) on Twitter.
