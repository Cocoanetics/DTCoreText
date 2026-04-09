//
//  DictationPlaceholderView.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 05.02.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// A dictation placeholder displaying 3 animated purple dots.
@objc(DTDictationPlaceholderView)
public class DictationPlaceholderView: UIView {

	// MARK: - Constants

	private static let dotWidth: CGFloat = 10.0
	private static let dotDistance: CGFloat = 2.5
	private static let dotOutsideMargin: CGFloat = 3.0

	// MARK: - State

	private var phase: Int = 0
	private var phaseTimer: Timer?

	/// An arbitrary context object, e.g. the selection range to replace with dictation result text.
	@objc public var context: AnyObject?

	// MARK: - Factory

	/// Creates an appropriately sized placeholder view with 3 animated purple dots.
	@objc
	public static func placeholderView() -> DictationPlaceholderView {
		return DictationPlaceholderView(frame: .zero)
	}

	// MARK: - Init

	public override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = .clear
		sizeToFit()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Layout

	public override func sizeThatFits(_ size: CGSize) -> CGSize {
		let w = Self.dotOutsideMargin * 2 + Self.dotWidth * 3 + Self.dotDistance * 2
		let h = Self.dotOutsideMargin * 2 + Self.dotWidth
		return CGSize(width: w, height: h)
	}

	// MARK: - Colors

	private var lightDotColor: UIColor {
		UIColor(red: 238.0 / 255.0, green: 128.0 / 255.0, blue: 238.0 / 255.0, alpha: 1.0)
	}

	private var darkDotColor: UIColor {
		UIColor(red: 191.0 / 255.0, green: 51.0 / 255.0, blue: 191.0 / 255.0, alpha: 1.0)
	}

	// MARK: - Timer

	public override func willMove(toSuperview newSuperview: UIView?) {
		super.willMove(toSuperview: newSuperview)

		phaseTimer?.invalidate()
		phaseTimer = nil

		if newSuperview != nil {
			phaseTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(phaseTimerTick), userInfo: nil, repeats: true)
		}
	}

	@objc private func phaseTimerTick() {
		phase = (phase + 1) % 3
		setNeedsDisplay()
	}

	// MARK: - Drawing

	public override func draw(_ rect: CGRect) {
		guard let ctx = UIGraphicsGetCurrentContext() else { return }

		var dotRect = CGRect(x: Self.dotOutsideMargin, y: 4, width: Self.dotWidth, height: Self.dotWidth)

		for i in 0..<3 {
			let color = (phase == i) ? darkDotColor : lightDotColor
			ctx.setFillColor(color.cgColor)
			ctx.fillEllipse(in: dotRect)
			dotRect.origin.x = dotRect.maxX + Self.dotDistance
		}
	}
}

#endif
