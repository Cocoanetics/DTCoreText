DTCoreText
==========

This project aims to duplicate the methods present on Mac OSX which allow creation of `NSAttributedString` from HTML code on iOS. 

The project covers two broad areas:

1. **Layouting** - Interfacing with CoreText, generating attributed strings from HTML code
2. **User Interface** - UI-related classes render these objects, specifically `DTAttributedTextView`, `DTAttributedLabel` and `DTAttributedTextCell`.

This is useful for drawing simple rich text like any HTML document without having to use a web view. For text selection and highlighting (as you might need for an Editor or Reader) there is the commercial **DTRichTextEditor** component which can be purchased in the [Cocoanetics Parts Store](http://www.cocoanetics.com/parts/dtrichtexteditor/).

Documentation
-------------

Documentation can be [browsed online](https://docs.cocoanetics.com/DTCoreText) or installed in your Xcode Organizer via the [Atom Feed URL](https://docs.cocoanetics.com/DTCoreText/DTCoreText.atom).

A [Q&A](http://www.cocoanetics.com/2011/08/nsattributedstringhtml-qa/) answers some frequently asked questions.

Changelog: [GitHub Releases](https://github.com/Cocoanetics/DTCoreText/releases)

There is also a [Programming Guide](Documentation/Programming Guide-template.markdown) with a set of solutions to common problems.

Follow [@cocoanetics](http://twitter.com/cocoanetics) on Twitter or subscribe to the [Cocoanetics Blog](http://www.cocoanetics.com) for news and updates.

License
-------

It is open source and covered by a standard 2-clause BSD license. That means you have to mention *Cocoanetics* as the original author of this code and reproduce the LICENSE text inside your app. 

You can purchase a [Non-Attribution-License](https://www.cocoanetics.com/order/?product_id=DTCoreText) for 75 Euros for not having to include the LICENSE text.

We also accept sponsorship for specific enhancements which you might need. Please [contact us via email](mailto:oliver@cocoanetics.com?subject=DTCoreText) for inquiries.
