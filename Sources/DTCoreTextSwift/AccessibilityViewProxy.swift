//
//  AccessibilityViewProxy.swift
//  DTCoreText
//
//  Created by Austen Green on 5/6/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

#if canImport(UIKit) && !os(watchOS)
  import UIKit

  /// Protocol to provide custom views for accessibility elements representing a TextAttachment.
  @objc(DTAccessibilityViewProxyDelegate)
  public protocol AccessibilityViewProxyDelegate {
    /// Provides a view for an attachment.
    func view(for attachment: TextAttachment, proxy: AccessibilityViewProxy) -> UIView?
  }

  /// UIView proxy for DTAttributedTextContentView custom subviews for text attachments.
  @objc(DTAccessibilityViewProxy)
  public class AccessibilityViewProxy: NSObject {

    @objc public private(set) weak var delegate: (any AccessibilityViewProxyDelegate)?
    @objc public private(set) var textAttachment: TextAttachment

    @objc
    public init(textAttachment: TextAttachment, delegate: any AccessibilityViewProxyDelegate) {
      self.textAttachment = textAttachment
      self.delegate = delegate
    }

    private func proxiedView() -> UIView? {
      delegate?.view(for: textAttachment, proxy: self)
    }

    // Forward unknown selectors to the proxied view
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
      proxiedView()
    }

    public override func responds(to aSelector: Selector!) -> Bool {
      if super.responds(to: aSelector) { return true }
      return proxiedView()?.responds(to: aSelector) ?? false
    }

    public override func isEqual(_ object: Any?) -> Bool {
      proxiedView()?.isEqual(object) ?? false
    }

    public override var hash: Int {
      proxiedView()?.hash ?? super.hash
    }
  }

#endif
