Setup Guide
===========

DTCoreText is distributed as a Swift package. Swift Package Manager is the only supported integration method.

Requirements
------------

- iOS 16.0+, macOS 13.0+, or tvOS 16.0+
- Xcode 15+ / Swift 5.9+

Integrating via Swift Package Manager
--------------------------------------

### In Xcode

Use **File > Add Package Dependencies…** and add:

    https://github.com/Cocoanetics/DTCoreText.git

Then add the `DTCoreText` library product to your target.

### In Package.swift

Add DTCoreText as a dependency:

```swift
dependencies: [
    .package(url: "https://github.com/Cocoanetics/DTCoreText.git", from: "2.0.0")
]
```

And depend on the product from your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "DTCoreText", package: "DTCoreText")
    ]
)
```

Smoke Test
----------

Verify that everything is set up correctly:

```swift
import DTCoreTextSwift

let html = "<p>Some Text</p>"
let data = html.data(using: .utf8)!

if let attrString = NSAttributedString(htmlData: data, documentAttributes: nil) {
    print(attrString)
}
```

You should see a description of the generated attributed string in the console.

Resources
---------

DTCoreText includes a `default.css` stylesheet that defines the default HTML styles. To customize default styles, pass a `DTDefaultStyleSheet` option when creating attributed strings rather than modifying the built-in stylesheet. See the [Programming Guide](Programming%20Guide-template.markdown) for details.
