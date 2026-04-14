DTCoreText Programming Guide
============================

This document is a collection of recipes for common DTCoreText tasks.

Smoke Test
----------

After adding DTCoreText to your project via Swift Package Manager, verify the setup with:

```swift
import DTCoreTextSwift

let html = "<p>Some Text</p>"
let data = html.data(using: .utf8)!

if let attrString = NSAttributedString(htmlData: data, documentAttributes: nil) {
    print(attrString)
}
```

You should see a description of the generated attributed string in the console.

### SwiftUI AttributedString

DTCoreText can also produce a SwiftUI `AttributedString` that preserves all custom attributes:

```swift
let attrStr = try AttributedString(htmlData: data)
```

Or asynchronously with cancellation support:

```swift
let attrStr = try await AttributedString(htmlData: data, options: options)
```

Basic text styling (fonts, colors, links) renders natively in SwiftUI `Text`. DTCoreText-specific attributes (text blocks, header levels, anchors, etc.) are preserved in the attribute runs for custom view implementations.

Using Helvetica Neue Light
--------------------------

There are two ways to use a specific font:

**Variant 1** — specify the PostScript font face name via the `font` tag:

```html
<p><font face="HelveticaNeue-Light">HelveticaNeue-Light</font></p>
```

Setting the font face uses exactly this font if it exists on the system. If not, the fallback mechanism is used (see below). Tags that modify bold or italic traits cause the font face to be removed from the inheritance, using the font family technique instead.

**Variant 2** — register a font name override in code:

```swift
CoreTextFontDescriptor.setOverrideFontName(
    "HelveticaNeue-Light",
    forFontFamily: "Helvetica Neue",
    bold: false,
    italic: false
)
```

This makes DTCoreText use "HelveticaNeue-Light" whenever a non-bold, non-italic "Helvetica Neue" font is requested.


Font Matching Performance
-------------------------

DTCoreText uses an internal lookup table mapping font family + bold/italic traits to a specific font face name. You can prepopulate this table by including a `DTCoreTextFontOverrides.plist` in your app bundle.

For most use cases the overrides plist from the DTCoreText demo app covers the commonly used fonts.

If you don't know the set of fonts your app will encounter, trigger an asynchronous preload:

```swift
await CoreTextFontDescriptor.preloadFontLookupTable()
```

Calling this does not replace entries already loaded from the plist.

Setting a Fallback Font Family
------------------------------

When DTCoreText encounters a font family not installed on the system, it falls back to a configurable default:

```swift
try CoreTextFontDescriptor.setFallbackFontFamily("Helvetica Neue")
```

The font family must be valid on the system. An invalid name throws `CoreTextFontDescriptor.FontError.unknownFontFamily`.

Getting a Tapped Word
-----------------------

To retrieve the word a user tapped on, get the closest cursor position to the tapped point, then find the enclosing word range:

```swift
@objc func handleTap(_ gesture: UITapGestureRecognizer) {
    guard gesture.state == .recognized else { return }

    let location = gesture.location(in: textView)
    let tappedIndex = textView.closestCursorIndex(to: location)
    let plainText = textView.attributedString.string

    var wordRange = plainText.startIndex..<plainText.startIndex
    plainText.enumerateSubstrings(
        in: plainText.startIndex...,
        options: .byWords
    ) { _, substringRange, enclosingRange, stop in
        let nsRange = NSRange(enclosingRange, in: plainText)
        if NSLocationInRange(Int(tappedIndex), nsRange) {
            wordRange = substringRange
            stop = true
        }
    }

    let word = String(plainText[wordRange])
    print("Tapped word: '\(word)'")
}
```

Visible String Range
--------------------

To retrieve the visible string range from a `DTAttributedTextView`:

```swift
let visibleRect = textView.bounds
let visibleLines = textView.attributedTextContentView.layoutFrame.linesVisible(in: visibleRect)

if let first = visibleLines.first, let last = visibleLines.last {
    var range = first.stringRange()
    range = NSUnionRange(last.stringRange(), range)
    print("Visible range: \(range)")
}
```

Determining Size Required for an Attributed String
---------------------------------------------------

When creating a `CoreTextLayoutFrame` you can specify `CGFLOAT_WIDTH_UNKNOWN` or `CGFLOAT_HEIGHT_UNKNOWN` to have the needed dimensions calculated:

```swift
let layouter = CoreTextLayouter(attributedString: attributedString)

let maxRect = CGRect(x: 10, y: 20, width: CGFLOAT_WIDTH_UNKNOWN, height: CGFLOAT_HEIGHT_UNKNOWN)
let entireString = NSRange(location: 0, length: attributedString.length)
let layoutFrame = layouter.layoutFrame(with: maxRect, range: entireString)

let sizeNeeded = layoutFrame.frame.size
```


Displaying Remote Images
------------------------

Use `DTLazyImageView` for deferred image loading. Return it from the text content view delegate:

```swift
func attributedTextContentView(
    _ attributedTextContentView: DTAttributedTextContentView,
    viewForAttachment attachment: DTTextAttachment,
    frame: CGRect
) -> UIView? {
    guard let imageAttachment = attachment as? DTImageTextAttachment else { return nil }

    let imageView = DTLazyImageView(frame: frame)
    imageView.delegate = self
    imageView.url = imageAttachment.contentURL
    return imageView
}
```

Then update the layout when the image loads:

```swift
func lazyImageView(_ lazyImageView: DTLazyImageView, didChangeImageSize size: CGSize) {
    guard let url = lazyImageView.url else { return }
    let pred = NSPredicate(format: "contentURL == %@", url as CVarArg)

    for attachment in attributedTextContentView.layoutFrame.textAttachments(with: pred) {
        attachment.originalSize = size
    }

    attributedTextContentView.layouter = nil
    attributedTextContentView.relayoutText()
}
```

Changing the Default Font
-------------------------

Specify font options when creating the attributed string:

```swift
let options: [String: Any] = [
    NSTextSizeMultiplierDocumentOption: 1.0,
    DTDefaultFontFamily: "Helvetica Neue"
]

let html = "<p>Some Text</p>"
let data = html.data(using: .utf8)!
let attributedString = NSAttributedString(htmlData: data, options: options, documentAttributes: nil)
```

Adding a Custom Font via CSS
----------------------------

Use the `-coretext-fontname` CSS property:

```swift
let customStyleSheet = CSSStylesheet(styleBlock: "body { -coretext-fontname: SourceSansPro-Light; }")
CSSStylesheet.defaultStyleSheet().merge(customStyleSheet)
```
