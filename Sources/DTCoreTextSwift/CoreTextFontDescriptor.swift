import CoreText
import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

import os

/// Thread-safe registry for font overrides, fallback family, and matched-font cache.
struct FontRegistry: Sendable {
  static let shared = FontRegistry()

  /// NSCache is thread-safe; marked nonisolated(unsafe) only because it lacks Sendable conformance.
  nonisolated(unsafe) private let fontCache = NSCache<NSNumber, AnyObject>()

  private struct State: Sendable {
    var overrides = [String: String]()
    var fallbackFontFamily = "Times New Roman"
    var needsChineseFontCascadeFix = false
    var initialized = false
  }

  private let state = OSAllocatedUnfairLock(initialState: State())

  private init() {}

  // MARK: - Initialization

  func ensureInitialized() {
    let needsInit = state.withLock { s -> Bool in
      guard !s.initialized else { return false }
      s.initialized = true
      return true
    }
    guard needsInit else { return }

    let path =
      Bundle(for: CoreTextFontDescriptor.self).path(
        forResource: "DTCoreTextFontOverrides", ofType: "plist")
      ?? Bundle.main.path(forResource: "DTCoreTextFontOverrides", ofType: "plist")

    if let path = path, let fileArray = NSArray(contentsOfFile: path) as? [[String: Any]] {
      for oneOverride in fileArray {
        guard let fontFamily = oneOverride["FontFamily"] as? String,
          let overrideFontName = oneOverride["OverrideFontName"] as? String
        else { continue }

        let bold = (oneOverride["Bold"] as? NSNumber)?.boolValue ?? false
        let italic = (oneOverride["Italic"] as? NSNumber)?.boolValue ?? false
        let smallcaps = (oneOverride["SmallCaps"] as? NSNumber)?.boolValue ?? false

        if smallcaps {
          setSmallCapsFontName(overrideFontName, forFontFamily: fontFamily, bold: bold, italic: italic)
        } else {
          setOverrideFontName(overrideFontName, forFontFamily: fontFamily, bold: bold, italic: italic)
        }
      }
    }
  }

  // MARK: - Font Cache

  func cachedFont(forKey key: NSNumber) -> CTFont? {
    fontCache.object(forKey: key) as! CTFont?
  }

  func cacheFont(_ font: CTFont, forKey key: NSNumber) {
    fontCache.setObject(font, forKey: key)
  }

  // MARK: - Overrides

  func setOverrideFontName(_ fontName: String, forFontFamily family: String, bold: Bool, italic: Bool) {
    let key = "\(family)-\(bold ? 1 : 0)-\(italic ? 1 : 0)-override"
    state.withLock { $0.overrides[key] = fontName }
  }

  func overrideFontName(forFontFamily family: String, bold: Bool, italic: Bool) -> String? {
    let key = "\(family)-\(bold ? 1 : 0)-\(italic ? 1 : 0)-override"
    return state.withLock { $0.overrides[key] }
  }

  func setSmallCapsFontName(_ fontName: String, forFontFamily family: String, bold: Bool, italic: Bool) {
    let key = "\(family)-\(bold ? 1 : 0)-\(italic ? 1 : 0)-smallcaps"
    state.withLock { $0.overrides[key] = fontName }
  }

  func smallCapsFontName(forFontFamily family: String, bold: Bool, italic: Bool) -> String? {
    let key = "\(family)-\(bold ? 1 : 0)-\(italic ? 1 : 0)-smallcaps"
    return state.withLock { $0.overrides[key] }
  }

  func mergeOverrides(_ dictionary: [String: String]) {
    state.withLock { s in
      for (key, value) in dictionary where s.overrides[key] == nil {
        s.overrides[key] = value
      }
    }
  }

  // MARK: - Fallback Font Family

  var fallbackFontFamily: String {
    state.withLock { $0.fallbackFontFamily }
  }

  func setFallbackFontFamily(_ family: String) {
    state.withLock { $0.fallbackFontFamily = family }
  }

  // MARK: - Chinese Font Cascade Fix

  var needsChineseFontCascadeFix: Bool {
    state.withLock { $0.needsChineseFontCascadeFix }
  }

  func setNeedsChineseFontCascadeFix(_ value: Bool) {
    state.withLock { $0.needsChineseFontCascadeFix = value }
  }
}

/// Describes the attributes of a font. Used to represent fonts throughout parsing
/// and when needed generates matching CTFont instances.
@objc(DTCoreTextFontDescriptor)
open class CoreTextFontDescriptor: NSObject, NSCopying, NSCoding {

  @objc public var fontFamily: String?
  @objc public var fontName: String?

  @objc public var pointSize: CGFloat {
    get { return _pointSize }
    set { _pointSize = round(newValue) }
  }
  private var _pointSize: CGFloat = 0

  private var _stylisticTraits: CTFontSymbolicTraits = []
  @objc public var stylisticClass: CTFontStylisticClass = []

  @objc public var smallCapsFeature: Bool = false

  // internal values for size class and usage category
  private var _sizeCategory: Int = 0
  private var _usageAttribute: String?

  // MARK: - Initialization

  public override init() {
    super.init()
    FontRegistry.shared.ensureInitialized()
  }

  // MARK: - Creating Font Descriptors

  /// Convenience method to create a font descriptor from a font attributes dictionary
  @objc public class func fontDescriptor(withFontAttributes attributes: NSDictionary)
    -> CoreTextFontDescriptor
  {
    return CoreTextFontDescriptor(fontAttributes: attributes)
  }

  /// Convenience method for creating a font descriptor from a Core Text font
  @objc public class func fontDescriptor(for ctFont: CTFont) -> CoreTextFontDescriptor {
    return CoreTextFontDescriptor(ctFont: ctFont)
  }

  /// Creates a font descriptor from a font attributes dictionary
  @objc public init(fontAttributes attributes: NSDictionary) {
    super.init()
    FontRegistry.shared.ensureInitialized()
    setFontAttributes(attributes)
  }

  /// Creates a font descriptor from a Core Text font descriptor
  @objc public init(ctFontDescriptor: CTFontDescriptor) {
    super.init()
    FontRegistry.shared.ensureInitialized()

    let dict = CTFontDescriptorCopyAttributes(ctFontDescriptor) as NSDictionary
    _sizeCategory = (dict["NSCTFontSizeCategoryAttribute"] as? NSNumber)?.intValue ?? 0
    _usageAttribute = dict["NSCTFontUIUsageAttribute"] as? String

    let traitsDict =
      CTFontDescriptorCopyAttribute(ctFontDescriptor, kCTFontTraitsAttribute) as? NSDictionary
    let traitsValue = (traitsDict?[kCTFontSymbolicTrait as String] as? NSNumber)?.uint32Value ?? 0
    self.symbolicTraits = CTFontSymbolicTraits(rawValue: traitsValue)

    setFontAttributes(dict)

    // also get family name
    if let familyName = CTFontDescriptorCopyAttribute(ctFontDescriptor, kCTFontFamilyNameAttribute)
      as? String
    {
      self.fontFamily = familyName
    }
  }

  /// Creates a font descriptor from a Core Text font
  @objc public init(ctFont: CTFont) {
    super.init()
    FontRegistry.shared.ensureInitialized()

    let fd = CTFontCopyFontDescriptor(ctFont)
    let dict = CTFontDescriptorCopyAttributes(fd) as NSDictionary

    let traitsDict = CTFontDescriptorCopyAttribute(fd, kCTFontTraitsAttribute) as? NSDictionary
    let traitsValue = (traitsDict?[kCTFontSymbolicTrait as String] as? NSNumber)?.uint32Value ?? 0
    self.symbolicTraits = CTFontSymbolicTraits(rawValue: traitsValue)

    setFontAttributes(dict)

    // also get the family while we're at it
    if let cfStr = CTFontCopyFamilyName(ctFont) as String? {
      self.fontFamily = cfStr
    }

    // look if this has synthetic italics
    let transform = CTFontGetMatrix(ctFont)
    if !transform.isIdentity {
      self.italicTrait = true
    }
  }

  // MARK: - Creating Fonts from Font Descriptors

  /// Creates a CTFont matching the receiver's attributes
  /// - Returns: A Core Text font (caller owns the reference)
  @objc public func newMatchingFont() -> CTFont? {
    return _findOrMakeMatchingFont()
  }

  // MARK: - Font Attributes

  /// Sets the font attributes from a dictionary
  @objc public func setFontAttributes(_ newAttributes: NSDictionary?) {
    guard let attributes = newAttributes as? [String: Any] else {
      self.fontFamily = nil
      self.fontName = nil
      self.pointSize = 12
      _stylisticTraits = []
      stylisticClass = []
      return
    }

    if let traitsDict = attributes[kCTFontTraitsAttribute as String] as? [String: Any] {
      let traitsValue = (traitsDict[kCTFontSymbolicTrait as String] as? NSNumber)?.uint32Value ?? 0
      self.symbolicTraits = CTFontSymbolicTraits(rawValue: traitsValue)
    }

    if let pointNum = attributes[kCTFontSizeAttribute as String] as? NSNumber {
      _pointSize = CGFloat(pointNum.floatValue)
    }

    if let family = attributes[kCTFontFamilyNameAttribute as String] as? String {
      self.fontFamily = family
    }

    if let name = attributes[kCTFontNameAttribute as String] as? String {
      self.fontName = name
    }
  }

  /// Retrieves a dictionary of font attributes
  @objc public func fontAttributes() -> NSDictionary {
    let tmpDict = NSMutableDictionary()
    let traitsDict = NSMutableDictionary()

    let theSymbolicTraits = CTFontSymbolicTraits(
      rawValue: _stylisticTraits.rawValue | stylisticClass.rawValue)

    if theSymbolicTraits.rawValue != 0 {
      traitsDict[kCTFontSymbolicTrait as String] = NSNumber(value: theSymbolicTraits.rawValue)
    }

    if traitsDict.count > 0 {
      tmpDict[kCTFontTraitsAttribute as String] = traitsDict
    }

    if let fontFamily = fontFamily {
      tmpDict[kCTFontFamilyNameAttribute as String] = fontFamily
    }

    if let fontName = fontName {
      tmpDict[kCTFontNameAttribute as String] = fontName
    }

    // we need size because that's what makes a font unique
    tmpDict[kCTFontSizeAttribute as String] = NSNumber(value: Double(_pointSize))

    if smallCapsFeature {
      let typeNum = NSNumber(value: 3)
      let selNum = NSNumber(value: 3)
      let setting: NSDictionary = [
        kCTFontFeatureSelectorIdentifierKey as String: selNum,
        kCTFontFeatureTypeIdentifierKey as String: typeNum,
      ]
      tmpDict[kCTFontFeatureSettingsAttribute as String] = [setting]
    }

    if _sizeCategory != 0 {
      tmpDict["NSCTFontSizeCategoryAttribute"] = NSNumber(value: _sizeCategory)
    }

    if let usageAttribute = _usageAttribute {
      tmpDict["NSCTFontUIUsageAttribute"] = usageAttribute
    }

    if !self.boldTrait && FontRegistry.shared.needsChineseFontCascadeFix {
      let desc = CTFontDescriptorCreateWithNameAndSize(
        "STHeitiSC-Light" as CFString, self.pointSize)
      tmpDict[kCTFontCascadeListAttribute as String] = [desc]
    }

    return tmpDict
  }

  private func fontAttributes(withOverrideFontName overrideFontName: String) -> NSDictionary {
    let tmpAttributes = NSMutableDictionary(dictionary: fontAttributes())
    tmpAttributes.removeObject(forKey: kCTFontFamilyNameAttribute as String)
    tmpAttributes[kCTFontNameAttribute as String] = overrideFontName
    return tmpAttributes
  }

  // MARK: - Small Caps

  /// Determines if the font described by the receiver has native small caps support
  @objc public func supportsNativeSmallCaps() -> Bool {
    if CoreTextFontDescriptor.smallCapsFontName(
      forFontFamily: fontFamily ?? "", bold: boldTrait, italic: italicTrait) != nil
    {
      return true
    }

    var smallCapsSupported = false

    if let tmpFont = newMatchingFont() {
      if let fontFeatures = CTFontCopyFeatures(tmpFont) as? [[String: Any]] {
        for oneFeature in fontFeatures {
          let featureTypeId =
            (oneFeature[kCTFontFeatureTypeIdentifierKey as String] as? NSNumber)?.intValue ?? 0

          if featureTypeId == 3 {  // Letter Case
            if let featureSelectors = oneFeature[kCTFontFeatureTypeSelectorsKey as String]
              as? [[String: Any]]
            {
              for oneSelector in featureSelectors {
                let selectorId =
                  (oneSelector[kCTFontFeatureSelectorIdentifierKey as String] as? NSNumber)?
                  .intValue ?? 0
                if selectorId == 3 {  // Small Caps
                  smallCapsSupported = true
                  break
                }
              }
            }
            break
          }
        }
      }
    }

    return smallCapsSupported
  }

  // MARK: - CSS

  /// The CSS style sheet representation of the receiver
  @objc public func cssStyleRepresentation() -> String? {
    var retString = ""

    if let fontFamily = fontFamily {
      retString += "font-family:'\(fontFamily)';"
    }

    retString += String(format: "font-size:%.0fpx;", _pointSize)

    if italicTrait {
      retString += "font-style:italic;"
    }

    if boldTrait {
      retString += "font-weight:bold;"
    }

    return retString.isEmpty ? nil : retString
  }

  // MARK: - Trait Properties

  @objc public var symbolicTraits: CTFontSymbolicTraits {
    get {
      return CTFontSymbolicTraits(rawValue: _stylisticTraits.rawValue | stylisticClass.rawValue)
    }
    set {
      _stylisticTraits = CTFontSymbolicTraits(
        rawValue: newValue.rawValue & ~CTFontSymbolicTraits.classMaskTrait.rawValue)
      stylisticClass = CTFontStylisticClass(
        rawValue: newValue.rawValue & CTFontSymbolicTraits.classMaskTrait.rawValue)
    }
  }

  @objc public var boldTrait: Bool {
    get { return _stylisticTraits.contains(.traitBold) }
    set {
      if newValue {
        _stylisticTraits.insert(.traitBold)
      } else {
        _stylisticTraits.remove(.traitBold)
      }
    }
  }

  @objc public var italicTrait: Bool {
    get { return _stylisticTraits.contains(.traitItalic) }
    set {
      if newValue {
        _stylisticTraits.insert(.traitItalic)
      } else {
        _stylisticTraits.remove(.traitItalic)
      }
    }
  }

  @objc public var expandedTrait: Bool {
    get { return _stylisticTraits.contains(.traitExpanded) }
    set {
      if newValue {
        _stylisticTraits.insert(.traitExpanded)
      } else {
        _stylisticTraits.remove(.traitExpanded)
      }
    }
  }

  @objc public var condensedTrait: Bool {
    get { return _stylisticTraits.contains(.traitCondensed) }
    set {
      if newValue {
        _stylisticTraits.insert(.traitCondensed)
      } else {
        _stylisticTraits.remove(.traitCondensed)
      }
    }
  }

  @objc public var monospaceTrait: Bool {
    get { return _stylisticTraits.contains(.traitMonoSpace) }
    set {
      if newValue {
        _stylisticTraits.insert(.traitMonoSpace)
      } else {
        _stylisticTraits.remove(.traitMonoSpace)
      }
    }
  }

  @objc public var verticalTrait: Bool {
    get { return _stylisticTraits.contains(.traitVertical) }
    set {
      if newValue {
        _stylisticTraits.insert(.traitVertical)
      } else {
        _stylisticTraits.remove(.traitVertical)
      }
    }
  }

  @objc public var UIoptimizedTrait: Bool {
    get { return _stylisticTraits.contains(.traitUIOptimized) }
    set {
      if newValue {
        _stylisticTraits.insert(.traitUIOptimized)
      } else {
        _stylisticTraits.remove(.traitUIOptimized)
      }
    }
  }

  // MARK: - NSObject

  open override var description: String {
    var string = "<\(type(of: self))"

    if let fontName = fontName {
      string += " name='\(fontName)'"
    }

    if let fontFamily = fontFamily {
      string += " family='\(fontFamily)'"
    }

    string += String(format: " size:%.0f", _pointSize)

    var tmpTraits: [String] = []

    if _stylisticTraits.contains(.traitBold) { tmpTraits.append("bold") }
    if _stylisticTraits.contains(.traitItalic) { tmpTraits.append("italic") }
    if _stylisticTraits.contains(.traitMonoSpace) { tmpTraits.append("monospace") }
    if _stylisticTraits.contains(.traitCondensed) { tmpTraits.append("condensed") }
    if _stylisticTraits.contains(.traitExpanded) { tmpTraits.append("expanded") }
    if _stylisticTraits.contains(.traitVertical) { tmpTraits.append("vertical") }
    if _stylisticTraits.contains(.traitUIOptimized) { tmpTraits.append("UI optimized") }

    if !tmpTraits.isEmpty {
      string += " attributes=" + tmpTraits.joined(separator: ", ")
    }

    string += ">"
    return string
  }

  open override var hash: Int {
    var calcHash = 7
    calcHash = calcHash &* 31 &+ Int(_pointSize)
    calcHash = calcHash &* 31 &+ Int(stylisticClass.rawValue | _stylisticTraits.rawValue)
    calcHash = calcHash &* 31 &+ (fontName?.hashValue ?? 0)
    calcHash = calcHash &* 31 &+ (fontFamily?.hashValue ?? 0)
    return calcHash
  }

  open override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? CoreTextFontDescriptor else { return false }
    if other === self { return true }

    if _pointSize != other._pointSize { return false }
    if stylisticClass != other.stylisticClass { return false }
    if _stylisticTraits != other._stylisticTraits { return false }
    if fontName != other.fontName { return false }
    if fontFamily != other.fontFamily { return false }

    return true
  }

  // MARK: - NSCoding

  @objc public func encode(with coder: NSCoder) {
    coder.encode(fontName, forKey: "FontName")
    coder.encode(fontFamily, forKey: "FontFamily")
    coder.encode(boldTrait, forKey: "BoldTrait")
    coder.encode(italicTrait, forKey: "ItalicTrait")
  }

  @objc public required init?(coder: NSCoder) {
    super.init()
    FontRegistry.shared.ensureInitialized()
    fontName = coder.decodeObject(forKey: "FontName") as? String
    fontFamily = coder.decodeObject(forKey: "FontFamily") as? String
    boldTrait = coder.decodeBool(forKey: "BoldTrait")
    italicTrait = coder.decodeBool(forKey: "ItalicTrait")
  }

  // MARK: - NSCopying

  @objc open func copy(with zone: NSZone? = nil) -> Any {
    let newDesc = CoreTextFontDescriptor(fontAttributes: fontAttributes())
    newDesc.pointSize = self.pointSize
    return newDesc
  }

  // MARK: - Stylistic Class Setter

  open func setStylisticClass(_ newClass: CTFontStylisticClass) {
    self.fontFamily = nil
    self.stylisticClass = newClass
  }

  // MARK: - Global Font Overriding

  /// Preloads all available system fonts into a lookup table for faster font matching.
  /// ObjC-compatible fire-and-forget entry point.
  @objc public class func asyncPreloadFontLookupTable() {
    FontRegistry.shared.ensureInitialized()
    Task.detached(priority: .utility) {
      await preloadFontLookupTable()
    }
  }

  /// Preloads all available system fonts into a lookup table for faster font matching.
  public class func preloadFontLookupTable() async {
    FontRegistry.shared.ensureInitialized()
    let dictionary = await _allAvailableFontOverrideNames()
    FontRegistry.shared.mergeOverrides(dictionary)
  }

  private class func _allAvailableFontOverrideNames() async -> [String: String] {
    let allFonts = CoreTextFontCollection.availableFontsCollection()
    guard let descriptors = allFonts.fontDescriptors() as? [CoreTextFontDescriptor] else {
      return [:]
    }

    var tmpDictionary = [String: String]()

    let sortedFonts = descriptors.sorted { lhs, rhs in
      let familyCompare = (lhs.fontFamily ?? "").compare(rhs.fontFamily ?? "")
      if familyCompare != .orderedSame { return familyCompare == .orderedAscending }
      return (lhs.fontName ?? "").compare(rhs.fontName ?? "") == .orderedAscending
    }

    for oneFontDescriptor in sortedFonts {
      let key =
        "\(oneFontDescriptor.fontFamily ?? "")-\(oneFontDescriptor.boldTrait ? 1 : 0)-\(oneFontDescriptor.italicTrait ? 1 : 0)-override"

      if let existing = tmpDictionary[key] {
        if let name = oneFontDescriptor.fontName, existing.count > name.count {
          tmpDictionary[key] = name
        }
      } else {
        tmpDictionary[key] = oneFontDescriptor.fontName
      }
    }

    return tmpDictionary
  }

  /// Sets the font family to use if the font family in a font descriptor is invalid.
  @objc public class func setFallbackFontFamily(_ fontFamily: String) {
    FontRegistry.shared.ensureInitialized()

    guard !fontFamily.isEmpty else {
      NSException(
        name: NSExceptionName(DTCoreTextFontDescriptorException as String),
        reason: "Fallback Font Family cannot be nil"
      ).raise()
      return
    }

    let attributes: NSDictionary = [kCTFontFamilyNameAttribute as String: fontFamily]
    let fontDesc = CTFontDescriptorCreateWithAttributes(attributes)
    let font = CTFontCreateWithFontDescriptor(fontDesc, 12, nil)

    let usedFontFamily = CTFontCopyFamilyName(font) as String
    guard usedFontFamily == fontFamily else {
      NSException(
        name: NSExceptionName(DTCoreTextFontDescriptorException as String),
        reason: "Fallback Font Family '\(fontFamily)' not registered on the system"
      ).raise()
      return
    }

    FontRegistry.shared.setFallbackFontFamily(fontFamily)
  }

  /// Returns the font family to use if the font family in a font descriptor is invalid.
  @objc public class func fallbackFontFamily() -> String {
    FontRegistry.shared.ensureInitialized()
    return FontRegistry.shared.fallbackFontFamily
  }

  /// Sets the global font name override for a given font family with bold and italic traits.
  @objc public class func setOverrideFontName(
    _ fontName: String, forFontFamily fontFamily: String, bold: Bool, italic: Bool
  ) {
    FontRegistry.shared.ensureInitialized()
    FontRegistry.shared.setOverrideFontName(fontName, forFontFamily: fontFamily, bold: bold, italic: italic)
  }

  /// Retrieves the global font name override for a given font family with bold and italic traits.
  @objc public class func overrideFontName(
    forFontFamily fontFamily: String, bold: Bool, italic: Bool
  ) -> String? {
    FontRegistry.shared.ensureInitialized()
    return FontRegistry.shared.overrideFontName(forFontFamily: fontFamily, bold: bold, italic: italic)
  }

  /// Sets the global font name override for small caps text.
  @objc public class func setSmallCapsFontName(
    _ fontName: String, forFontFamily fontFamily: String, bold: Bool, italic: Bool
  ) {
    FontRegistry.shared.ensureInitialized()
    FontRegistry.shared.setSmallCapsFontName(fontName, forFontFamily: fontFamily, bold: bold, italic: italic)
  }

  /// Retrieves the global font name override for small caps text.
  @objc public class func smallCapsFontName(
    forFontFamily fontFamily: String, bold: Bool, italic: Bool
  ) -> String? {
    FontRegistry.shared.ensureInitialized()
    return FontRegistry.shared.smallCapsFontName(forFontFamily: fontFamily, bold: bold, italic: italic)
  }

  // MARK: - Private Font Matching

  private func _fontIsOblique(_ font: CTFont) -> Bool {
    guard let traits = CTFontCopyTraits(font) as? [String: Any] else { return false }

    let slant = (traits[kCTFontSlantTrait as String] as? NSNumber)?.floatValue ?? 0
    let symbolicValue = (traits[kCTFontSymbolicTrait as String] as? NSNumber)?.uint32Value ?? 0
    let hasItalicTrait = (symbolicValue & CTFontSymbolicTraits.traitItalic.rawValue) != 0

    if !hasItalicTrait || slant < 0.01 {
      return false
    }

    return true
  }

  private func _findOrMakeMatchingFont() -> CTFont? {
    var searchingFontDescriptor: CTFontDescriptor?
    var matchingFontDescriptor: CTFontDescriptor?
    var matchingFontDescriptors: CFArray?
    var matchingFont: CTFont?

    // check the cache first
    let cacheKey = NSNumber(value: self.hash)
    if let cachedFont = FontRegistry.shared.cachedFont(forKey: cacheKey) {
      return (cachedFont as! CTFont)
    }

    // check the override table
    var overrideName: String?

    if fontFamily != nil && fontName == nil {
      if smallCapsFeature {
        overrideName = CoreTextFontDescriptor.smallCapsFontName(
          forFontFamily: fontFamily ?? "", bold: boldTrait, italic: italicTrait)
      } else {
        overrideName = CoreTextFontDescriptor.overrideFontName(
          forFontFamily: fontFamily ?? "", bold: boldTrait, italic: italicTrait)
      }
    }

    // if we use the chinese font cascade fix we cannot use fast method
    let useFastFontCreation = !(FontRegistry.shared.needsChineseFontCascadeFix && !self.boldTrait)

    if useFastFontCreation
      && ((fontName != nil && !(fontName?.hasPrefix(".") ?? false)) || overrideName != nil)
    {
      let usedName = overrideName ?? fontName!
      matchingFont = CTFontCreateWithName(usedName as CFString, _pointSize, nil)
    } else {
      // we need to search for a suitable font
      let attrs: NSDictionary
      if let overrideName = overrideName {
        attrs = fontAttributes(withOverrideFontName: overrideName)
      } else {
        attrs = fontAttributes()
      }

      searchingFontDescriptor = CTFontDescriptorCreateWithAttributes(attrs)

      let mandatoryAttributes = NSMutableSet()
      mandatoryAttributes.add(kCTFontTraitsAttribute as String)

      if fontFamily != nil {
        mandatoryAttributes.add(kCTFontFamilyNameAttribute as String)
      }

      if smallCapsFeature {
        mandatoryAttributes.add(kCTFontFeaturesAttribute as String)
      }

      matchingFontDescriptors = CTFontDescriptorCreateMatchingFontDescriptors(
        searchingFontDescriptor!, mandatoryAttributes)

      if let descriptors = matchingFontDescriptors {
        let count = CFArrayGetCount(descriptors)
        if count == 1 {
          matchingFontDescriptor = CTFontDescriptorCreateMatchingFontDescriptor(
            searchingFontDescriptor!, mandatoryAttributes)
        } else {
          for i in 0..<count {
            let currentFD = unsafeBitCast(
              CFArrayGetValueAtIndex(descriptors, i), to: CTFontDescriptor.self)
            if let traits = CTFontDescriptorCopyAttribute(currentFD, kCTFontTraitsAttribute)
              as? [String: Any]
            {
              let hasSlantValue = (traits["NSCTFontSlantTrait"] as? NSNumber)?.boolValue ?? false
              let hasBoldValue = (traits["NSCTFontWeightTrait"] as? NSNumber)?.boolValue ?? false

              let hasMatchingBold = hasBoldValue == self.boldTrait
              let hasMatchingItalic = hasSlantValue == self.italicTrait

              if hasMatchingBold && hasMatchingItalic {
                matchingFontDescriptor = currentFD
                break
              }
            }
          }
        }
      }

      if matchingFontDescriptor == nil {
        // try without traits
        let mutableAttributes = NSMutableDictionary(dictionary: attrs)
        mutableAttributes.removeObject(forKey: kCTFontTraitsAttribute as String)

        searchingFontDescriptor = CTFontDescriptorCreateWithAttributes(mutableAttributes)
        matchingFontDescriptor = CTFontDescriptorCreateMatchingFontDescriptor(
          searchingFontDescriptor!, nil)
      }

      if matchingFontDescriptor == nil {
        // try with fallback font family
        let mutableAttributes = NSMutableDictionary(dictionary: attrs)
        mutableAttributes[kCTFontFamilyNameAttribute as String] = FontRegistry.shared.fallbackFontFamily

        searchingFontDescriptor = CTFontDescriptorCreateWithAttributes(mutableAttributes)

        matchingFontDescriptors = CTFontDescriptorCreateMatchingFontDescriptors(
          searchingFontDescriptor!, nil)
        if let descriptors = matchingFontDescriptors {
          let count = CFArrayGetCount(descriptors)
          if count == 1 {
            matchingFontDescriptor = CTFontDescriptorCreateMatchingFontDescriptor(
              searchingFontDescriptor!, mandatoryAttributes)
          } else {
            for i in 0..<count {
              let currentFD = unsafeBitCast(
                CFArrayGetValueAtIndex(descriptors, i), to: CTFontDescriptor.self)
              if let traits = CTFontDescriptorCopyAttribute(currentFD, kCTFontTraitsAttribute)
                as? [String: Any]
              {
                let hasSlantValue = (traits["NSCTFontSlantTrait"] as? NSNumber)?.boolValue ?? false
                let hasBoldValue = (traits["NSCTFontWeightTrait"] as? NSNumber)?.boolValue ?? false

                let hasMatchingBold = hasBoldValue == self.boldTrait
                let hasMatchingItalic = hasSlantValue == self.italicTrait

                if hasMatchingBold && hasMatchingItalic {
                  matchingFontDescriptor = currentFD
                  break
                }
              }
            }
          }
        }
      }
    }

    // any search was successful
    if let fd = matchingFontDescriptor {
      matchingFont = CTFontCreateWithFontDescriptor(fd, _pointSize, nil)
    }

    // check if we indeed got an oblique font if we wanted one
    if let font = matchingFont, self.italicTrait && !_fontIsOblique(font) {
      // need to synthesize slant
      var slantMatrix = CGAffineTransform(a: 1, b: 0, c: 0.25, d: 1, tx: 0, ty: 0)
      matchingFont = CTFontCreateCopyWithAttributes(font, _pointSize, &slantMatrix, nil)
    }

    // add found font to cache
    if let font = matchingFont {
      FontRegistry.shared.cacheFont(font, forKey: cacheKey)
    }

    return matchingFont
  }
}
