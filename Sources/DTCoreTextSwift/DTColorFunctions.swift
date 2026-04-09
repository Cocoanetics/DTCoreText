import Foundation

#if canImport(UIKit)
import UIKit
public typealias DTColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias DTColor = NSColor
#endif

// MARK: - Private Helpers

private func _integerValueFromHexString(_ hexString: String) -> UInt {
    var result: UInt32 = 0
    Scanner(string: hexString).scanHexInt32(&result)
    return UInt(result)
}

// MARK: - Public Functions

/// Creates a color from a CSS hex string (3 or 6 characters, without '#').
/// - Parameter hexString: A CSS hexadecimal color string of length 6 or 3.
/// - Returns: A color generated from the hexadecimal string with alpha 1.0, or nil if invalid.
public func DTColorCreateWithHexString(_ hexString: String) -> DTColor? {
    guard hexString.count == 6 || hexString.count == 3 else {
        return nil
    }

    let digits = hexString.count / 3
    let maxValue: CGFloat = (digits == 1) ? 15.0 : 255.0

    let nsHex = hexString as NSString
    let redValue = _integerValueFromHexString(nsHex.substring(with: NSRange(location: 0, length: digits)))
    let greenValue = _integerValueFromHexString(nsHex.substring(with: NSRange(location: digits, length: digits)))
    let blueValue = _integerValueFromHexString(nsHex.substring(with: NSRange(location: 2 * digits, length: digits)))

    let red = CGFloat(redValue) / maxValue
    let green = CGFloat(greenValue) / maxValue
    let blue = CGFloat(blueValue) / maxValue

    #if canImport(UIKit)
    return DTColor(red: red, green: green, blue: blue, alpha: 1.0)
    #else
    return NSColor(deviceRed: red, green: green, blue: blue, alpha: 1.0)
    #endif
}

/// Takes an English string representing a color and maps it to a numeric RGB value as declared by the HTML and CSS specifications.
/// Also accepts CSS '#' hexadecimal colors, 'rgba()', and 'rgb()'.
/// - Parameter name: The CSS color string.
/// - Returns: A color representing the name, or nil if unrecognized.
public func DTColorCreateWithHTMLName(_ name: String) -> DTColor? {
    if name.hasPrefix("#") {
        return DTColorCreateWithHexString(String(name.dropFirst()))
    }

    if name.hasPrefix("rgba") {
        let trimmed = name.trimmingCharacters(in: CharacterSet(charactersIn: "rgba() "))
        let components = trimmed.components(separatedBy: ",")
        guard components.count == 4 else { return nil }

        let red = CGFloat((components[0].trimmingCharacters(in: .whitespaces) as NSString).floatValue) / 255.0
        let green = CGFloat((components[1].trimmingCharacters(in: .whitespaces) as NSString).floatValue) / 255.0
        let blue = CGFloat((components[2].trimmingCharacters(in: .whitespaces) as NSString).floatValue) / 255.0
        let alpha = CGFloat((components[3].trimmingCharacters(in: .whitespaces) as NSString).floatValue)

        #if canImport(UIKit)
        return DTColor(red: red, green: green, blue: blue, alpha: alpha)
        #else
        return NSColor(deviceRed: red, green: green, blue: blue, alpha: alpha)
        #endif
    }

    if name.hasPrefix("rgb") {
        let trimmed = name.trimmingCharacters(in: CharacterSet(charactersIn: "rgb() "))
        let components = trimmed.components(separatedBy: CharacterSet(charactersIn: ","))
        guard components.count == 3 else { return nil }

        let red = CGFloat((components[0].trimmingCharacters(in: .whitespaces) as NSString).floatValue) / 255.0
        let green = CGFloat((components[1].trimmingCharacters(in: .whitespaces) as NSString).floatValue) / 255.0
        let blue = CGFloat((components[2].trimmingCharacters(in: .whitespaces) as NSString).floatValue) / 255.0

        #if canImport(UIKit)
        return DTColor(red: red, green: green, blue: blue, alpha: 1.0)
        #else
        return NSColor(deviceRed: red, green: green, blue: blue, alpha: 1.0)
        #endif
    }

    guard let hexString = colorLookup[name.lowercased()] else {
        return nil
    }

    return DTColorCreateWithHexString(hexString)
}

/// Returns a hexadecimal string representation of a color.
/// - Parameter color: The color to convert.
/// - Returns: A CSS hexadecimal string (e.g. "ff0000"), or nil for unsupported color spaces.
public func DTHexStringFromDTColor(_ color: DTColor) -> String? {
    guard let cgColor = color.cgColor else { return nil }

    let count = cgColor.numberOfComponents
    guard let components = cgColor.components else { return nil }

    // Grayscale
    if count == 2 {
        let white = UInt(components[0] * 255.0)
        return String(format: "%02x%02x%02x", white, white, white)
    }

    // RGB
    if count == 4 {
        return String(format: "%02x%02x%02x",
                      UInt(components[0] * 255.0),
                      UInt(components[1] * 255.0),
                      UInt(components[2] * 255.0))
    }

    // Unsupported color space
    return nil
}

// MARK: - Color Lookup Table

private let colorLookup: [String: String] = [
    "aliceblue": "F0F8FF",
    "antiquewhite": "FAEBD7",
    "aqua": "00FFFF",
    "aquamarine": "7FFFD4",
    "azure": "F0FFFF",
    "beige": "F5F5DC",
    "bisque": "FFE4C4",
    "black": "000000",
    "blanchedalmond": "FFEBCD",
    "blue": "0000FF",
    "blueviolet": "8A2BE2",
    "brown": "A52A2A",
    "burlywood": "DEB887",
    "cadetblue": "5F9EA0",
    "chartreuse": "7FFF00",
    "chocolate": "D2691E",
    "coral": "FF7F50",
    "cornflowerblue": "6495ED",
    "cornsilk": "FFF8DC",
    "crimson": "DC143C",
    "cyan": "00FFFF",
    "darkblue": "00008B",
    "darkcyan": "008B8B",
    "darkgoldenrod": "B8860B",
    "darkgray": "A9A9A9",
    "darkgrey": "A9A9A9",
    "darkgreen": "006400",
    "darkkhaki": "BDB76B",
    "darkmagenta": "8B008B",
    "darkolivegreen": "556B2F",
    "darkorange": "FF8C00",
    "darkorchid": "9932CC",
    "darkred": "8B0000",
    "darksalmon": "E9967A",
    "darkseagreen": "8FBC8F",
    "darkslateblue": "483D8B",
    "darkslategray": "2F4F4F",
    "darkslategrey": "2F4F4F",
    "darkturquoise": "00CED1",
    "darkviolet": "9400D3",
    "deeppink": "FF1493",
    "deepskyblue": "00BFFF",
    "dimgray": "696969",
    "dimgrey": "696969",
    "dodgerblue": "1E90FF",
    "firebrick": "B22222",
    "floralwhite": "FFFAF0",
    "forestgreen": "228B22",
    "fuchsia": "FF00FF",
    "gainsboro": "DCDCDC",
    "ghostwhite": "F8F8FF",
    "gold": "FFD700",
    "goldenrod": "DAA520",
    "gray": "808080",
    "grey": "808080",
    "green": "008000",
    "greenyellow": "ADFF2F",
    "honeydew": "F0FFF0",
    "hotpink": "FF69B4",
    "indianred": "CD5C5C",
    "indigo": "4B0082",
    "ivory": "FFFFF0",
    "khaki": "F0E68C",
    "lavender": "E6E6FA",
    "lavenderblush": "FFF0F5",
    "lawngreen": "7CFC00",
    "lemonchiffon": "FFFACD",
    "lightblue": "ADD8E6",
    "lightcoral": "F08080",
    "lightcyan": "E0FFFF",
    "lightgoldenrodyellow": "FAFAD2",
    "lightgray": "D3D3D3",
    "lightgrey": "D3D3D3",
    "lightgreen": "90EE90",
    "lightpink": "FFB6C1",
    "lightsalmon": "FFA07A",
    "lightseagreen": "20B2AA",
    "lightskyblue": "87CEFA",
    "lightslategray": "778899",
    "lightslategrey": "778899",
    "lightsteelblue": "B0C4DE",
    "lightyellow": "FFFFE0",
    "lime": "00FF00",
    "limegreen": "32CD32",
    "linen": "FAF0E6",
    "magenta": "FF00FF",
    "maroon": "800000",
    "mediumaquamarine": "66CDAA",
    "mediumblue": "0000CD",
    "mediumorchid": "BA55D3",
    "mediumpurple": "9370D8",
    "mediumseagreen": "3CB371",
    "mediumslateblue": "7B68EE",
    "mediumspringgreen": "00FA9A",
    "mediumturquoise": "48D1CC",
    "mediumvioletred": "C71585",
    "midnightblue": "191970",
    "mintcream": "F5FFFA",
    "mistyrose": "FFE4E1",
    "moccasin": "FFE4B5",
    "navajowhite": "FFDEAD",
    "navy": "000080",
    "oldlace": "FDF5E6",
    "olive": "808000",
    "olivedrab": "6B8E23",
    "orange": "FFA500",
    "orangered": "FF4500",
    "orchid": "DA70D6",
    "palegoldenrod": "EEE8AA",
    "palegreen": "98FB98",
    "paleturquoise": "AFEEEE",
    "palevioletred": "D87093",
    "papayawhip": "FFEFD5",
    "peachpuff": "FFDAB9",
    "peru": "CD853F",
    "pink": "FFC0CB",
    "plum": "DDA0DD",
    "powderblue": "B0E0E6",
    "purple": "800080",
    "red": "FF0000",
    "rosybrown": "BC8F8F",
    "royalblue": "4169E1",
    "saddlebrown": "8B4513",
    "salmon": "FA8072",
    "sandybrown": "F4A460",
    "seagreen": "2E8B57",
    "seashell": "FFF5EE",
    "sienna": "A0522D",
    "silver": "C0C0C0",
    "skyblue": "87CEEB",
    "slateblue": "6A5ACD",
    "slategray": "708090",
    "slategrey": "708090",
    "snow": "FFFAFA",
    "springgreen": "00FF7F",
    "steelblue": "4682B4",
    "tan": "D2B48C",
    "teal": "008080",
    "thistle": "D8BFD8",
    "tomato": "FF6347",
    "turquoise": "40E0D0",
    "violet": "EE82EE",
    "wheat": "F5DEB3",
    "white": "FFFFFF",
    "whitesmoke": "F5F5F5",
    "yellow": "FFFF00",
    "yellowgreen": "9ACD32",
]
