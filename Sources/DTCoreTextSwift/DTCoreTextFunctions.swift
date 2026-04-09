import Foundation
import CoreText

#if canImport(UIKit)
import UIKit

/// Creates a CTFont from a UIFont
/// - Parameter font: The UIFont
/// - Returns: The matching CTFont
public func DTCTFontCreateWithUIFont(_ font: UIFont) -> CTFont {
    return CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
}
#endif

/// Converts an NSLineBreakMode into CoreText line truncation type
public func DTCTLineTruncationTypeFromNSLineBreakMode(_ lineBreakMode: NSLineBreakMode) -> CTLineTruncationType {
    switch lineBreakMode {
    case .byTruncatingHead:
        return .start
    case .byTruncatingMiddle:
        return .middle
    default:
        return .end
    }
}

/// Rounds the passed value according to the specified content scale.
///
/// With contentScale 1 the results are identical to roundf, with Retina content scale 2 the results are multiples of 0.5.
public func DTRoundWithContentScale(_ value: CGFloat, _ contentScale: CGFloat) -> CGFloat {
    return (value * contentScale).rounded() / contentScale
}

/// Rounds up the passed value according to the specified content scale.
///
/// With contentScale 1 the results are identical to ceilf, with Retina content scale 2 the results are multiples of 0.5.
public func DTCeilWithContentScale(_ value: CGFloat, _ contentScale: CGFloat) -> CGFloat {
    return ceil(value * contentScale) / contentScale
}

/// Rounds down the passed value according to the specified content scale.
///
/// With contentScale 1 the results are identical to floorf, with Retina content scale 2 the results are multiples of 0.5.
public func DTFloorWithContentScale(_ value: CGFloat, _ contentScale: CGFloat) -> CGFloat {
    return floor(value * contentScale) / contentScale
}

// MARK: - Alignment Conversion

/// Converts from NSTextAlignment to CTTextAlignment
public func DTNSTextAlignmentToCTTextAlignment(_ nsTextAlignment: NSTextAlignment) -> CTTextAlignment {
    switch nsTextAlignment {
    case .left:
        return .left
    case .right:
        return .right
    case .center:
        return .center
    case .justified:
        return .justified
    case .natural:
        return .natural
    @unknown default:
        return .left
    }
}

/// Converts from CTTextAlignment to NSTextAlignment
public func DTNSTextAlignmentFromCTTextAlignment(_ ctTextAlignment: CTTextAlignment) -> NSTextAlignment {
    switch ctTextAlignment {
    case .left:
        return .left
    case .right:
        return .right
    case .center:
        return .center
    case .justified:
        return .justified
    case .natural:
        return .natural
    @unknown default:
        return .left
    }
}
