import Foundation

/// A specialized subclass in the TextAttachment class cluster to represent a generic object.
@objc(DTObjectTextAttachment)
open class ObjectTextAttachment: TextAttachment, TextAttachmentHTMLPersistence {

  /// The HTMLElement child nodes of the receiver. This array is only used for object tags at the moment.
  @objc public var childNodes: [HTMLElement]?

  // MARK: - NSCoding

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    // childNodes are transient; they are not restored from an archive.
  }

  open override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    // childNodes are transient; they are not written to an archive.
  }

  public override init(data contentData: Data?, ofType uti: String?) {
    super.init(data: contentData, ofType: uti)
  }

  open override func configured(with element: HTMLElement, options: [String: Any]?) -> Self {
    let result = super.configured(with: element, options: options)

    // get base URL
    let baseURL = options?[NSBaseURLDocumentOption] as? URL
    let src = element.attributes?["src"]

    // content URL
    if let src = src {
      result.contentURL = URL(string: src, relativeTo: baseURL)
    }

    return result
  }

  // MARK: - TextAttachmentHTMLPersistence

  @objc open func stringByEncodingAsHTML() -> String {
    var retString = "<object"

    if let contentURL = contentURL {
      retString += " src=\"\(contentURL.absoluteString)\""
    }

    // build style for object
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
    if let attrs = attributes {
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

    if let childNodes = childNodes, !childNodes.isEmpty {
      retString += ">"

      for element in childNodes {
        element.appendHTML(to: &retString, indentLevel: 0)
      }

      retString += "</object>"
    } else {
      retString += " />"
    }

    return retString
  }
}
