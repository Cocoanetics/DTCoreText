import Foundation
import CoreText

/// Class representing a collection of fonts
@objc(DTCoreTextFontCollection)
open class CoreTextFontCollection: NSObject {

    private var _fontDescriptors: NSArray?
    private var _fontMatchCache: NSCache<NSString, CoreTextFontDescriptor>?

    nonisolated(unsafe) private static var _availableFontsCollection: CoreTextFontCollection?

    /// Creates a font collection with all available fonts on the system
    @objc public class func availableFontsCollection() -> CoreTextFontCollection {
        if let existing = _availableFontsCollection {
            return existing
        }

        let instance = CoreTextFontCollection(availableFonts: ())
        _availableFontsCollection = instance
        return instance
    }

    private init(availableFonts: Void) {
        super.init()
    }

    /// The font descriptor describing a font in the receiver's collection that matches a given descriptor
    @objc public func matchingFontDescriptor(for descriptor: CoreTextFontDescriptor) -> CoreTextFontDescriptor? {
        let cacheKey = NSString(format: "fontFamily BEGINSWITH[cd] %@ and boldTrait == %d and italicTrait == %d", descriptor.fontFamily ?? "", descriptor.boldTrait ? 1 : 0, descriptor.italicTrait ? 1 : 0)

        // try cache
        if let firstMatch = fontMatchCache.object(forKey: cacheKey) {
            let retMatch = firstMatch.copy() as! CoreTextFontDescriptor
            retMatch.pointSize = descriptor.pointSize
            return retMatch
        }

        // need to search
        let predicate = NSPredicate(format: "fontFamily BEGINSWITH[cd] %@ and boldTrait == %d and italicTrait == %d", descriptor.fontFamily ?? "", NSNumber(value: descriptor.boldTrait), NSNumber(value: descriptor.italicTrait))

        let matching = (fontDescriptors() as NSArray).filtered(using: predicate)

        if let firstMatch = matching.first as? CoreTextFontDescriptor {
            fontMatchCache.setObject(firstMatch, forKey: cacheKey)

            let retMatch = firstMatch.copy() as! CoreTextFontDescriptor
            retMatch.pointSize = descriptor.pointSize
            return retMatch
        }

        return nil
    }

    // MARK: - Properties

    /// The font descriptors describing all fonts in the receiver's font collection
    @objc public func fontDescriptors() -> NSArray {
        if let existing = _fontDescriptors {
            return existing
        }

        let fonts = CTFontCollectionCreateFromAvailableFonts(nil)
        guard let matchingFonts = CTFontCollectionCreateMatchingFontDescriptors(fonts) as? [CTFontDescriptor] else {
            return NSArray()
        }

        let tmpArray = NSMutableArray()

        for fontDesc in matchingFonts {
            let desc = CoreTextFontDescriptor(ctFontDescriptor: fontDesc)
            tmpArray.add(desc)
        }

        _fontDescriptors = tmpArray
        return tmpArray
    }

    private var fontMatchCache: NSCache<NSString, CoreTextFontDescriptor> {
        if let existing = _fontMatchCache {
            return existing
        }
        let cache = NSCache<NSString, CoreTextFontDescriptor>()
        _fontMatchCache = cache
        return cache
    }

    /// The font family names that occur in the receiver's list of fonts
    @objc public func fontFamilyNames() -> [String] {
        var tmpArray = [String]()

        for descriptor in fontDescriptors() {
            if let desc = descriptor as? CoreTextFontDescriptor, let familyName = desc.fontFamily {
                if !tmpArray.contains(familyName) {
                    tmpArray.append(familyName)
                }
            }
        }

        return tmpArray.sorted()
    }
}
