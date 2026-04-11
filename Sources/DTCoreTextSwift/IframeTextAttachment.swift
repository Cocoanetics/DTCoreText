import Foundation

/// A specialized subclass in the TextAttachment class cluster to represent an IFRAME.
@objc(DTIframeTextAttachment)
open class IframeTextAttachment: TextAttachment, TextAttachmentHTMLPersistence {

  @objc open override func configured(with element: HTMLElement, options: NSDictionary?) -> Self {
    let result = super.configured(with: element, options: options)

    // get base URL
    let baseURL = (options as? [String: Any])?[NSBaseURLDocumentOption as String] as? URL
    var src = (element.attributes as? [String: Any])?["src"] as? String

    // prepend https: if URL string starts with // (seems to do with youtube iframes as standard)
    if let s = src, s.hasPrefix("//") {
      src = "https:" + s
    }

    // upgrade http:// YouTube embed URLs to https:// — YouTube blocks the
    // insecure scheme and returns a "Video player configuration" error.
    if let s = src, s.hasPrefix("http://") {
      src = "https://" + String(s.dropFirst("http://".count))
    }

    // content URL
    if let src = src {
      result.contentURL = URL(string: src, relativeTo: baseURL)
    }

    return result
  }

  // MARK: - TextAttachmentHTMLPersistence

  @objc open func stringByEncodingAsHTML() -> String {
    var retString = "<iframe"

    if let contentURL = contentURL {
      retString += " src=\"\(contentURL.absoluteString)\""
    }

    // build style for iframe
    var styleString = ""

    switch verticalAlignment {
    case .baseline:
      break
    case .top:
      styleString += "vertical-align:text-top;"
    case .center:
      styleString += "vertical-align:middle;"
    case .bottom:
      styleString += "vertical-align:text-bottom;"
    }

    if _originalSize.width > 0 {
      styleString += String(format: "width:%.0fpx;", _originalSize.width)
    }

    if _originalSize.height > 0 {
      styleString += String(format: "height:%.0fpx;", _originalSize.height)
    }

    if !styleString.isEmpty {
      retString += " style=\"\(styleString)\""
    }

    // attach the attributes dictionary
    if let attrs = attributes as? [String: Any] {
      var tmpAttributes = attrs
      tmpAttributes.removeValue(forKey: "src")
      tmpAttributes.removeValue(forKey: "style")
      tmpAttributes.removeValue(forKey: "width")
      tmpAttributes.removeValue(forKey: "height")

      for key in tmpAttributes.keys {
        let encodedKey = key.addingHTMLEntities()
        let value = "\(tmpAttributes[key]!)"
        let encodedValue = value.addingHTMLEntities()
        retString += " \(encodedKey)=\"\(encodedValue)\""
      }
    }

    retString += " />"

    return retString
  }
}
