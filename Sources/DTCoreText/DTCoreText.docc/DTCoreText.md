# ``DTCoreText``

Generate `NSAttributedString` and SwiftUI `AttributedString` from HTML on iOS, macOS, and tvOS.

## Overview

DTCoreText parses HTML into attributed strings using CoreText, giving you full control over rich text display without a web view. It supports fonts, colors, links, images, lists, tables, text shadows, and custom HTML attributes.

### Generating Attributed Strings

Create an `NSAttributedString` from HTML:

```swift
let html = "<p>Hello <b>World</b></p>"
let data = html.data(using: .utf8)!
let attributed = NSAttributedString(htmlData: data, documentAttributes: nil)
```

Or a SwiftUI `AttributedString` that preserves all custom attributes:

```swift
let attributed = try AttributedString(htmlData: data)
```

### Customizing Output

Control fonts, text scale, stylesheets, and more via the options dictionary:

```swift
let options: [String: Any] = [
    DTDefaultFontFamily: "Helvetica Neue",
    NSTextSizeMultiplierDocumentOption: 1.5
]
let attributed = NSAttributedString(htmlData: data, options: options, documentAttributes: nil)
```

### Rendering Rich Text

Use ``DTAttributedTextView`` or ``DTAttributedLabel`` to render the attributed string with full support for inline images, links, and custom views.

## Topics

### Parsing HTML

- ``HTMLAttributedStringBuilder``
- ``CSSStylesheet``

### Layout

- ``CoreTextLayoutFrame``
- ``CoreTextLayoutLine``
- ``CoreTextLayouter``

### Text Attachments

- ``TextAttachment``
- ``ImageTextAttachment``
- ``VideoTextAttachment``
- ``ObjectTextAttachment``

### Font Handling

- ``CoreTextFontDescriptor``
- ``CoreTextFontCollection``

### SwiftUI Support

- ``DTCoreTextAttributes``
- ``DTHeaderLevelKey``
- ``DTAnchorKey``
- ``DTTextBlocksKey``
- ``DTFieldKey``

### HTML Elements

- ``HTMLElement``
- ``HTMLParserNode``

### Paragraph Styling

- ``CoreTextParagraphStyle``
- ``TextBlock``
