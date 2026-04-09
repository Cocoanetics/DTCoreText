import Foundation

// Constants for dictation placeholder dot layout
private let DOT_WIDTH: CGFloat = 10.0
private let DOT_DISTANCE: CGFloat = 2.5
private let DOT_OUTSIDE_MARGIN: CGFloat = 3.0

/// A special subclass of TextAttachment used to represent the dictation placeholder.
///
/// When encountering such an element, AttributedTextContentView does not call the delegate
/// to provide a subclass but automatically creates and adds a DictationPlaceholderView.
@objc(DTDictationPlaceholderTextAttachment)
open class DictationPlaceholderTextAttachment: TextAttachment {

    /// The string that inserting the dictation placeholder replaced, used for Undoing
    @objc public var replacedAttributedString: NSAttributedString?

    // MARK: - NSCoding

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        replacedAttributedString = coder.decodeObject(forKey: "replacedAttributedString") as? NSAttributedString
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(replacedAttributedString, forKey: "replacedAttributedString")
    }

    public override init(data contentData: Data?, ofType uti: String?) {
        super.init(data: contentData, ofType: uti)
    }

    // MARK: - Hard-coded sizes

    open override var displaySize: CGSize {
        get {
            return CGSize(
                width: DOT_OUTSIDE_MARGIN * 2.0 + DOT_WIDTH * 3.0 + DOT_DISTANCE * 2.0,
                height: DOT_OUTSIDE_MARGIN * 2.0 + DOT_WIDTH
            )
        }
        set { /* ignore */ }
    }

    open override var originalSize: CGSize {
        get { return displaySize }
        set { /* ignore */ }
    }

    open override func ascentForLayout() -> CGFloat {
        return displaySize.height
    }

    open override func descentForLayout() -> CGFloat {
        return 0.0
    }
}
