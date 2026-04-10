import Foundation

#if canImport(UIKit)
  import UIKit
  public typealias DTEdgeInsets = UIEdgeInsets
#elseif canImport(AppKit)
  import AppKit
  public typealias DTEdgeInsets = NSEdgeInsets
  public typealias UIEdgeInsets = NSEdgeInsets
#endif

extension NSCoder {

  #if canImport(AppKit) && !canImport(UIKit)
    /// Encodes a CGSize for the given key (macOS only; iOS has this built in).
    @objc public func encodeCGSize(_ size: CGSize, forKey key: String) {
      encode(NSStringFromSize(NSSizeFromCGSize(size)), forKey: key)
    }

    /// Decodes a CGSize for the given key (macOS only; iOS has this built in).
    @objc public func decodeCGSize(forKey key: String) -> CGSize {
      let string = decodeObject(forKey: key) as? String ?? ""
      return NSSizeToCGSize(NSSizeFromString(string))
    }
  #endif

  /// Encodes DTEdgeInsets for the given key.
  @objc public func encodeDTEdgeInsets(_ insets: DTEdgeInsets, forKey key: String) {
    #if canImport(UIKit)
      encode(insets, forKey: key)
    #else
      let string = String(
        format: "{%f,%f,%f,%f}", insets.top, insets.left, insets.bottom, insets.right)
      encode(string, forKey: key)
    #endif
  }

  /// Decodes DTEdgeInsets for the given key.
  @objc public func decodeDTEdgeInsets(forKey key: String) -> DTEdgeInsets {
    #if canImport(UIKit)
      return decodeUIEdgeInsets(forKey: key)
    #else
      guard let string = decodeObject(forKey: key) as? String else {
        return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
      }
      return nsEdgeInsetsFromString(string)
    #endif
  }
}

#if canImport(AppKit) && !canImport(UIKit)
  extension NSEdgeInsets {
    public static var zero: NSEdgeInsets {
      return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
  }

  private func nsEdgeInsetsFromString(_ string: String) -> NSEdgeInsets {
    // Cut off curly brackets
    guard string.count > 2 else {
      return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    let trimmed = String(string.dropFirst().dropLast())
    let floatStrings = trimmed.components(separatedBy: ",")

    guard floatStrings.count == 4 else {
      return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    let top = CGFloat((floatStrings[0] as NSString).floatValue)
    let left = CGFloat((floatStrings[1] as NSString).floatValue)
    let bottom = CGFloat((floatStrings[2] as NSString).floatValue)
    let right = CGFloat((floatStrings[3] as NSString).floatValue)

    return NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)
  }
#endif
