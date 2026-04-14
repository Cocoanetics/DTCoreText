//
//  DTTextList.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 8/11/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// `DTTextList` is a subclass of `NSTextList` that adds the CSS-specific metadata
/// DTCoreText needs (marker position, custom image bullets, and non-standard marker
/// types like `plus`, `underscore`, and `decimal-leading-zero`). The underlying
/// `markerFormat` and `startingItemNumber` are stored on the `NSTextList` superclass,
/// so instances interoperate with any TextKit API that expects an `NSTextList`.
public class DTTextList: NSTextList {

  // MARK: - Additional Properties

  /// Image name for a custom bullet (`list-style-image: url(...)`).
  public var imageName: String?

  /// Position of the marker within the list item (`list-style-position`).
  public var position: DTTextListPosition = .outside

  /// Non-native marker type, if any. `nil` means the `markerFormat` on the
  /// `NSTextList` superclass is the source of truth.
  public var customMarker: DTTextListCustomMarker?

  /// True if the entire list style was specified as `list-style: inherit`.
  public var inheritStyle: Bool = false

  // MARK: - NSSecureCoding

  public override class var supportsSecureCoding: Bool { true }

  // MARK: - Initialization

  public override init(
    markerFormat: NSTextList.MarkerFormat, options: NSTextList.Options = [],
    startingItemNumber: Int
  ) {
    super.init(
      markerFormat: markerFormat, options: options, startingItemNumber: startingItemNumber)
  }

  /// Creates a list from a CSS styles dictionary.
  public convenience init(styles: [String: Any]) {
    let parsed = DTTextList.parseStyles(styles)
    // NSTextList's designated init coerces `startingItemNumber: 0` to 1, so we init with
    // 1 and then override via the setter for unordered lists — matching Apple's convention
    // where `<ul>` lists report `startingItemNumber == 0`.
    self.init(markerFormat: parsed.format, startingItemNumber: 1)
    if !DTTextList.isOrderedMarker(format: parsed.format, customMarker: parsed.customMarker) {
      self.startingItemNumber = 0
    }
    self.imageName = parsed.imageName
    self.position = parsed.position
    self.customMarker = parsed.customMarker
    self.inheritStyle = parsed.inheritStyle
  }

  /// Static variant of `isOrdered` usable before `self.init` has run.
  private static func isOrderedMarker(
    format: NSTextList.MarkerFormat, customMarker: DTTextListCustomMarker?
  ) -> Bool {
    if let custom = customMarker {
      return custom == .decimalLeadingZero
    }
    switch format {
    case .decimal, .lowercaseAlpha, .uppercaseAlpha, .lowercaseLatin, .uppercaseLatin,
      .lowercaseRoman, .uppercaseRoman:
      return true
    default:
      return false
    }
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    self.imageName = coder.decodeObject(of: NSString.self, forKey: "dt_imageName") as String?
    self.position =
      DTTextListPosition(rawValue: coder.decodeInteger(forKey: "dt_position")) ?? .outside
    let cmRaw = coder.decodeInteger(forKey: "dt_customMarker")
    self.customMarker = (cmRaw < 0) ? nil : DTTextListCustomMarker(rawValue: cmRaw)
    self.inheritStyle = coder.decodeBool(forKey: "dt_inheritStyle")
  }

  public override func encode(with coder: NSCoder) {
    super.encode(with: coder)
    coder.encode(imageName as NSString?, forKey: "dt_imageName")
    coder.encode(position.rawValue, forKey: "dt_position")
    coder.encode(customMarker?.rawValue ?? -1, forKey: "dt_customMarker")
    coder.encode(inheritStyle, forKey: "dt_inheritStyle")
  }

  // MARK: - NSCopying

  public override func copy(with zone: NSZone? = nil) -> Any {
    let copy = DTTextList(markerFormat: self.markerFormat, startingItemNumber: self.startingItemNumber)
    copy.startingItemNumber = self.startingItemNumber
    copy.imageName = self.imageName
    copy.position = self.position
    copy.customMarker = self.customMarker
    copy.inheritStyle = self.inheritStyle
    return copy
  }

  // MARK: - Equality

  public override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? DTTextList else { return false }
    return isEqualTo(other)
  }

  public override var hash: Int {
    var h = markerFormat.rawValue.hashValue
    h = h &* 31 &+ startingItemNumber
    h = h &* 31 &+ (imageName?.hashValue ?? 0)
    h = h &* 31 &+ position.hashValue
    h = h &* 31 &+ (customMarker?.hashValue ?? 0)
    h = h &* 31 &+ (inheritStyle ? 1 : 0)
    return h
  }

  /// Value equality with another `DTTextList`.
  public func isEqualTo(_ other: DTTextList) -> Bool {
    if other === self { return true }
    if markerFormat != other.markerFormat { return false }
    if startingItemNumber != other.startingItemNumber { return false }
    if imageName != other.imageName { return false }
    if position != other.position { return false }
    if customMarker != other.customMarker { return false }
    if inheritStyle != other.inheritStyle { return false }
    return true
  }

  // MARK: - Marker Generation

  /// True if the list produces a visible marker prefix.
  public var hasMarker: Bool {
    if let custom = customMarker {
      return custom != .none && custom != .inherit
    }
    return true
  }

  /// True for ordered (numbered) lists.
  public override var isOrdered: Bool {
    if let custom = customMarker {
      return custom == .decimalLeadingZero
    }
    return super.isOrdered
  }

  /// Returns the fully tab-wrapped prefix string for the given item number, honoring
  /// the list's marker type, custom marker override, and position. Returns `nil` if
  /// the list has no visible marker (e.g. `list-style-type: none`).
  public func formattedMarker(forItemNumber itemNumber: Int) -> String? {
    let token: String

    if let custom = customMarker {
      switch custom {
      case .none, .inherit:
        return nil
      case .image:
        token = "\u{fffc}"  // UNICODE OBJECT REPLACEMENT CHARACTER
      case .plus:
        token = "+"
      case .underscore:
        token = "_"
      case .decimalLeadingZero:
        token = String(format: "%02d.", itemNumber)
      }
    } else {
      switch markerFormat {
      case .disc:
        token = "\u{2022}"  // •
      case .circle:
        token = "\u{25e6}"  // ◦
      case .square:
        token = "\u{25aa}"  // ▪
      case .hyphen:
        token = "-"
      case .decimal:
        token = "\(itemNumber)."
      case .lowercaseAlpha, .lowercaseLatin:
        let letter = Character(UnicodeScalar(UInt8(97 + itemNumber - 1)))
        token = "\(letter)."
      case .uppercaseAlpha, .uppercaseLatin:
        let letter = Character(UnicodeScalar(UInt8(65 + itemNumber - 1)))
        token = "\(letter)."
      case .lowercaseRoman:
        token = "\(NSNumber(value: itemNumber).romanNumeral().lowercased())."
      case .uppercaseRoman:
        token = "\(NSNumber(value: itemNumber).romanNumeral())."
      default:
        return nil
      }
    }

    if position == .inside {
      #if os(iOS) || os(tvOS)
        return "\t\t\(token)"
      #else
        return "\t\(token)\t"
      #endif
    } else {
      return "\t\(token)\t"
    }
  }

  // MARK: - Style Overrides

  /// Returns a copy of the receiver with any list-style keys in the given CSS dictionary applied
  /// on top. Keys that are not present in `styles` leave the corresponding field unchanged. Because
  /// `NSTextList.markerFormat` is read-only, a change in marker type produces a fresh instance.
  public func applyingStyles(_ styles: [String: Any]) -> DTTextList {
    // shorthand — rebuild from scratch, preserving startingItemNumber
    if let shortHand = (styles["list-style"] as? String)?.lowercased() {
      if shortHand == "inherit" {
        let c = self.copy() as! DTTextList
        c.inheritStyle = true
        return c
      }
      let rebuilt = DTTextList(styles: styles)
      rebuilt.startingItemNumber = self.startingItemNumber
      // the shorthand may omit the image or position; in CSS this means "reset", matching legacy
      return rebuilt
    }

    let typePresent = (styles["list-style-type"] as? String) != nil
    let positionPresent = (styles["list-style-position"] as? String) != nil
    let imagePresent = (styles["list-style-image"] as? String) != nil

    if !typePresent && !positionPresent && !imagePresent {
      return self
    }

    let overrides = DTTextList(styles: styles)

    if typePresent {
      // marker type changed — need a new NSTextList instance
      let rebuilt = DTTextList(markerFormat: overrides.markerFormat, startingItemNumber: 1)
      rebuilt.startingItemNumber = self.startingItemNumber
      rebuilt.imageName = imagePresent ? overrides.imageName : self.imageName
      rebuilt.position = positionPresent ? overrides.position : self.position
      rebuilt.customMarker = overrides.customMarker
      rebuilt.inheritStyle = self.inheritStyle
      return rebuilt
    }

    // type unchanged — mutate a copy in place
    let c = self.copy() as! DTTextList
    if positionPresent {
      c.position = overrides.position
    }
    if imagePresent {
      c.imageName = overrides.imageName
    }
    return c
  }

  // MARK: - CSS Helpers

  /// CSS `list-style-type` string corresponding to the current marker.
  public var cssListStyleTypeString: String {
    if let custom = customMarker {
      switch custom {
      case .none: return "none"
      case .inherit: return "inherit"
      case .decimalLeadingZero: return "decimal-leading-zero"
      case .plus: return "plus"
      case .underscore: return "underscore"
      case .image: return "image"
      }
    }
    switch markerFormat {
    case .disc: return "disc"
    case .circle: return "circle"
    case .square: return "square"
    case .decimal: return "decimal"
    case .uppercaseAlpha: return "upper-alpha"
    case .uppercaseLatin: return "upper-latin"
    case .lowercaseAlpha: return "lower-alpha"
    case .lowercaseLatin: return "lower-latin"
    case .uppercaseRoman: return "upper-roman"
    case .lowercaseRoman: return "lower-roman"
    default: return "disc"
    }
  }

  // MARK: - Shorthand Token Recognition

  /// Mirrors legacy behavior: any non-nil string is considered a "recognized"
  /// list-style-type token. Used by the CSS shorthand parser to consume
  /// components for the `list-style-type` slot.
  public static func isValidListStyleTypeString(_ string: String?) -> Bool {
    return string != nil
  }

  /// Returns true if the passed string is a recognized CSS list-style-position token.
  public static func isValidListStylePositionString(_ string: String?) -> Bool {
    guard let s = string?.lowercased() else { return false }
    return s == "inherit" || s == "inside" || s == "outside"
  }

  // MARK: - CSS Parsing

  private struct ParsedStyles {
    var format: NSTextList.MarkerFormat
    var customMarker: DTTextListCustomMarker?
    var position: DTTextListPosition
    var imageName: String?
    var inheritStyle: Bool
  }

  private static func parseStyles(_ styles: [String: Any]) -> ParsedStyles {
    var result = ParsedStyles(
      format: .disc, customMarker: nil, position: .outside,
      imageName: nil, inheritStyle: false)

    // shorthand
    if let shortHand = (styles["list-style"] as? String)?.lowercased() {
      if shortHand == "inherit" {
        result.inheritStyle = true
        return result
      }

      var typeWasSet = false
      var positionWasSet = false

      for component in shortHand.components(separatedBy: .whitespaces) {
        if component.hasPrefix("url") {
          let scanner = Scanner(string: component)
          if let urlString = scanner.scanCSSURL() {
            result.imageName = urlString
            continue
          }
        }

        if !typeWasSet {
          applyTypeString(component, to: &result)
          typeWasSet = true
          continue
        }

        if !positionWasSet {
          if applyPositionString(component, to: &result) {
            positionWasSet = true
            continue
          }
        }
      }
      return result
    }

    // individual longhand properties
    if let t = styles["list-style-type"] as? String {
      applyTypeString(t, to: &result)
    }
    if let p = styles["list-style-position"] as? String {
      _ = applyPositionString(p, to: &result)
    }
    if let img = styles["list-style-image"] as? String {
      let scanner = Scanner(string: img)
      if let urlString = scanner.scanCSSURL() {
        result.imageName = urlString
      }
    }
    return result
  }

  private static func applyTypeString(_ string: String, to result: inout ParsedStyles) {
    switch string.lowercased() {
    case "inherit":
      result.customMarker = .inherit
    case "none":
      result.customMarker = DTTextListCustomMarker.none
    case "circle":
      result.format = .circle
      result.customMarker = nil
    case "square":
      result.format = .square
      result.customMarker = nil
    case "decimal":
      result.format = .decimal
      result.customMarker = nil
    case "decimal-leading-zero":
      result.format = .decimal
      result.customMarker = .decimalLeadingZero
    case "disc":
      result.format = .disc
      result.customMarker = nil
    case "upper-alpha":
      result.format = .uppercaseAlpha
      result.customMarker = nil
    case "upper-latin":
      result.format = .uppercaseLatin
      result.customMarker = nil
    case "lower-alpha":
      result.format = .lowercaseAlpha
      result.customMarker = nil
    case "lower-latin":
      result.format = .lowercaseLatin
      result.customMarker = nil
    case "lower-roman":
      result.format = .lowercaseRoman
      result.customMarker = nil
    case "upper-roman":
      result.format = .uppercaseRoman
      result.customMarker = nil
    case "plus":
      result.customMarker = .plus
    case "underscore":
      result.customMarker = .underscore
    default:
      // mirrors legacy: unknown token resolves to none
      result.customMarker = DTTextListCustomMarker.none
    }
  }

  private static func applyPositionString(_ string: String, to result: inout ParsedStyles) -> Bool {
    switch string.lowercased() {
    case "inherit":
      result.position = .inherit
      return true
    case "inside":
      result.position = .inside
      return true
    case "outside":
      result.position = .outside
      return true
    default:
      return false
    }
  }
}
