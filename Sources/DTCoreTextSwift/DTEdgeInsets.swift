import Foundation

#if canImport(UIKit)
  import UIKit
  public typealias DTEdgeInsets = UIEdgeInsets
#elseif canImport(AppKit)
  import AppKit
  public typealias DTEdgeInsets = NSEdgeInsets
  public typealias UIEdgeInsets = NSEdgeInsets
#endif

#if canImport(AppKit) && !canImport(UIKit)
  extension NSEdgeInsets {
    public static var zero: NSEdgeInsets {
      return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
  }

  internal func nsEdgeInsetsFromString(_ string: String) -> NSEdgeInsets {
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
