import Foundation

private let romanNumerals = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
private let romanValues: [Int] = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]

public extension NSNumber {

    /// Returns the Roman numeral representation of the receiver's integer value.
    @objc func romanNumeral() -> String {
        var n = self.intValue
        var result = ""

        for i in 0..<romanValues.count {
            while n >= romanValues[i] {
                n -= romanValues[i]
                result += romanNumerals[i]
            }
        }

        return result
    }
}
