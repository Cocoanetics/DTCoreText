import CoreText
import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Text Attachment vertical alignment
@objc(DTTextAttachmentVerticalAlignment)
public enum TextAttachmentVerticalAlignment: UInt {
  /// Baseline alignment (default)
  case baseline = 0
  /// Align with top edge
  case top
  /// Align with center
  case center
  /// Align with bottom edge
  case bottom
}

/// Methods to implement for attachments to support inline drawing.
@objc(DTTextAttachmentDrawing)
public protocol TextAttachmentDrawing {
  /// Draws the contents of the receiver into a graphics context
  func draw(in rect: CGRect, context: CGContext)
}

/// Methods to implement for attachments to support output to HTML.
@objc(DTTextAttachmentHTMLPersistence)
public protocol TextAttachmentHTMLPersistence {
  /// Creates a HTML representation of the receiver
  func stringByEncodingAsHTML() -> String
}

/// Thread-safe, Swift-native tag-name → `TextAttachment` subclass registry.
///
/// Background: DTCoreText's original registry was an `NSMutableDictionary` guarded only
/// by a `nonisolated(unsafe)` flag with double-checked-locking-without-a-lock. Under
/// test parallelism — where many `BuilderState` actors read the registry via
/// `TextAttachment.textAttachment(with:options:)` while test setup concurrently writes
/// via `TextAttachment.registerClass(_:forTagName:)` — `NSMutableDictionary`'s internal
/// hash table could resize under a reader's traversal, producing silent memory
/// corruption and SIGSEGV crashes much later.
///
/// This enum namespace provides:
///
/// - A pure Swift `[String: AnyClass]` storage (no Cocoa bridging, no NSMutableDictionary).
/// - An `NSLock` that serializes all reads and writes so the dict is never observed
///   mid-mutation.
/// - One-shot bootstrap via a `static let` closure, whose lowering to `swift_once`
///   provides a release barrier on publish — fixing the classic publication race where
///   a second thread could observe the "initialized" flag before the writes that
///   populated the standard tags became visible.
/// - Deduplicated "Replacing previously registered class" log: only fires when the new
///   class is actually different, so test re-registrations of the same class don't spam.
private enum TextAttachmentRegistry {
  private static let lock = NSLock()
  nonisolated(unsafe) private static var lookup: [String: AnyClass] = [:]

  /// One-shot registration of the four built-in attachment subclasses. Lazily triggered
  /// by the first call to `register(_:forTagName:)` or `classForTagName(_:)` via
  /// `_ = bootstrap`. Runs exactly once under `swift_once` (release-published, so any
  /// thread that observes bootstrap being done also observes the four writes below).
  private static let bootstrap: Void = {
    // These writes happen inside swift_once and before bootstrap's result is published,
    // so they cannot race with any lock-protected reader or writer — readers block on
    // bootstrap's once-lock until this closure returns.
    lookup["img"] = ImageTextAttachment.self
    lookup["video"] = VideoTextAttachment.self
    lookup["iframe"] = IframeTextAttachment.self
    lookup["object"] = ObjectTextAttachment.self
  }()

  static func register(_ cls: AnyClass, forTagName tagName: String) {
    _ = bootstrap
    lock.lock()
    defer { lock.unlock() }
    if let previous = lookup[tagName], previous !== cls {
      NSLog(
        "Replacing previously registered class '%@' for tag name '%@' with '%@'",
        NSStringFromClass(previous), tagName, NSStringFromClass(cls))
    }
    lookup[tagName] = cls
  }

  static func classForTagName(_ tagName: String) -> AnyClass? {
    _ = bootstrap
    lock.lock()
    defer { lock.unlock() }
    return lookup[tagName]
  }
}

/// An object to represent an attachment in an HTML/rich text view.
@objc(DTTextAttachment)
open class TextAttachment: NSTextAttachment {

  @objc open var displaySize: CGSize = .zero
  @objc open var originalSize: CGSize {
    get { return _originalSize }
    set {
      if !newValue.equalTo(_originalSize) {
        _originalSize = newValue
        if displaySize.width == 0 || displaySize.height == 0 {
          setDisplaySize(newValue, withMaxDisplaySize: _maxImageSize)
        }
      }
    }
  }
  open var _originalSize: CGSize = .zero
  open var _maxImageSize: CGSize = .zero

  @objc public var contentURL: URL?
  @objc public var hyperLinkURL: URL?
  @objc public var hyperLinkGUID: String?

  @objc open var attributes: NSDictionary?

  @objc public var verticalAlignment: TextAttachmentVerticalAlignment = .baseline

  private var _fontLeading: CGFloat = 0
  private var _fontAscent: CGFloat = 0
  private var _fontDescent: CGFloat = 0

  // MARK: - Creating Text Attachments

  /// Factory method that returns the appropriate subclass for the given element's tag name.
  @objc public class func textAttachment(with element: HTMLElement, options: NSDictionary?)
    -> TextAttachment?
  {
    guard let cls = TextAttachmentRegistry.classForTagName(element.name) else {
      return nil
    }

    guard let attachmentClass = cls as? TextAttachment.Type else {
      return nil
    }

    let attachment = attachmentClass.init()
    return attachment.configured(with: element, options: options)
  }

  /// The designated initializer for members of the TextAttachment class cluster.
  @objc open func configured(with element: HTMLElement, options: NSDictionary?) -> Self {
    _originalSize = element.size

    _maxImageSize = .zero
    if let maxImageSizeValue = (options as? [String: Any])?[DTMaxImageSize as String] as? NSValue {
      #if canImport(UIKit)
        _maxImageSize = maxImageSizeValue.cgSizeValue
      #else
        _maxImageSize = maxImageSizeValue.sizeValue
      #endif
    }

    setDisplaySize(_originalSize, withMaxDisplaySize: _maxImageSize)

    attributes = element.attributes as NSDictionary?
    return self
  }

  // MARK: - NSCoding

  open override func encode(with coder: NSCoder) {
    super.encode(with: coder)
    coder.encode(displaySize, forKey: "displaySize")
    coder.encode(_originalSize, forKey: "originalSize")
    coder.encode(_maxImageSize, forKey: "maxImageSize")
    coder.encode(contentURL, forKey: "contentURL")
    coder.encode(attributes, forKey: "attributes")
    coder.encode(verticalAlignment.rawValue, forKey: "verticalAlignment")
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    displaySize = coder.decodeCGSize(forKey: "displaySize")
    _originalSize = coder.decodeCGSize(forKey: "originalSize")
    _maxImageSize = coder.decodeCGSize(forKey: "maxImageSize")
    contentURL = coder.decodeObject(forKey: "contentURL") as? URL
    attributes = coder.decodeObject(forKey: "attributes") as? NSDictionary
    verticalAlignment =
      TextAttachmentVerticalAlignment(
        rawValue: UInt(coder.decodeInteger(forKey: "verticalAlignment"))) ?? .baseline
  }

  public override init(data contentData: Data?, ofType uti: String?) {
    super.init(data: contentData, ofType: uti)
  }

  // MARK: - Vertical Alignment

  /// Inspects the given font and records the font's ascent, descent and leading.
  @objc public func adjustVerticalAlignment(for font: CTFont) {
    _fontLeading = CTFontGetLeading(font)
    _fontAscent = CTFontGetAscent(font)
    _fontDescent = CTFontGetDescent(font)
  }

  /// The ascent to use during layout
  @objc open func ascentForLayout() -> CGFloat {
    switch verticalAlignment {
    case .baseline:
      return displaySize.height
    case .top:
      return _fontAscent
    case .center:
      let halfHeight = (_fontAscent + _fontDescent) / 2.0
      return halfHeight - _fontDescent + displaySize.height / 2.0
    case .bottom:
      return displaySize.height - _fontDescent
    }
  }

  /// The descent to use during layout
  @objc open func descentForLayout() -> CGFloat {
    switch verticalAlignment {
    case .baseline:
      return 0
    case .top:
      return displaySize.height - _fontAscent
    case .center:
      let halfHeight = (_fontAscent + _fontDescent) / 2.0
      return halfHeight - _fontAscent + displaySize.height / 2.0
    case .bottom:
      return _fontDescent
    }
  }

  // MARK: - Display Size

  /// Updates the display size optionally passing a maximum size that it should not exceed.
  @objc public func setDisplaySize(_ displaySize: CGSize, withMaxDisplaySize maxDisplaySize: CGSize)
  {
    var size = displaySize

    if _originalSize.width != 0 && _originalSize.height != 0 {
      if size.width == 0 && size.height == 0 {
        size = _originalSize
      } else if size.width == 0 && size.height != 0 {
        let factor = _originalSize.height / size.height
        size.width = round(_originalSize.width / factor)
      } else if size.width != 0 && size.height == 0 {
        let factor = _originalSize.width / size.width
        size.height = round(_originalSize.height / factor)
      }
    }

    if maxDisplaySize.width > 0 && maxDisplaySize.height > 0 {
      if maxDisplaySize.width < size.width || maxDisplaySize.height < size.height {
        let scale = min(maxDisplaySize.width / size.width, maxDisplaySize.height / size.height)
        size = CGSize(width: round(size.width * scale), height: round(size.height * scale))
      }
    }

    self.displaySize = size
  }

  // MARK: - Subclass Customization

  /// Registers a class for use when encountering a specific tag name.
  ///
  /// Thread-safe. Re-registering the same class for a tag is a silent no-op; the
  /// "Replacing previously registered class" log only fires when the new class is
  /// actually different from the existing registration.
  @objc public class func registerClass(_ theClass: AnyClass, forTagName tagName: String) {
    TextAttachmentRegistry.register(theClass, forTagName: tagName)
  }

  /// The class to use for a tag name. Thread-safe.
  @objc public class func registeredClass(forTagName tagName: String) -> AnyClass? {
    return TextAttachmentRegistry.classForTagName(tagName)
  }
}

#if !canImport(UIKit)
  // On macOS, NSCoder doesn't have encodeCGSize/decodeCGSize by default, but
  // the ObjC code uses NSCoder+DTCompatibility which adds them for Mac.
  // Since we import DTCoreText which includes that category, they should be available.
#endif
