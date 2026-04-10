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
  public class AttributedTextView: UIScrollView {

    // MARK: - Content View

    /// Subclasses can access this ivar directly.
    @objc public var _attributedTextContentView: AttributedTextContentView?

    // MARK: - Private State

    private var _backgroundView: UIView?
    private weak var _textDelegate: (any DTAttributedTextContentViewDelegate)?
    private var _attributedString: NSAttributedString?
    private var _shouldDrawLinks = true
    private var _shouldDrawImages = true

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
      _shouldDrawLinks = true
      _shouldDrawImages = true
    }

    // MARK: - Layout

    public override func layoutSubviews() {
      super.layoutSubviews()
      attributedTextContentView.edgeInsets = contentInset
      _attributedTextContentView?.layoutSubviews(in: bounds)
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
      _attributedTextContentView?.layouter = nil
      _attributedTextContentView?.relayoutText()
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
        _attributedTextContentView?.frame = frameToSet
        contentSize = _attributedTextContentView?.intrinsicContentSize ?? .zero
      }
    }

    // MARK: - Properties

    /// The attributed text content view (created lazily).
    @objc public var attributedTextContentView: AttributedTextContentView {
      if let existing = _attributedTextContentView {
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
        if !(layerClass is CATiledLayer.Type) {
          AttributedTextContentView.setLayerClass(CATiledLayer.self)
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

      contentView.delegate = _textDelegate
      contentView.shouldDrawLinks = _shouldDrawLinks

      NotificationCenter.default.addObserver(
        self,
        selector: #selector(contentViewDidLayout(_:)),
        name: NSNotification.Name(DTAttributedTextContentViewDidFinishLayoutNotification),
        object: contentView)

      contentView.frame = frame
      contentView.attributedString = _attributedString

      addSubview(contentView)
      _attributedTextContentView = contentView

      return contentView
    }

    @objc public override var backgroundColor: UIColor? {
      get { super.backgroundColor }
      set {
        if let newColor = newValue, newColor.cgColor.alpha < 1.0 {
          super.backgroundColor = newColor
          _attributedTextContentView?.backgroundColor = .clear
          isOpaque = false
        } else {
          super.backgroundColor = newValue
          if _attributedTextContentView?.isOpaque == true {
            _attributedTextContentView?.backgroundColor = newValue
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
          height: _attributedTextContentView?.frame.size.height ?? 0)
        if _attributedTextContentView?.frame != contentFrame {
          _attributedTextContentView?.frame = contentFrame
        }
      }
    }

    /// The attributed string to display.
    @objc public var attributedString: NSAttributedString? {
      get { _attributedString }
      set {
        _attributedString = newValue
        setNeedsLayout()
        _attributedTextContentView?.attributedString = newValue
      }
    }

    /// Delegate for providing custom views for images and links.
    @objc public weak var textDelegate: (any DTAttributedTextContentViewDelegate)? {
      get { _attributedTextContentView?.delegate ?? _textDelegate }
      set {
        _textDelegate = newValue
        _attributedTextContentView?.delegate = newValue
      }
    }

    /// Whether the content view should draw links.
    @objc public var shouldDrawLinks: Bool {
      get { _shouldDrawLinks }
      set {
        _shouldDrawLinks = newValue
        _attributedTextContentView?.shouldDrawLinks = newValue
      }
    }

    /// Whether the content view should draw images.
    @objc public var shouldDrawImages: Bool {
      get { _shouldDrawImages }
      set {
        _shouldDrawImages = newValue
        _attributedTextContentView?.shouldDrawImages = newValue
      }
    }

    /// A view displayed behind the text content.
    @objc public var backgroundView: UIView? {
      get {
        if _backgroundView == nil {
          let bg = UIView(frame: bounds)
          bg.backgroundColor = .white
          bg.isUserInteractionEnabled = false
          insertSubview(bg, belowSubview: attributedTextContentView)
          _attributedTextContentView?.backgroundColor = .clear
          _attributedTextContentView?.isOpaque = false
          _backgroundView = bg
        }
        return _backgroundView
      }
      set {
        guard _backgroundView !== newValue else { return }
        _backgroundView?.removeFromSuperview()
        _backgroundView = newValue

        if let newValue {
          if let contentView = _attributedTextContentView {
            insertSubview(newValue, belowSubview: contentView)
          } else {
            addSubview(newValue)
          }
          _attributedTextContentView?.backgroundColor = .clear
          _attributedTextContentView?.isOpaque = false
        } else {
          _attributedTextContentView?.backgroundColor = .white
          _attributedTextContentView?.isOpaque = true
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
              height: _attributedTextContentView?.frame.size.height ?? 0)
            _attributedTextContentView?.frame = contentFrame
          }
        }
      }
    }
  }

#endif
