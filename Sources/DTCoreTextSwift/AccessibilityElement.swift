//
//  AccessibilityElement.swift
//  DTCoreText
//
//  Created by Austen Green on 3/13/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

#if canImport(UIKit) && !os(watchOS)
  import UIKit

  private let nullActivationPoint = CGPoint(
    x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)

  /// A UIAccessibilityElement subclass that converts its local accessibilityFrame to screen coordinates.
  @objc(DTAccessibilityElement)
  public class AccessibilityElement: UIAccessibilityElement {

    /// The frame in the parent view's coordinate system.
    @objc public var localCoordinateAccessibilityFrame: CGRect = .zero

    /// The activation point in the parent view's coordinate system.
    @objc public var localCoordinateAccessibilityActivationPoint: CGPoint = nullActivationPoint

    private weak var parentView: UIView?

    /// Creates an element with the given parent view as its accessibility container.
    @objc
    public init(parentView: UIView) {
      self.parentView = parentView
      super.init(accessibilityContainer: parentView)
    }

    public override var accessibilityFrame: CGRect {
      get {
        guard let window = parentView?.window else { return localCoordinateAccessibilityFrame }
        return window.convert(localCoordinateAccessibilityFrame, from: parentView)
      }
      set { super.accessibilityFrame = newValue }
    }

    public override var accessibilityActivationPoint: CGPoint {
      get {
        var point = localCoordinateAccessibilityActivationPoint
        if point == nullActivationPoint {
          point = super.accessibilityActivationPoint
        }
        guard let window = parentView?.window else { return point }
        return window.convert(point, from: parentView)
      }
      set { super.accessibilityActivationPoint = newValue }
    }
  }

#endif
