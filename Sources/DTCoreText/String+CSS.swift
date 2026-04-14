import Foundation

/// Methods to make dealing with CSS strings easier (pure Swift surface).
extension String {

  /// Examine a string for all CSS styles that are applied to it and return a dictionary
  /// of those styles.
  ///
  /// Pure Swift — no `@objc`, so Swift callers get a native-variant `Dictionary<String, Any>`
  /// back with no lazy `_SwiftDeferredNSDictionary` bridging wrapper around it. Storing
  /// the result in another Swift dictionary is safe for concurrent reads from multiple
  /// threads. See the history of `CSSStylesheet.mergeStylesheet` for why this matters.
  public func dictionaryOfCSSStyles() -> [String: Any] {
    let scanner = Scanner(string: self)

    var tmpDict = [String: Any]()

    autoreleasepool {
      while let attr = scanner.scanCSSAttribute() {
        tmpDict[attr.name] = attr.value
      }
    }

    return tmpDict
  }
}
