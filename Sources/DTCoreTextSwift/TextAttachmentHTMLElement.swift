import Foundation
import CoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Specialized subclass of HTMLElement for dealing with text attachment instances, e.g. images.
@objc(DTTextAttachmentHTMLElement)
open class TextAttachmentHTMLElement: HTMLElement {

    private var _maxDisplaySize: CGSize = .zero

    @objc public init(name: String, attributes: NSDictionary?, options: NSDictionary?) {
        super.init(name: name, attributes: attributes)

        // make appropriate attachment
        if let attachment = TextAttachment.textAttachment(with: self, options: options) {
            // add it to tag
            _textAttachment = attachment

            // to avoid much too much space before the image
            if _paragraphStyle == nil {
                _paragraphStyle = CoreTextParagraphStyle()
            }

            _paragraphStyle?.lineHeightMultiple = 1

            // specifying line height interferes with correct positioning
            _paragraphStyle?.minimumLineHeight = 0
            _paragraphStyle?.maximumLineHeight = 0

            // remember the maximum display size
            _maxDisplaySize = .zero

            if let maxImageSizeValue = (options as? [String: Any])?[DTMaxImageSize as String] as? NSValue {
                #if canImport(UIKit)
                _maxDisplaySize = maxImageSizeValue.cgSizeValue
                #else
                _maxDisplaySize = maxImageSizeValue.sizeValue
                #endif
            }
        }
    }

    required public init(name: String, attributes: NSDictionary?) {
        super.init(name: name, attributes: attributes)
    }

    @objc open override func attributedString() -> NSAttributedString? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        let attributes = attributesForAttributedStringRepresentation() as! [NSAttributedString.Key: Any]

        // ignore text, use unicode object placeholder
        let tmpString = NSMutableAttributedString(string: UNICODE_OBJECT_PLACEHOLDER, attributes: attributes)

        // block-level elements get space trimmed and a newline
        if self.displayStyle != .inline {
            tmpString.appendString("\n")
        }

        return tmpString
    }

    // workaround, because we don't support float yet. float causes the image to be its own block
    @objc open override var displayStyle: DTHTMLElementDisplayStyle {
        get {
            if super.floatStyle == .none {
                return super.displayStyle
            }
            return .block
        }
        set {
            super.displayStyle = newValue
        }
    }

    @objc open override func applyStyleDictionary(_ styles: NSDictionary) {
        // element size is determined in super (tag attribute and style)
        super.applyStyleDictionary(styles)

        // at this point we have the size from width/height attribute or style in _size

        // set original size if it was previously unknown
        if let attachment = _textAttachment, attachment.originalSize.equalTo(.zero) {
            attachment.originalSize = _size
        }

        let widthString = styles["width"] as? String
        let heightString = styles["height"] as? String

        if let widthString = widthString, widthString.count > 1, widthString.hasSuffix("%") {
            let scaleStr = String(widthString.dropLast())
            let scale = CGFloat((scaleStr as NSString).floatValue) / 100.0
            _size.width = _maxDisplaySize.width * scale
        }

        if let heightString = heightString, heightString.count > 1, heightString.hasSuffix("%") {
            let scaleStr = String(heightString.dropLast())
            let scale = CGFloat((scaleStr as NSString).floatValue) / 100.0
            _size.height = _maxDisplaySize.height * scale
        }

        // update the display size
        _textAttachment?.setDisplaySize(_size, withMaxDisplaySize: _maxDisplaySize)
    }
}
