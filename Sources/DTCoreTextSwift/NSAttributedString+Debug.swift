//
//  NSAttributedString+Debug.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 2013.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

import Foundation

extension NSAttributedString {

  /// Dumps the ranges and values of a given attribute to stdout.
  @objc(dumpRangesOfAttribute:)
  public func dumpRanges(of attribute: String) {
    var output = ""
    let entireRange = NSRange(location: 0, length: length)

    enumerateAttribute(NSAttributedString.Key(rawValue: attribute), in: entireRange, options: []) {
      value, range, _ in
      let rangeString = (string as NSString).substring(with: range)
      let valueString: String

      if let array = value as? [Any] {
        valueString = array.map { "\($0)" }.joined(separator: ", ")
      } else if let val = value {
        valueString = String(reflecting: val)
      } else {
        valueString = "(null)"
      }

      let escapedRange = rangeString.replacingOccurrences(of: "\n", with: "\\n")
      output += "\(NSStringFromRange(range)) \(valueString) '\(escapedRange)'\n"
    }

    print(output, terminator: "")
  }
}
