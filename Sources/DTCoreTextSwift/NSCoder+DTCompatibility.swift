import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
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
