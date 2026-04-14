import CoreText
import Foundation

/// Methods simplifying dealing with text that is in paragraphs.
///
/// The character used to separate paragraphs from each other is '\n'.
extension NSString {

  /// Extends the given range such that it contains only full paragraphs.
  /// - Parameters:
  ///   - range: The string range
  ///   - parBegIndex: An optional output parameter that is filled with the beginning index of the extended range
  ///   - parEndIndex: An optional output parameter that is filled with the ending index of the extended range
  /// - Returns: The extended string range
  @objc public func rangeOfParagraphsContaining(
    _ range: NSRange, parBegIndex: UnsafeMutablePointer<UInt>?,
    parEndIndex: UnsafeMutablePointer<UInt>?
  ) -> NSRange {
    var beginIndex: CFIndex = 0
    var endIndex: CFIndex = 0

    CFStringGetParagraphBounds(
      self as CFString, CFRangeMake(range.location, range.length), &beginIndex, &endIndex, nil)

    parBegIndex?.pointee = UInt(beginIndex)
    parEndIndex?.pointee = UInt(endIndex)

    return NSRange(location: beginIndex, length: endIndex - beginIndex)
  }

  /// Determines if the given index is the first character of a new paragraph.
  ///
  /// This is done by examining the string; index 0 or characters following a newline are considered
  /// to be a first character of a new paragraph.
  /// - Parameter index: The index to examine
  /// - Returns: true if the given index is the first character of a new paragraph
  @objc public func indexIsAtBeginningOfParagraph(_ index: UInt) -> Bool {
    // index zero is beginning of first paragraph
    if index == 0 {
      return true
    }

    // beginning of any other paragraph is after NL
    if character(at: Int(index) - 1) == UInt16(0x0A) /* '\n' */ {
      return true
    }

    return false
  }

  /// Returns the string range of the paragraph at the given index.
  /// - Parameter index: The index to inspect
  /// - Returns: The string range of the paragraph
  @objc public func rangeOfParagraph(at index: UInt) -> NSRange {
    return rangeOfParagraphsContaining(
      NSRange(location: Int(index), length: 1), parBegIndex: nil, parEndIndex: nil)
  }

  /// Counts the number of paragraphs in the receiver.
  /// - Returns: The number of newline characters in the receiver
  @objc public func numberOfParagraphs() -> UInt {
    var count: UInt = 0

    for i in 0..<length {
      if character(at: i) == UInt16(0x0A) /* '\n' */ {
        count += 1
      }
    }

    return count
  }
}
