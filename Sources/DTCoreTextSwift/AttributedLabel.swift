//
//  AttributedLabel.swift
//  DTCoreText
//
//  Created by Brian Kenny on 1/17/13.
//  Copyright (c) 2013 Cocoanetics.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit
import QuartzCore

/// A rich-text replacement for `UILabel`, inheriting from `AttributedTextContentView`.
///
/// Unlike `AttributedTextContentView`, the intrinsic content size is only as wide as the text content.
/// Call `sizeToFit()` to shrink the label to that width.
@objc(DTAttributedLabel)
public class AttributedLabel: AttributedTextContentView {

	// MARK: - Layer

	override public class var layerClass: AnyClass {
		return CALayer.self
	}

	// MARK: - Setup

	private func setupAttributedLabel() {
		relayoutMask = [.onHeightChanged, .onWidthChanged]
		layoutFrameHeightIsConstrainedByBounds = true
	}

	// MARK: - Init

	public required init(frame: CGRect) {
		super.init(frame: frame)
		setupAttributedLabel()
	}

	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupAttributedLabel()
	}

	public override func awakeFromNib() {
		super.awakeFromNib()
		setupAttributedLabel()
	}

	// MARK: - Sizing

	public override var intrinsicContentSize: CGSize {
		guard let layoutFrame = self.layoutFrame else {
			return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
		}

		let contentSize = layoutFrame.intrinsicContentFrame().size
		return CGSize(
			width: contentSize.width + edgeInsets.left + edgeInsets.right,
			height: contentSize.height + edgeInsets.top + edgeInsets.bottom
		)
	}

	// MARK: - Properties

	/// The number of lines to display.
	@objc override public var numberOfLines: Int {
		didSet {
			if numberOfLines != oldValue {
				relayoutText()
			}
		}
	}

	/// The line break mode.
	@objc override public var lineBreakMode: NSLineBreakMode {
		didSet {
			if lineBreakMode != oldValue {
				relayoutText()
			}
		}
	}

	/// The attributed string appended when truncation occurs.
	@objc override public var truncationString: NSAttributedString? {
		didSet {
			if truncationString != oldValue {
				relayoutText()
			}
		}
	}
}

#endif
