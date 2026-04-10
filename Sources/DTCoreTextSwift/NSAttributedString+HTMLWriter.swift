//
//  NSAttributedString+HTMLWriter.swift
//  DTCoreText
//
//  Migrated from NSAttributedString+DTCoreText, April 2026.
//

import Foundation

extension NSAttributedString {

  /// Encodes the receiver into a full HTML document representation.
  @objc public func htmlString() -> String {
    let writer = HTMLWriter(attributedString: self)
    return writer.htmlString()
  }

  /// Encodes the receiver into an HTML fragment with inline styles.
  @objc public func htmlFragment() -> String {
    let writer = HTMLWriter(attributedString: self)
    return writer.htmlFragment()
  }
}
