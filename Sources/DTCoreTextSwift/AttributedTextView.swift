//
//  AttributedTextView.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

#if canImport(UIKit) && !os(watchOS)
  import UIKit
  import QuartzCore

  /// A `UIScrollView` subclass that displays a `AttributedTextContentView`
  /// as its content view. Replacement for `UITextView` with rich text.
  @objc(DTAttributedTextView)
  open class AttributedTextView: UIScrollView {

    // MARK: - Content View

    /// Subclasses can access this ivar directly.
    @objc public var attributedTextContentView: AttributedTextContentView?

    // MARK: - Private State

    private var backgroundViewStorage: UIView?
    private weak var textDelegate: (any DTAttributedTextContentViewDelegate)?
    private var attributedStringStorage: NSAttributedString?
    private var shouldDrawLinksStorage = true
    private var shouldDrawImagesStorage = true

    // MARK: - Init

    public override init(frame: CGRect) {
      super.init(frame: frame)
      setup()
    }

    public required init?(coder: NSCoder) {
      super.init(coder: coder)
    }

    deinit {
      NotificationCenter.default.removeObserver(self)
    }

    public override func awakeFromNib() {
      super.awakeFromNib()
      MainActor.assumeIsolated {
        setup()
      }
    }

    private func setup() {
      if let bg = backgroundColor {
        isOpaque = bg.cgColor.alpha >= 1.0
      } else {
        backgroundColor = .white
        isOpaque = true
      }

      autoresizesSubviews = false
      clipsToBounds = true
      shouldDrawLinksStorage = true
      shouldDrawImagesStorage = true
    }

    // MARK: - Layout

    public override func layoutSubviews() {
      super.layoutSubviews()
      // The content view's frame is already sized to exclude the scroll
      // view's `contentInset` (see `attributedTextContentView` getter),
      // so the content view itself must NOT apply any additional edge
      // insets — otherwise the text layout rect is insetted twice and
      // block-level attachments sized against the outer inset (e.g. an
      // iframe using `view.bounds.width - 20`) overflow the content
      // view's right edge by the second inset.
      attributedTextContentView.edgeInsets = .zero
      attributedTextContentView?.layoutSubviews(in: bounds)
    }

    public override func safeAreaInsetsDidChange() {
      super.safeAreaInsetsDidChange()
    }

    // MARK: - Content View Class

    /// Override to provide a custom `AttributedTextContentView` subclass.
    @objc open func classForContentView() -> AnyClass {
      AttributedTextContentView.self
    }

    // MARK: - Public Methods

    /// Scrolls to the anchor with the given name.
    @objc(scrollToAnchorNamed:animated:)
    public func scrollToAnchor(named anchorName: String, animated: Bool) {
      let range =
        attributedTextContentView.attributedString?.rangeOfAnchorNamed(anchorName)
        ?? NSRange(location: NSNotFound, length: 0)
      if range.location != NSNotFound {
        scrollRangeToVisible(range, animated: animated)
      }
    }

    /// Scrolls until the given text range is visible.
    @objc public func scrollRangeToVisible(_ range: NSRange, animated: Bool) {
      guard
        let line = attributedTextContentView.layoutFrame?.lineContaining(
          index: UInt(range.location))
      else { return }
      let maxScrollPos =
        contentSize.height - bounds.size.height + contentInset.bottom + contentInset.top
      let scrollPos = min(line.frame.origin.y, maxScrollPos)
      setContentOffset(CGPoint(x: 0, y: scrollPos), animated: animated)
    }

    /// Performs a new text layout pass.
    @objc public func relayoutText() {
      // We're already main-actor-isolated; the content view's layouter must be
      // reset on the main thread.
      attributedTextContentView?.layouter = nil
      attributedTextContentView?.relayoutText()
      setNeedsLayout()
    }

    // MARK: - Cursor

    /// Closest string index to a point in the receiver's frame.
    @objc(closestCursorIndexToPoint:)
    public func closestCursorIndex(to point: CGPoint) -> Int {
      let pointInContentView = attributedTextContentView.convert(point, from: self)
      return attributedTextContentView.closestCursorIndex(to: pointInContentView)
    }

    /// Rectangle for drawing a caret at the given index.
    @objc public func cursorRect(atIndex index: Int) -> CGRect {
      let rectInContentView = attributedTextContentView.cursorRect(atIndex: index)
      return attributedTextContentView.convert(rectInContentView, to: self)
    }

    // MARK: - Notifications

    @objc private func contentViewDidLayout(_ notification: Notification) {
      // The content view always posts this notification while main-actor-isolated;
      // no need to hop threads.
      guard let userInfo = notification.userInfo,
        let optimalFrame = (userInfo["OptimalFrame"] as? NSValue)?.cgRectValue
      else { return }

      // Use bounds.size — not bounds.inset(by:) — because a scroll view's
      // bounds.origin reflects its contentOffset, which is negative when
      // contentInsetAdjustmentBehavior pushes content below a nav bar. That
      // would make the inset frame start with a negative origin.y.
      let availableWidth = bounds.size.width - contentInset.left - contentInset.right

      if optimalFrame.size.width == availableWidth {
        // Always position the content view at (0, 0) in the scroll view's
        // content coordinate space. The scroll view itself handles pushing
        // content down for the adjusted content inset.
        var frameToSet = optimalFrame
        frameToSet.origin = .zero
        attributedTextContentView?.frame = frameToSet
        contentSize = attributedTextContentView?.intrinsicContentSize ?? .zero
      }
    }

    // MARK: - Properties

    /// The attributed text content view (created lazily).
    @objc public var attributedTextContentView: AttributedTextContentView {
      if let existing = attributedTextContentView {
        return existing
      }

      let classToUse = classForContentView() as! AttributedTextContentView.Type
      // Place the content view at (0, 0) in the scroll view's content
      // coordinate space. We must NOT use bounds.inset(by:) because
      // UIScrollView's bounds.origin reflects contentOffset, which becomes
      // negative when contentInsetAdjustmentBehavior pushes content below a
      // nav bar — that would leave the content view with a negative origin.
      var frame = CGRect(
        x: 0,
        y: 0,
        width: bounds.size.width - contentInset.left - contentInset.right,
        height: bounds.size.height - contentInset.top - contentInset.bottom)

      if frame.size.width <= 0 || frame.size.height <= 0 {
        frame = .zero
      }

      // Force a tiled layer for content views so long documents render
      // incrementally on background tile threads. The content view's
      // `draw(_:in:)` is `nonisolated` and reads drawing state from a locked
      // `RenderSnapshot` mirror updated on the main actor, so this is safe
      // with Swift Concurrency's main-actor isolation check.
      var previousLayerClass: AnyClass?
      if classToUse.isSubclass(of: AttributedTextContentView.self) {
        let layerClass: AnyClass = AttributedTextContentView.layerClass
        if layerClass != TiledLayerWithoutFade.self {
          AttributedTextContentView.setLayerClass(TiledLayerWithoutFade.self)
          previousLayerClass = layerClass
        }
      }

      let contentView = classToUse.init(frame: frame)

      if let previousLayerClass {
        AttributedTextContentView.setLayerClass(previousLayerClass)
      }

      contentView.isUserInteractionEnabled = true
      contentView.backgroundColor = backgroundColor
      contentView.shouldLayoutCustomSubviews = false

      if let bg = backgroundColor {
        contentView.isOpaque = bg.cgColor.alpha >= 1.0
      }

      contentView.delegate = textDelegate
      contentView.shouldDrawLinks = shouldDrawLinksStorage

      NotificationCenter.default.addObserver(
        self,
        selector: #selector(contentViewDidLayout(_:)),
        name: NSNotification.Name(DTAttributedTextContentViewDidFinishLayoutNotification),
        object: contentView)

      contentView.frame = frame
      contentView.attributedString = attributedStringStorage

      addSubview(contentView)
      attributedTextContentView = contentView

      return contentView
    }

    @objc public override var backgroundColor: UIColor? {
      get { super.backgroundColor }
      set {
        if let newColor = newValue, newColor.cgColor.alpha < 1.0 {
          super.backgroundColor = newColor
          attributedTextContentView?.backgroundColor = .clear
          isOpaque = false
        } else {
          super.backgroundColor = newValue
          if attributedTextContentView?.isOpaque == true {
            attributedTextContentView?.backgroundColor = newValue
          }
        }
      }
    }

    public override var contentInset: UIEdgeInsets {
      get { super.contentInset }
      set {
        super.contentInset = newValue
        let contentFrame = CGRect(
          x: 0, y: 0,
          width: frame.size.width - newValue.left - newValue.right,
          height: attributedTextContentView?.frame.size.height ?? 0)
        if attributedTextContentView?.frame != contentFrame {
          attributedTextContentView?.frame = contentFrame
        }
      }
    }

    /// The attributed string to display.
    @objc public var attributedString: NSAttributedString? {
      get { attributedStringStorage }
      set {
        attributedStringStorage = newValue
        setNeedsLayout()
        attributedTextContentView?.attributedString = newValue
      }
    }

    /// Delegate for providing custom views for images and links.
    @objc public weak var textDelegate: (any DTAttributedTextContentViewDelegate)? {
      get { attributedTextContentView?.delegate ?? textDelegate }
      set {
        textDelegate = newValue
        attributedTextContentView?.delegate = newValue
      }
    }

    /// Whether the content view should draw links.
    @objc public var shouldDrawLinks: Bool {
      get { shouldDrawLinksStorage }
      set {
        shouldDrawLinksStorage = newValue
        attributedTextContentView?.shouldDrawLinks = newValue
      }
    }

    /// Whether the content view should draw images.
    @objc public var shouldDrawImages: Bool {
      get { shouldDrawImagesStorage }
      set {
        shouldDrawImagesStorage = newValue
        attributedTextContentView?.shouldDrawImages = newValue
      }
    }

    /// A view displayed behind the text content.
    @objc public var backgroundView: UIView? {
      get {
        if backgroundViewStorage == nil {
          let bg = UIView(frame: bounds)
          bg.backgroundColor = .white
          bg.isUserInteractionEnabled = false
          insertSubview(bg, belowSubview: attributedTextContentView)
          attributedTextContentView?.backgroundColor = .clear
          attributedTextContentView?.isOpaque = false
          backgroundViewStorage = bg
        }
        return backgroundViewStorage
      }
      set {
        guard backgroundViewStorage !== newValue else { return }
        backgroundViewStorage?.removeFromSuperview()
        backgroundViewStorage = newValue

        if let newValue {
          if let contentView = attributedTextContentView {
            insertSubview(newValue, belowSubview: contentView)
          } else {
            addSubview(newValue)
          }
          attributedTextContentView?.backgroundColor = .clear
          attributedTextContentView?.isOpaque = false
        } else {
          attributedTextContentView?.backgroundColor = .white
          attributedTextContentView?.isOpaque = true
        }
      }
    }

    public override var frame: CGRect {
      get { super.frame }
      set {
        let oldFrame = super.frame
        if oldFrame != newValue {
          super.frame = newValue
          if oldFrame.size.width != newValue.size.width {
            let contentFrame = CGRect(
              x: 0, y: 0,
              width: newValue.size.width - contentInset.left - contentInset.right,
              height: attributedTextContentView?.frame.size.height ?? 0)
            attributedTextContentView?.frame = contentFrame
          }
        }
      }
    }
  }

#endif
