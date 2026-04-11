//
//  LinkButton.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/16/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

#if canImport(UIKit) && !os(watchOS)
  import UIKit

  extension Notification.Name {
    /// Posted when a link button changes its highlighted state.
    public static let dtLinkButtonDidHighlight = Notification.Name(
      "DTLinkButtonDidHighlightNotification")
  }

  /// A button that corresponds to a hyperlink.
  ///
  /// Multiple parts of the same hyperlink synchronize their highlighted appearance through a shared GUID.
  @objc(DTLinkButton)
  public class LinkButton: UIButton {

    /// The URL that this button corresponds to.
    @objc(URL) public var url: URL?

    /// The unique identifier that all parts of the same hyperlink share.
    @objc(GUID) public var guid: String?

    /// The minimum size that the receiver should respond to hits with.
    @objc public var minimumHitSize: CGSize = .zero {
      didSet {
        guard minimumHitSize != oldValue else { return }
        adjustBoundsIfNecessary()
      }
    }

    /// Insets recording how much the bounds were grown beyond the button's natural
    /// content size to accommodate `minimumHitSize`. Tracked locally instead of on
    /// `UIButton.contentEdgeInsets` (deprecated in iOS 15, routes through
    /// `UIButton.Configuration` which we intentionally don't use — see `init(frame:)`).
    /// Used by `draw(_:)` to compute the inner content rect and by `layoutSubviews()`
    /// to re-center the image and title subviews inside the enlarged bounds.
    private var hitSizeInsets: UIEdgeInsets = .zero

    // MARK: - Init

    /// Whether to show a highlight effect when the user touches the button.
    @objc public var showsHighlightOnTouch: Bool = true

    public override init(frame: CGRect) {
      super.init(frame: frame)

      isUserInteractionEnabled = true
      isEnabled = true
      isOpaque = false

      // Use classic (non-Configuration) UIButton behavior so that
      // setImage(_:for:) and drawRect-based highlighting work the same
      // way they did in the ObjC DTLinkButton. Assigning a
      // UIButton.Configuration here would switch the button to the modern
      // configuration-based image pipeline, where setImage(_:for:) is
      // not honored — the button would remain visually empty and the
      // custom drawRect highlight would never fire.

      NotificationCenter.default.addObserver(
        self, selector: #selector(highlightNotification(_:)), name: .dtLinkButtonDidHighlight,
        object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    deinit {
      NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Drawing

    public override func draw(_ rect: CGRect) {
      guard let ctx = UIGraphicsGetCurrentContext(), isHighlighted, showsHighlightOnTouch else {
        return
      }

      // The content lives inside the (possibly-enlarged) bounds, offset by our tracked
      // hit-size insets — equivalent to the old `contentRect(forBounds:)` call.
      let imageRect = bounds.inset(by: hitSizeInsets)
      let roundedPath = UIBezierPath(roundedRect: imageRect, cornerRadius: 3.0)
      ctx.setFillColor(gray: 0.73, alpha: 0.4)
      roundedPath.fill()
    }

    // MARK: - Layout

    public override func layoutSubviews() {
      super.layoutSubviews()

      // `UIButton.contentEdgeInsets` is deprecated since iOS 15 and we're intentionally
      // not using `UIButton.Configuration`, so we position `imageView` and `titleLabel`
      // ourselves to compensate for the extra hit-test bounds we added in
      // `adjustBoundsIfNecessary()`. Without this, `super.layoutSubviews()` lays them
      // out in the top-left of the enlarged bounds.
      guard hitSizeInsets != .zero else { return }

      if let iv = imageView, !iv.isHidden {
        iv.frame = iv.frame.offsetBy(dx: hitSizeInsets.left, dy: hitSizeInsets.top)
      }
      if let tl = titleLabel, !tl.isHidden {
        tl.frame = tl.frame.offsetBy(dx: hitSizeInsets.left, dy: hitSizeInsets.top)
      }
    }

    // MARK: - Hit Size Adjustment

    private func adjustBoundsIfNecessary() {
      var currentBounds = bounds
      var widthExtend: CGFloat = 0
      var heightExtend: CGFloat = 0

      if currentBounds.size.width < minimumHitSize.width {
        widthExtend = minimumHitSize.width - currentBounds.size.width
      }

      if currentBounds.size.height < minimumHitSize.height {
        heightExtend = minimumHitSize.height - currentBounds.size.height
      }

      if widthExtend > 0 || heightExtend > 0 {
        let insets = UIEdgeInsets(
          top: ceil(heightExtend / 2.0),
          left: ceil(widthExtend / 2.0),
          bottom: ceil(heightExtend / 2.0),
          right: ceil(widthExtend / 2.0)
        )
        currentBounds.size.width += insets.left + insets.right
        currentBounds.size.height += insets.top + insets.bottom
        bounds = currentBounds
        hitSizeInsets = insets
      } else {
        hitSizeInsets = .zero
      }
      setNeedsLayout()
    }

    // MARK: - Synchronized Highlighting

    @objc private func highlightNotification(_ notification: Notification) {
      guard notification.object as AnyObject? !== self else { return }

      guard let userInfo = notification.userInfo,
        let notificationGUID = userInfo["GUID"] as? String,
        notificationGUID == guid
      else { return }

      let highlighted = (userInfo["Highlighted"] as? Bool) ?? false
      super.isHighlighted = highlighted
      setNeedsDisplay()
    }

    public override var isHighlighted: Bool {
      didSet {
        setNeedsDisplay()

        if let guid {
          let userInfo: [String: Any] = ["Highlighted": isHighlighted, "GUID": guid]
          NotificationCenter.default.post(
            name: .dtLinkButtonDidHighlight, object: self, userInfo: userInfo)
        }
      }
    }

    // MARK: - Frame

    public override var frame: CGRect {
      didSet {
        guard !frame.isEmpty else { return }
        adjustBoundsIfNecessary()
      }
    }
  }

#endif
