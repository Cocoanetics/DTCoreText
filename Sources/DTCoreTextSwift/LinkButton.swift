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

public extension Notification.Name {
	/// Posted when a link button changes its highlighted state.
	static let dtLinkButtonDidHighlight = Notification.Name("DTLinkButtonDidHighlightNotification")
}

/// A button that corresponds to a hyperlink.
///
/// Multiple parts of the same hyperlink synchronize their highlighted appearance through a shared GUID.
@objc(DTLinkButton)
public class LinkButton: UIButton {

	/// The URL that this button corresponds to.
	@objc public var url: URL?

	/// The unique identifier that all parts of the same hyperlink share.
	@objc public var guid: String?

	/// The minimum size that the receiver should respond to hits with.
	@objc public var minimumHitSize: CGSize = .zero {
		didSet {
			guard minimumHitSize != oldValue else { return }
			adjustBoundsIfNecessary()
		}
	}

	/// Whether tapping the button causes it to show a gray rounded rectangle. Default is `true`.
	@objc public var showsTouchWhenHighlighted: Bool = true

	// MARK: - Init

	public override init(frame: CGRect) {
		super.init(frame: frame)

		isUserInteractionEnabled = true
		isEnabled = true
		isOpaque = false

		NotificationCenter.default.addObserver(self, selector: #selector(highlightNotification(_:)), name: .dtLinkButtonDidHighlight, object: nil)
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
		guard let ctx = UIGraphicsGetCurrentContext(), isHighlighted, showsTouchWhenHighlighted else { return }

		let imageRect = contentRect(forBounds: bounds)
		let roundedPath = UIBezierPath(roundedRect: imageRect, cornerRadius: 3.0)
		ctx.setFillColor(gray: 0.73, alpha: 0.4)
		roundedPath.fill()
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
			contentEdgeInsets = insets
		} else {
			contentEdgeInsets = .zero
		}
	}

	// MARK: - Synchronized Highlighting

	@objc private func highlightNotification(_ notification: Notification) {
		guard notification.object as AnyObject? !== self else { return }

		guard let userInfo = notification.userInfo,
			  let notificationGUID = userInfo["GUID"] as? String,
			  notificationGUID == guid else { return }

		let highlighted = (userInfo["Highlighted"] as? Bool) ?? false
		super.isHighlighted = highlighted
		setNeedsDisplay()
	}

	public override var isHighlighted: Bool {
		didSet {
			setNeedsDisplay()

			if let guid {
				let userInfo: [String: Any] = ["Highlighted": isHighlighted, "GUID": guid]
				NotificationCenter.default.post(name: .dtLinkButtonDidHighlight, object: self, userInfo: userInfo)
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
