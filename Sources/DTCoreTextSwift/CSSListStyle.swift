//
//  CSSListStyle.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 8/11/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

import Foundation

/// This class is the equivalent of `NSTextList` on Mac with the added handling of the marker position.
@objc(DTCSSListStyle)
public class CSSListStyle: NSObject, NSCoding, NSCopying {

    /// If the list style is inherited.
    @objc public var inherit: Bool = false

    /// The type of the text list.
    @objc public var type: DTCSSListStyleType = .inherit

    /// The position of the marker in the prefix.
    @objc public var position: DTCSSListStylePosition = .inherit

    /// The image name to use for the marker.
    @objc public var imageName: String?

    /// The starting item number for the text list.
    @objc public var startingItemNumber: Int = 1

    // MARK: - Initialization

    @objc public override init() {
        super.init()
    }

    /// Creates a list style from the passed CSS style dictionary.
    @objc public init(styles: [String: Any]) {
        super.init()

        // defaults
        position = .outside
        startingItemNumber = 1

        updateFromStyleDictionary(styles)
    }

    // MARK: - NSCoding

    @objc public required init?(coder aDecoder: NSCoder) {
        super.init()
        inherit = aDecoder.decodeBool(forKey: "inherit")
        type = DTCSSListStyleType(rawValue: UInt(aDecoder.decodeInteger(forKey: "type"))) ?? .inherit
        position = DTCSSListStylePosition(rawValue: UInt(aDecoder.decodeInteger(forKey: "position"))) ?? .inherit
        imageName = aDecoder.decodeObject(forKey: "imageName") as? String
        startingItemNumber = aDecoder.decodeInteger(forKey: "startingItemNumber")
    }

    @objc public func encode(with aCoder: NSCoder) {
        aCoder.encode(inherit, forKey: "inherit")
        aCoder.encode(Int(type.rawValue), forKey: "type")
        aCoder.encode(Int(position.rawValue), forKey: "position")
        aCoder.encode(imageName, forKey: "imageName")
        aCoder.encode(startingItemNumber, forKey: "startingItemNumber")
    }

    // MARK: - Type/Position from String

    /// Convert a string into a list style type.
    @objc public class func listStyleType(from string: String?) -> DTCSSListStyleType {
        guard let string = string?.lowercased() else {
            return .invalid
        }

        switch string {
        case "inherit": return .inherit
        case "none": return .none
        case "circle": return .circle
        case "square": return .square
        case "decimal": return .decimal
        case "decimal-leading-zero": return .decimalLeadingZero
        case "disc": return .disc
        case "upper-alpha", "upper-latin": return .upperAlpha
        case "lower-alpha", "lower-latin": return .lowerAlpha
        case "lower-roman": return .lowerRoman
        case "upper-roman": return .upperRoman
        case "plus": return .plus
        case "underscore": return .underscore
        default: return .none
        }
    }

    /// Convert a string into a marker position.
    @objc public class func listStylePosition(from string: String?) -> DTCSSListStylePosition {
        guard let string = string?.lowercased() else {
            return .invalid
        }

        switch string {
        case "inherit": return .inherit
        case "inside": return .inside
        case "outside": return .outside
        default: return .inherit
        }
    }

    // MARK: - Private Helpers

    private func setType(with string: String?) -> Bool {
        let type = CSSListStyle.listStyleType(from: string)
        if type == .invalid {
            return false
        }
        self.type = type
        return true
    }

    private func setPosition(with string: String?) -> Bool {
        let position = CSSListStyle.listStylePosition(from: string)
        if position == .invalid {
            return false
        }
        self.position = position
        return true
    }

    // MARK: - Update from Style Dictionary

    /// Update the receiver from the CSS styles dictionary passed.
    @objc public func updateFromStyleDictionary(_ styles: [String: Any]) {
        if let shortHand = (styles["list-style"] as? String)?.lowercased() {
            if shortHand == "inherit" {
                inherit = true
                return
            }

            let components = shortHand.components(separatedBy: .whitespaces)

            var typeWasSet = false
            var positionWasSet = false

            for oneComponent in components {
                if oneComponent.hasPrefix("url") {
                    let scanner = Scanner(string: oneComponent)
                    var urlString: NSString?
                    if scanner.scanCSSURL(&urlString) {
                        imageName = urlString as String?
                        continue
                    }
                }

                if !typeWasSet && setType(with: oneComponent) {
                    typeWasSet = true
                    continue
                }

                if !positionWasSet && setPosition(with: oneComponent) {
                    positionWasSet = true
                    continue
                }
            }

            return
        }

        // not a short hand, set from individual types
        _ = setType(with: styles["list-style-type"] as? String)
        _ = setPosition(with: styles["list-style-position"] as? String)

        if let tmpValue = styles["list-style-image"] as? String {
            let scanner = Scanner(string: tmpValue)
            var urlString: NSString?
            if scanner.scanCSSURL(&urlString) {
                imageName = urlString as String?
            }
        }
    }

    // MARK: - Description

    public override var description: String {
        return "<\(Swift.type(of: self)) \(Unmanaged.passUnretained(self).toOpaque()) type=\(type.rawValue) position=\(position.rawValue)>"
    }

    // MARK: - Hashing

    public override var hash: Int {
        var calcHash = 7
        calcHash = calcHash &* 31 &+ (imageName?.hash ?? 0)
        calcHash = calcHash &* 31 &+ Int(type.rawValue)
        calcHash = calcHash &* 31 &+ Int(position.rawValue)
        calcHash = calcHash &* 31 &+ startingItemNumber
        calcHash = calcHash &* 31 &+ (inherit ? 1 : 0)
        return calcHash
    }

    // MARK: - Comparing

    /// Determine if another list style has equivalent settings.
    @objc(isEqualToListStyle:)
    public func isEqualToListStyle(_ otherListStyle: CSSListStyle?) -> Bool {
        guard let otherListStyle = otherListStyle else {
            return false
        }

        if otherListStyle === self {
            return true
        }

        if inherit != otherListStyle.inherit { return false }
        if type != otherListStyle.type { return false }
        if position != otherListStyle.position { return false }
        if startingItemNumber != otherListStyle.startingItemNumber { return false }

        if imageName == otherListStyle.imageName { return true }
        return imageName == otherListStyle.imageName
    }

    // MARK: - NSCopying

    @objc public func copy(with zone: NSZone? = nil) -> Any {
        let newStyle = CSSListStyle()
        newStyle.type = type
        newStyle.position = position
        newStyle.imageName = imageName
        newStyle.startingItemNumber = startingItemNumber
        return newStyle
    }

    // MARK: - Prefix

    /// Returns the prefix for lists of the receiver's settings.
    @objc public func prefix(withCounter counter: Int) -> String? {
        var token: String?

        var listStyleType = type

        if imageName != nil {
            listStyleType = .image
        }

        switch listStyleType {
        case .none, .inherit, .invalid:
            return nil

        case .image:
            token = "\u{fffc}" // UNICODE_OBJECT_PLACEHOLDER

        case .circle:
            token = "\u{25e6}"

        case .square:
            token = "\u{25aa}"

        case .decimal:
            token = "\(counter)."

        case .decimalLeadingZero:
            token = String(format: "%02d.", counter)

        case .disc:
            token = "\u{2022}"

        case .upperAlpha, .upperLatin:
            let letter = Character(UnicodeScalar(UInt8(65 + counter - 1)))  // 'A' + counter - 1
            token = "\(letter)."

        case .lowerAlpha, .lowerLatin:
            let letter = Character(UnicodeScalar(UInt8(97 + counter - 1)))  // 'a' + counter - 1
            token = "\(letter)."

        case .plus:
            token = "+"

        case .underscore:
            token = "_"

        case .upperRoman:
            token = "\(NSNumber(value: counter).romanNumeral())."

        case .lowerRoman:
            token = "\(NSNumber(value: counter).romanNumeral().lowercased())."

        @unknown default:
            return nil
        }

        guard let token = token else { return nil }

        if position == .inside {
            #if os(iOS)
            return "\t\t\(token)"
            #else
            return "\t\(token)\t"
            #endif
        } else {
            return "\t\(token)\t"
        }
    }

    /// Returns if the receiver is an ordered or unordered list.
    @objc public func isOrdered() -> Bool {
        switch type {
        case .decimal, .decimalLeadingZero, .upperAlpha, .upperLatin, .lowerAlpha, .lowerLatin:
            return true
        default:
            return false
        }
    }
}
