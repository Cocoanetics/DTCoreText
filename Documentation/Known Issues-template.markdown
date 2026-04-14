Known Issues
============

### Font Matching Performance

CoreText's internal font lookup table can take a moment to initialize on first use. You can prepopulate the table by calling:

```swift
await CoreTextFontDescriptor.preloadFontLookupTable()
```

Alternatively, include a `DTCoreTextFontOverrides.plist` in your app bundle containing only the font families your app uses.

Some combinations of fonts and unusual list types cause an extra space to appear (e.g. 20px Courier + circle list style).

### Differences between Apple and DTCoreText

In many aspects DTCoreText is superior to Apple's built-in `NSAttributedString` HTML generation. Notable differences:

- DTCoreText supports the `<video>` tag; Apple's implementation does not.
- DTCoreText synthesizes small caps by rendering lowercase characters in uppercase with a smaller font size.
- Apple uses `-webkit-margin-*` CSS styles for paragraph spacing; DTCoreText uses `-webkit-margin-bottom` and `margin-bottom`.
- Apple supports cascaded CSS selectors (e.g. `ul ul` to change nested list styles); DTCoreText does not, so list bullets remain the same across nesting levels.
- Apple outputs newlines in `<pre>` tags as `\n`; DTCoreText uses Unicode Line Feed characters so that paragraph spacing applies at the end of the `<pre>` tag rather than after each line.

### Differences between UITextView/WKWebView and DTCoreText

- UIKit draws a fixed 1px line for underline and strikethrough; DTCoreText uses the line thickness and position from the CTFont.
- UIKit does not support multiple text shadows; DTCoreText does (via `DTShadowsAttribute`).
- UIKit does not support kerning by default; DTCoreText always kerns.
- UIKit does not support inline text attachments in the same way; DTCoreText renders images and custom views inline via its delegate protocol.

If you find an issue you are welcome to fix it and contribute via a GitHub pull request.
