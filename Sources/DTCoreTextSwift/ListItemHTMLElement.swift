import Foundation
import CoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Specialized subclass of HTMLElement that deals with list items.
@objc(DTListItemHTMLElement)
open class ListItemHTMLElement: HTMLElement {

    private func _indexOfListItemInListRoot(_ listRoot: HTMLElement) -> Int {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        var index: Int = -1

        guard let childNodes = listRoot.childNodes as? [HTMLElement] else { return 0 }

        for oneElement in childNodes {
            if oneElement is ListItemHTMLElement {
                index += 1
            }

            if oneElement === self {
                break
            }
        }

        return max(index, 0)
    }

    // calculates the accumulated list indent
    private func _sumOfListIndents() -> CGFloat {
        var indent: CGFloat = 0

        var element: HTMLElement? = self.parentElement()

        while let elem = element {
            if elem.name == "ul" || elem.name == "ol" {
                indent += elem._listIndent
            } else if elem.displayStyle == .listItem {
                // we accept these
                indent += elem.padding.left
            } else {
                break
            }

            element = elem.parentElement()
        }

        return indent
    }

    @objc open override func applyStyleDictionary(_ styles: NSDictionary) {
        super.applyStyleDictionary(styles)

        let parentPadding = self.parentElement()?._listIndent ?? 0
        let listIndents = _sumOfListIndents()

        self.paragraphStyle.headIndent = listIndents + _padding.left + _margins.left
        self.paragraphStyle.firstLineHeadIndent = self.paragraphStyle.headIndent

        _margins.left += parentPadding
    }

    // creates an attributed list prefix
    private func _listPrefix() -> NSAttributedString? {
        let paragraphStyle = CoreTextParagraphStyle.paragraphStyle(withNSParagraphStyle: (attributesForAttributedStringRepresentation() as! [NSAttributedString.Key: Any])[.paragraphStyle] as? NSParagraphStyle)

        let fontDescriptor = (attributesForAttributedStringRepresentation() as! [NSAttributedString.Key: Any]).dtct_fontDescriptor()

        var effectiveList = self.paragraphStyle.textLists?.last as? CSSListStyle
        let listRoot = self.parentElement()
        let listCounter = _indexOfListItemInListRoot(listRoot!) + Int(effectiveList?.startingItemNumber ?? 1)

        // make a temporary version of self that has same font attributes as list root
        let tmpCopy = ListItemHTMLElement(name: "", attributes: nil)
        tmpCopy.inheritAttributes(from: self)

        // take the parents text color
        tmpCopy.textColor = listRoot?.textColor

        // check for list-style:none modifier
        if let styleStr = self.attributeForKey("style") {
            let styles = (styleStr as NSString).dictionaryOfCSSStyles()

            if styles.count > 0 {
                // make a temp copy
                effectiveList = effectiveList?.copy() as? CSSListStyle

                // update from styles
                effectiveList?.updateFromStyleDictionary(styles)
            }
        }

        let attributes = tmpCopy.attributesForAttributedStringRepresentation() as! [NSAttributedString.Key: Any]

        // modify paragraph style
        let ps = paragraphStyle
        ps.firstLineHeadIndent = self.paragraphStyle.headIndent - _margins.left - _padding.left
        ps.defaultTabInterval = 100

        // resets tabs
        ps.tabStops = nil

        guard let effectiveList = effectiveList else { return nil }

        // set tab stops
        if effectiveList.type != .none {
            if _margins.left <= 0 {
                return nil
            }

            // first tab is to right-align bullet, numbering against
            let tabOffset = ps.headIndent - 5.0

            ps.addTabStop(at: tabOffset, alignment: .right)
        }

        // second tab is for the beginning of first line after bullet
        ps.addTabStop(at: ps.headIndent, alignment: .left)

        let newAttributes = NSMutableDictionary()

        // make a font without italic or bold
        guard let fd = fontDescriptor else { return nil }
        fd.boldTrait = false
        fd.italicTrait = false

        let font = fd.newMatchingFont()

        if let font = font {
            #if canImport(UIKit)
            let uiFont = UIFont.font(with: font)
            newAttributes[NSAttributedString.Key.font] = uiFont
            #else
            newAttributes[NSAttributedString.Key.font] = font
            #endif
        }

        let uiColor = attributes.dtct_foregroundColor()
        newAttributes[NSAttributedString.Key.foregroundColor] = uiColor

        // add paragraph style (this has the tabs)
        let style = ps.nsParagraphStyle()
        newAttributes[NSAttributedString.Key.paragraphStyle] = style

        // add textBlock if there's one (this has padding and background color)
        if let textBlocks = attributes[NSAttributedString.Key(rawValue: DTTextBlocksAttribute)] {
            newAttributes[NSAttributedString.Key(rawValue: DTTextBlocksAttribute)] = textBlocks
        }

        // transfer all lists so that
        if let lists = attributes[NSAttributedString.Key(rawValue: DTTextListsAttribute)] {
            newAttributes[NSAttributedString.Key(rawValue: DTTextListsAttribute)] = lists
        }

        // add a marker so that we know that this is a field/prefix
        newAttributes[NSAttributedString.Key(rawValue: DTFieldAttribute)] = DTListPrefixField

        guard var prefix = effectiveList.prefix(withCounter: listCounter) else {
            return nil
        }

        var image: DTImage? = nil

        if let imageName = effectiveList.imageName {
            image = DTImage(named: imageName)

            if image == nil {
                // image invalid
                effectiveList.imageName = nil

                guard let newPrefix = effectiveList.prefix(withCounter: listCounter) else {
                    return nil
                }
                prefix = newPrefix
            }
        }

        let tmpStr = NSMutableAttributedString(string: prefix, attributes: newAttributes as? [NSAttributedString.Key: Any])

        if let image = image {
            // make an attachment for the image
            let attachment = ImageTextAttachment()
            attachment.image = image
            attachment.displaySize = image.size

            let mutableNewAttributes = newAttributes.mutableCopy() as! NSMutableDictionary

            #if canImport(UIKit)
            // need run delegate for sizing
            let embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(attachment)
            mutableNewAttributes[NSAttributedString.Key(rawValue: kCTRunDelegateAttributeName as String)] = embeddedObjectRunDelegate
            #endif

            // add attachment
            mutableNewAttributes[NSAttributedString.Key.attachment] = attachment

            if effectiveList.position == .inside {
                tmpStr.setAttributes(mutableNewAttributes as? [NSAttributedString.Key: Any], range: NSRange(location: 2, length: 1))
            } else {
                tmpStr.setAttributes(mutableNewAttributes as? [NSAttributedString.Key: Any], range: NSRange(location: 1, length: 1))
            }
        }

        // estimate width of the prefix
        let trimmedPrefix = prefix.trimmingCharacters(in: .whitespaces)
        let tmpAttributedString = NSAttributedString(string: trimmedPrefix, attributes: newAttributes as? [NSAttributedString.Key: Any])

        let tmpLine = CTLineCreateWithAttributedString(tmpAttributedString as CFAttributedString)
        let width = CTLineGetTypographicBounds(tmpLine, nil, nil, nil)

        // if the non-whitespace characters are too wide then we omit the prefix
        if (width + 5.0) > Double(_margins.left) {
            return nil
        }

        return tmpStr
    }

    @objc open override func attributedString() -> NSAttributedString? {
        let tmpString = NSMutableAttributedString()

        // append child elements
        let childrenString = super.attributedString()

        // append list prefix
        let listPrefix = _listPrefix()

        if let listPrefix = listPrefix {
            tmpString.append(listPrefix)

            // add NL if there is immediately another list prefix following
            if let childrenString = childrenString {
                let field = childrenString.attribute(NSAttributedString.Key(rawValue: DTFieldAttribute), at: 0, effectiveRange: nil) as? String

                if field == DTListPrefixField {
                    tmpString.dtct_appendEndOfParagraph()
                }
            }
        }

        if let childrenString = childrenString {
            tmpString.append(childrenString)
        }

        return tmpString
    }
}
