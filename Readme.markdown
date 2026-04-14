DTCoreText
==========

DTCoreText generates `NSAttributedString` (and SwiftUI `AttributedString`) from HTML on iOS, macOS, and tvOS. It uses CoreText for layout and rendering, giving you full control over rich text display without a web view.

The project covers two broad areas:

1. **Parsing and layout** - Generating attributed strings from HTML, interfacing with CoreText
2. **User interface** - `DTAttributedTextView`, `DTAttributedLabel` and related classes for rendering rich text

Installation
------------

DTCoreText is a Swift package. Add it in Xcode via **File > Add Package Dependencies…** using:

    https://github.com/Cocoanetics/DTCoreText.git

Or in your `Package.swift`:

```swift
.package(url: "https://github.com/Cocoanetics/DTCoreText.git", from: "2.0.0")
```

Then link the `DTCoreText` product to your target.

Documentation
-------------

Documentation can be [browsed online](https://docs.cocoanetics.com/DTCoreText) or installed in your Xcode Organizer via the [Atom Feed URL](https://docs.cocoanetics.com/DTCoreText/DTCoreText.atom).

Changelog: [GitHub Releases](https://github.com/Cocoanetics/DTCoreText/releases)

There is also a [Programming Guide](Documentation/Programming%20Guide-template.markdown) with solutions to common problems.

Follow [@cocoanetics](http://twitter.com/cocoanetics) on Twitter or subscribe to the [Cocoanetics Blog](http://www.cocoanetics.com) for news and updates.

License
-------

It is open source and covered by a standard 2-clause BSD license. That means you have to mention *Cocoanetics* as the original author of this code and reproduce the LICENSE text inside your app.

You can purchase a [Non-Attribution-License](https://www.cocoanetics.com/order/?product_id=DTCoreText) for 75 Euros for not having to include the LICENSE text.

We also accept sponsorship for specific enhancements which you might need. Please [contact us via email](mailto:oliver@cocoanetics.com?subject=DTCoreText) for inquiries.
