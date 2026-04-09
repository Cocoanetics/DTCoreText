import Foundation

#if canImport(UIKit)
import UIKit

/// Platform-independent image type alias.
public typealias DTImage = UIImage

/// Category used to have the same method available for unit testing on Mac on iOS.
public extension UIImage {

    /// Retrieve the NSData representation of a UIImage.
    /// Used to encode UIImages in DTTextAttachments.
    /// - Returns: The PNG data representation of this image.
    @objc func dataForPNGRepresentation() -> Data? {
        return self.pngData()
    }
}

#elseif canImport(AppKit)
import AppKit

/// Platform-independent image type alias.
public typealias DTImage = NSImage

/// Category used to have the same method available for unit testing on Mac on iOS.
public extension NSImage {

    /// Retrieve the NSData representation of a NSImage.
    /// - Returns: The PNG data representation of this image.
    @objc func dataForPNGRepresentation() -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapRep.representation(using: .png, properties: [:])
    }
}

#endif
