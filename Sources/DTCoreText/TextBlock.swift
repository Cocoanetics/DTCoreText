//
//  TextBlock.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 04.03.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

import CoreGraphics
import Foundation

/// Class that represents a block of text with attributes like padding or a background color.
///
/// The API mirrors AppKit's `NSTextBlock` (which iOS gains natively with iOS 27) so that
/// instances can be converted 1:1 to the system class where it is available. All enum raw
/// values are identical to their AppKit counterparts; see the article
/// <doc:HTMLTablesOnMacOS> for the empirical basis.
///
/// Edges are identified by `CGRectEdge`, which has the same raw values as the `NSRectEdge`
/// used by `NSTextBlock` (`minXEdge` = leading/left, `minYEdge` = top, `maxXEdge` =
/// trailing/right, `maxYEdge` = bottom in the flipped text coordinate system).
///
/// Text blocks are built once during parsing and treated as immutable afterwards — the
/// same contract `NSAttributedString` requires of all attribute values. This makes them
/// safe to carry across concurrency domains, e.g. as typed values inside Swift's
/// `AttributedString`, hence the `@unchecked Sendable` conformance.
@objc(DTTextBlock)
public class TextBlock: NSObject, NSCoding, @unchecked Sendable {

  // MARK: - Constants

  /// The dimensions of a text block. Mirrors `NSTextBlock.Dimension`.
  @objc(DTTextBlockDimension)
  public enum Dimension: UInt, Sendable {
    case width = 0
    case minimumWidth = 1
    case maximumWidth = 2
    // note: raw value 3 is unused, matching AppKit
    case height = 4
    case minimumHeight = 5
    case maximumHeight = 6
  }

  /// The value type of a dimension or layer width. Mirrors `NSTextBlock.ValueType`.
  @objc(DTTextBlockValueType)
  public enum ValueType: UInt, Sendable {
    /// The value is an absolute length in points.
    case absoluteValueType = 0
    /// The value is a percentage of the enclosing block's dimension.
    case percentageValueType = 1
  }

  /// The layers of the block box model. Mirrors `NSTextBlock.Layer`.
  @objc(DTTextBlockLayer)
  public enum Layer: Int, Sendable {
    case padding = -1
    case border = 0
    case margin = 1
  }

  /// The vertical alignment of text within a block. Mirrors `NSTextBlock.VerticalAlignment`.
  @objc(DTTextBlockVerticalAlignment)
  public enum VerticalAlignment: UInt, Sendable {
    case topAlignment = 0
    case middleAlignment = 1
    case bottomAlignment = 2
    case baselineAlignment = 3
  }

  /// The drawing style of a border edge.
  ///
  /// This is a DTCoreText extension: `NSTextBlock` only models border width and color,
  /// so this information is dropped when converting to the AppKit/UIKit classes.
  /// A `none` border is modeled as a width of 0 instead of a style.
  @objc(DTTextBlockBorderStyle)
  public enum BorderStyle: UInt, Sendable {
    case solid = 0
    case dashed = 1
    case dotted = 2
    case double = 3
  }

  // MARK: - Storage

  // dimension storage is indexed by Dimension raw value; index 3 is unused like in AppKit
  private var dimensionValues = [CGFloat](repeating: 0, count: 7)
  private var dimensionValueTypes = [ValueType](repeating: .absoluteValueType, count: 7)

  // layer storage is indexed by [Layer raw value + 1][edge raw value]
  private var layerWidths = [[CGFloat]](repeating: [CGFloat](repeating: 0, count: 4), count: 3)
  private var layerWidthTypes = [[ValueType]](
    repeating: [ValueType](repeating: .absoluteValueType, count: 4), count: 3)

  // border colors and styles indexed by edge raw value
  private var borderColors = [DTColor?](repeating: nil, count: 4)
  private var borderStyles = [BorderStyle](repeating: .solid, count: 4)

  // MARK: - Properties

  /// The background color to paint behind the text in the receiver
  @objc public var backgroundColor: DTColor?

  /// The vertical alignment of text within the receiver.
  @objc public var verticalAlignment: VerticalAlignment = .topAlignment

  /// The space to be applied between the layouted text and the edges of the receiver.
  ///
  /// This is a convenience over the `.padding` layer with absolute values: `top` maps to
  /// the `minYEdge`, `left` to `minXEdge`, `bottom` to `maxYEdge` and `right` to `maxXEdge`.
  @objc public var padding: DTEdgeInsets {
    get {
      return DTEdgeInsets(
        top: width(for: .padding, edge: .minYEdge),
        left: width(for: .padding, edge: .minXEdge),
        bottom: width(for: .padding, edge: .maxYEdge),
        right: width(for: .padding, edge: .maxXEdge))
    }
    set {
      setWidth(newValue.top, type: .absoluteValueType, for: .padding, edge: .minYEdge)
      setWidth(newValue.left, type: .absoluteValueType, for: .padding, edge: .minXEdge)
      setWidth(newValue.bottom, type: .absoluteValueType, for: .padding, edge: .maxYEdge)
      setWidth(newValue.right, type: .absoluteValueType, for: .padding, edge: .maxXEdge)
    }
  }

  // MARK: - Initialization

  @objc public override init() {
    super.init()
  }

  // MARK: - Dimensions

  /// Sets a dimension of the block to the given value of the given value type.
  @objc(setValue:type:forDimension:)
  public func setValue(_ val: CGFloat, type: ValueType, for dimension: Dimension) {
    dimensionValues[Int(dimension.rawValue)] = val
    dimensionValueTypes[Int(dimension.rawValue)] = type
  }

  /// The value of the given dimension of the block.
  @objc(valueForDimension:)
  public func value(for dimension: Dimension) -> CGFloat {
    return dimensionValues[Int(dimension.rawValue)]
  }

  /// The value type of the given dimension of the block.
  @objc(valueTypeForDimension:)
  public func valueType(for dimension: Dimension) -> ValueType {
    return dimensionValueTypes[Int(dimension.rawValue)]
  }

  /// Convenience for setting the `.width` dimension.
  @objc(setContentWidth:type:)
  public func setContentWidth(_ val: CGFloat, type: ValueType) {
    setValue(val, type: type, for: .width)
  }

  /// The value of the `.width` dimension.
  @objc public var contentWidth: CGFloat {
    return value(for: .width)
  }

  /// The value type of the `.width` dimension.
  @objc public var contentWidthValueType: ValueType {
    return valueType(for: .width)
  }

  // MARK: - Layer Widths

  /// Sets the width of the given layer at the given edge.
  @objc(setWidth:type:forLayer:edge:)
  public func setWidth(_ val: CGFloat, type: ValueType, for layer: Layer, edge: CGRectEdge) {
    layerWidths[layer.rawValue + 1][Int(edge.rawValue)] = val
    layerWidthTypes[layer.rawValue + 1][Int(edge.rawValue)] = type
  }

  /// Sets the width of the given layer at all four edges.
  @objc(setWidth:type:forLayer:)
  public func setWidth(_ val: CGFloat, type: ValueType, for layer: Layer) {
    for edge: CGRectEdge in [.minXEdge, .minYEdge, .maxXEdge, .maxYEdge] {
      setWidth(val, type: type, for: layer, edge: edge)
    }
  }

  /// The width of the given layer at the given edge.
  @objc(widthForLayer:edge:)
  public func width(for layer: Layer, edge: CGRectEdge) -> CGFloat {
    return layerWidths[layer.rawValue + 1][Int(edge.rawValue)]
  }

  /// The value type of the given layer width at the given edge.
  @objc(widthValueTypeForLayer:edge:)
  public func widthValueType(for layer: Layer, edge: CGRectEdge) -> ValueType {
    return layerWidthTypes[layer.rawValue + 1][Int(edge.rawValue)]
  }

  // MARK: - Border Colors

  /// Sets the border color at the given edge.
  @objc(setBorderColor:forEdge:)
  public func setBorderColor(_ color: DTColor?, for edge: CGRectEdge) {
    borderColors[Int(edge.rawValue)] = color
  }

  /// Sets the border color at all four edges.
  @objc(setBorderColor:)
  public func setBorderColor(_ color: DTColor?) {
    for edge: CGRectEdge in [.minXEdge, .minYEdge, .maxXEdge, .maxYEdge] {
      setBorderColor(color, for: edge)
    }
  }

  /// The border color at the given edge.
  @objc(borderColorForEdge:)
  public func borderColor(for edge: CGRectEdge) -> DTColor? {
    return borderColors[Int(edge.rawValue)]
  }

  // MARK: - Border Styles (DTCoreText extension)

  /// Sets the border style at the given edge.
  @objc(setBorderStyle:forEdge:)
  public func setBorderStyle(_ style: BorderStyle, for edge: CGRectEdge) {
    borderStyles[Int(edge.rawValue)] = style
  }

  /// Sets the border style at all four edges.
  @objc(setBorderStyle:)
  public func setBorderStyle(_ style: BorderStyle) {
    for edge: CGRectEdge in [.minXEdge, .minYEdge, .maxXEdge, .maxYEdge] {
      setBorderStyle(style, for: edge)
    }
  }

  /// The border style at the given edge.
  @objc(borderStyleForEdge:)
  public func borderStyle(for edge: CGRectEdge) -> BorderStyle {
    return borderStyles[Int(edge.rawValue)]
  }

  // MARK: - NSCoding

  // Archive format version. Version 2 added the full NSTextBlock-style properties;
  // archives without the version key only carry "padding" and "backgroundColor".
  private static let archiveFormatVersion = 2

  @objc public required init?(coder aDecoder: NSCoder) {
    backgroundColor = aDecoder.decodeObject(forKey: "backgroundColor") as? DTColor

    super.init()

    if aDecoder.decodeInteger(forKey: "blockFormat") >= 2 {
      for index in 0..<dimensionValues.count {
        dimensionValues[index] = CGFloat(aDecoder.decodeDouble(forKey: "dimension.\(index).value"))
        dimensionValueTypes[index] =
          ValueType(rawValue: UInt(aDecoder.decodeInteger(forKey: "dimension.\(index).type")))
          ?? .absoluteValueType
      }

      for layerIndex in 0..<layerWidths.count {
        for edgeIndex in 0..<4 {
          let keyBase = "layer.\(layerIndex - 1).\(edgeIndex)"
          layerWidths[layerIndex][edgeIndex] = CGFloat(
            aDecoder.decodeDouble(forKey: "\(keyBase).width"))
          layerWidthTypes[layerIndex][edgeIndex] =
            ValueType(rawValue: UInt(aDecoder.decodeInteger(forKey: "\(keyBase).type")))
            ?? .absoluteValueType
        }
      }

      for edgeIndex in 0..<4 {
        borderColors[edgeIndex] = aDecoder.decodeObject(forKey: "borderColor.\(edgeIndex)")
          as? DTColor
        borderStyles[edgeIndex] =
          BorderStyle(rawValue: UInt(aDecoder.decodeInteger(forKey: "borderStyle.\(edgeIndex)")))
          ?? .solid
      }

      verticalAlignment =
        VerticalAlignment(rawValue: UInt(aDecoder.decodeInteger(forKey: "verticalAlignment")))
        ?? .topAlignment
    } else {
      // legacy archive that only contains padding and background color
      padding = aDecoder.decodeDTEdgeInsets(forKey: "padding")
    }
  }

  @objc public func encode(with aCoder: NSCoder) {
    // legacy keys, so that archives stay readable by older versions of DTCoreText
    aCoder.encodeDTEdgeInsets(padding, forKey: "padding")
    aCoder.encode(backgroundColor, forKey: "backgroundColor")

    aCoder.encode(Self.archiveFormatVersion, forKey: "blockFormat")

    for index in 0..<dimensionValues.count {
      if dimensionValues[index] != 0 {
        aCoder.encode(Double(dimensionValues[index]), forKey: "dimension.\(index).value")
      }
      if dimensionValueTypes[index] != .absoluteValueType {
        aCoder.encode(Int(dimensionValueTypes[index].rawValue), forKey: "dimension.\(index).type")
      }
    }

    for layerIndex in 0..<layerWidths.count {
      for edgeIndex in 0..<4 {
        let keyBase = "layer.\(layerIndex - 1).\(edgeIndex)"
        if layerWidths[layerIndex][edgeIndex] != 0 {
          aCoder.encode(Double(layerWidths[layerIndex][edgeIndex]), forKey: "\(keyBase).width")
        }
        if layerWidthTypes[layerIndex][edgeIndex] != .absoluteValueType {
          aCoder.encode(
            Int(layerWidthTypes[layerIndex][edgeIndex].rawValue), forKey: "\(keyBase).type")
        }
      }
    }

    for edgeIndex in 0..<4 {
      if let color = borderColors[edgeIndex] {
        aCoder.encode(color, forKey: "borderColor.\(edgeIndex)")
      }
      if borderStyles[edgeIndex] != .solid {
        aCoder.encode(Int(borderStyles[edgeIndex].rawValue), forKey: "borderStyle.\(edgeIndex)")
      }
    }

    if verticalAlignment != .topAlignment {
      aCoder.encode(Int(verticalAlignment.rawValue), forKey: "verticalAlignment")
    }
  }

  // MARK: - Equality & Hashing

  public override var hash: Int {
    // intentionally only based on padding and background color; equal objects hash
    // equally and unequal objects may collide, which keeps legacy hashes stable
    let padding = self.padding
    var calcHash = 7
    calcHash = calcHash &* 31 &+ (backgroundColor?.hash ?? 0)
    calcHash = calcHash &* 31 &+ Int(padding.left)
    calcHash = calcHash &* 31 &+ Int(padding.top)
    calcHash = calcHash &* 31 &+ Int(padding.right)
    calcHash = calcHash &* 31 &+ Int(padding.bottom)
    return calcHash
  }

  public override func isEqual(_ object: Any?) -> Bool {
    guard let object = object as? TextBlock, type(of: object) == type(of: self) else {
      return false
    }

    if object === self {
      return true
    }

    if dimensionValues != object.dimensionValues
      || dimensionValueTypes != object.dimensionValueTypes
    {
      return false
    }

    if layerWidths != object.layerWidths || layerWidthTypes != object.layerWidthTypes {
      return false
    }

    for edgeIndex in 0..<4 {
      let myColor = borderColors[edgeIndex]
      let otherColor = object.borderColors[edgeIndex]

      if myColor !== otherColor && !(myColor?.isEqual(otherColor) ?? (otherColor == nil)) {
        return false
      }
    }

    if verticalAlignment != object.verticalAlignment {
      return false
    }

    if borderStyles != object.borderStyles {
      return false
    }

    if object.backgroundColor === backgroundColor {
      return true
    }

    return object.backgroundColor == backgroundColor
  }
}
