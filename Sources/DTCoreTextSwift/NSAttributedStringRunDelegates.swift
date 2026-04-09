import Foundation
import CoreText

/// Creates a CTRunDelegate for text attachments.
///
/// The run delegate provides ascent, descent, and width callbacks
/// that are used by Core Text during layout for embedded objects.
/// - Parameter obj: The text attachment object (should be a TextAttachment instance)
/// - Returns: A CTRunDelegate, or nil if creation fails
public func createEmbeddedObjectRunDelegate(_ obj: AnyObject?) -> CTRunDelegate? {
    guard let obj = obj else { return nil }

    var callbacks = CTRunDelegateCallbacks(
        version: kCTRunDelegateCurrentVersion,
        dealloc: { _ in
            // no-op
        },
        getAscent: { context in
            let attachment = Unmanaged<AnyObject>.fromOpaque(context).takeUnretainedValue()
            if let textAttachment = attachment as? TextAttachment {
                return textAttachment.ascentForLayout()
            }
            return 0
        },
        getDescent: { context in
            let attachment = Unmanaged<AnyObject>.fromOpaque(context).takeUnretainedValue()
            if let textAttachment = attachment as? TextAttachment {
                return textAttachment.descentForLayout()
            }
            return 0
        },
        getWidth: { context in
            let attachment = Unmanaged<AnyObject>.fromOpaque(context).takeUnretainedValue()
            if let textAttachment = attachment as? TextAttachment {
                return textAttachment.displaySize.width
            }
            return 35
        }
    )

    let pointer = Unmanaged.passUnretained(obj).toOpaque()
    return CTRunDelegateCreate(&callbacks, pointer)
}
