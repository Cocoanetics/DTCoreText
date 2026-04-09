import Foundation
import CoreText

/// Owns an attributed string and is able to create layout frames for certain ranges in this string.
@objc(DTCoreTextLayouter)
open class CoreTextLayouter: NSObject {

    private var _framesetter: CTFramesetter?
    private var _attributedString: NSAttributedString?
    private var _layoutFrameCache: NSCache<NSString, CoreTextLayoutFrame>?

    /// If set to YES then the receiver will cache layout frames.
    @objc open var shouldCacheLayoutFrames: Bool = false {
        didSet {
            if shouldCacheLayoutFrames != oldValue {
                if shouldCacheLayoutFrames {
                    _layoutFrameCache = NSCache()
                } else {
                    _layoutFrameCache = nil
                }
            }
        }
    }

    // MARK: - Creating a Layouter

    /// Designated Initializer. Creates a new Layouter with an attributed string.
    @objc public init?(attributedString: NSAttributedString?) {
        guard let attributedString = attributedString else { return nil }
        super.init()
        self.attributedString = attributedString
    }

    deinit {
        _discardFramesetter()
    }

    // MARK: - Creating Layout Frames

    /// Creates a layout frame with a given rectangle and string range.
    @objc open func layoutFrame(with frame: CGRect, range: NSRange) -> CoreTextLayoutFrame? {
        var newFrame: CoreTextLayoutFrame? = nil
        var cacheKey: NSString? = nil

        // need to have a non zero
        guard frame.size.width > 0 && frame.size.height > 0 else { return nil }

        if shouldCacheLayoutFrames {
            cacheKey = "\(_attributedString?.hash ?? 0)-\(NSStringFromCGRect(frame))-\(NSStringFromRange(range))" as NSString

            if let cachedLayoutFrame = _layoutFrameCache?.object(forKey: cacheKey!) {
                return cachedLayoutFrame
            }
        }

        autoreleasepool {
            newFrame = CoreTextLayoutFrame(frame: frame, layouter: self, range: range)
        }

        if let newFrame = newFrame, shouldCacheLayoutFrames, let cacheKey = cacheKey {
            _layoutFrameCache?.setObject(newFrame, forKey: cacheKey)
        }

        return newFrame
    }

    private func _discardFramesetter() {
        if let framesetter = _framesetter {
            _framesetter = nil
        }
    }

    // MARK: - Properties

    /// The internal framesetter of the receiver.
    @objc open var framesetter: CTFramesetter? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if _framesetter == nil {
            guard let attributedString = _attributedString else { return nil }
            _framesetter = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)
        }

        return _framesetter
    }

    /// The attributed string that the layouter currently owns.
    @objc open var attributedString: NSAttributedString? {
        get { return _attributedString }
        set {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }

            if _attributedString !== newValue {
                _attributedString = newValue
                _discardFramesetter()
                _layoutFrameCache?.removeAllObjects()
            }
        }
    }
}
