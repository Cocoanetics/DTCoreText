DTCoreText
==========

This project aims to duplicate the methods present on Mac OSX which allow creation of `NSAttributedString` from HTML code on iOS. 

The project covers two broad areas:

1. **Layouting** - Interfacing with CoreText, generating attributed strings from HTML code
2. **User Interface** - UI-related classes render these objects, specifically `DTAttributedTextView`, `DTAttributedLabel` and `DTAttributedTextCell`.

This is useful for drawing simple rich text like any HTML document without having to use a `UIWebView`. For text selection and highlighting (as you might need for an Editor or Reader) there is the commercial **DTRichTextEditor** component which can be purchased in the [Cocoanetics Parts Store](http://www.cocoanetics.com/parts/dtrichtexteditor/).

Documentation
-------------

Documentation can be [browsed online](https://docs.cocoanetics.com/DTCoreText) or installed in your Xcode Organizer via the [Atom Feed URL](https://docs.cocoanetics.com/DTCoreText/DTCoreText.atom).

A [Q&A](http://www.cocoanetics.com/2011/08/nsattributedstringhtml-qa/) answers some frequently asked questions.

Follow [@cocoanetics](http://twitter.com/cocoanetics) on Twitter or subscribe to the [Cocoanetics Blog](http://www.cocoanetics.com) for news and updates.

#### Changelog

- [Version 1.5.3](http://www.cocoanetics.com/2013/06/dtcoretext-1-5-3/)
- [Version 1.5.2](http://www.cocoanetics.com/2013/05/dtcoretext-1-5-2/)
- [Version 1.5](http://www.cocoanetics.com/2013/05/rich-text-update-1-5/)
- [Version 1.4.x](http://www.cocoanetics.com/2013/04/dtcoretext-1-4-2/)
- [Version 1.4](http://www.cocoanetics.com/2013/04/rich-text-update-1-4/)
- [Version 1.2](http://www.cocoanetics.com/2013/01/dtcoretext-1-2-0/)
- [Version 1.1](http://www.cocoanetics.com/2012/12/dtcoretext-1-1/)
- [Version 1.0.1](http://www.cocoanetics.com/2012/04/dtcoretext-1-0-1-linker-flags-and-rich-text-news/)
- [Version 1.0](http://www.cocoanetics.com/2012/02/dtrichtexteditor-dtcoretext-news/)

License
-------

It is open source and covered by a standard 2-clause BSD license. That means you have to mention *Cocoanetics* as the original author of this code and reproduce the LICENSE text inside your app. 

You can purchase a [Non-Attribution-License](https://www.cocoanetics.com/order/?product_id=DTCoreText) for 75 Euros for not having to include the LICENSE text.

We also accept sponsorship for specific enhancements which you might need. Please [contact us via email](mailto:oliver@cocoanetics.com?subject=DTCoreText) for inquiries.
