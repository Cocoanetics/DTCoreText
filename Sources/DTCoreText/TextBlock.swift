//
//  TextBlock.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 04.03.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

import Foundation

/// Class that represents a block of text with attributes like padding or a background color.
@objc(DTTextBlock)
public class TextBlock: NSObject, NSCoding {

  /// The space to be applied between the layouted text and the edges of the receiver
  @objc public var padding: DTEdgeInsets

  /// The background color to paint behind the text in the receiver
  @objc public var backgroundColor: DTColor?

  @objc public override init() {
    self.padding = DTEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    self.backgroundColor = nil
    super.init()
  }

  // MARK: - NSCoding

  @objc public required init?(coder aDecoder: NSCoder) {
    self.padding = aDecoder.decodeDTEdgeInsets(forKey: "padding")
    self.backgroundColor = aDecoder.decodeObject(forKey: "backgroundColor") as? DTColor
    super.init()
  }

  @objc public func encode(with aCoder: NSCoder) {
    aCoder.encodeDTEdgeInsets(padding, forKey: "padding")
    aCoder.encode(backgroundColor, forKey: "backgroundColor")
  }

  // MARK: - Equality & Hashing

  public override var hash: Int {
    var calcHash = 7
    calcHash = calcHash &* 31 &+ (backgroundColor?.hash ?? 0)
    calcHash = calcHash &* 31 &+ Int(padding.left)
    calcHash = calcHash &* 31 &+ Int(padding.top)
    calcHash = calcHash &* 31 &+ Int(padding.right)
    calcHash = calcHash &* 31 &+ Int(padding.bottom)
    return calcHash
  }

  public override func isEqual(_ object: Any?) -> Bool {
    guard let object = object as? TextBlock else {
      return false
    }

    if object === self {
      return true
    }

    if padding.left != object.padding.left || padding.top != object.padding.top
      || padding.right != object.padding.right || padding.bottom != object.padding.bottom
    {
      return false
    }

    if object.backgroundColor === backgroundColor {
      return true
    }

    return object.backgroundColor == backgroundColor
  }
}
