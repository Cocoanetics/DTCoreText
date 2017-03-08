//
//  DTCoreTextFontDescriptor.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/26/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//


/**
 This class describes the attributes of a font. It is used to represent fonts throughout the parsing and when needed is able to generated matching `CTFont` instances.
 */
@interface DTCoreTextFontDescriptor : NSObject <NSCopying, NSCoding>

/**
 @name Creating Font Descriptors
 */

/**
 Convenience method to create a font descriptor from a font attributes dictionary
 @param attributes The dictionary of font attributes
 @returns An initialized font descriptor
 */
+ (DTCoreTextFontDescriptor *)fontDescriptorWithFontAttributes:(NSDictionary *)attributes;

/**
 Convenience method for creates a font descriptor from a Core Text font
 @param ctFont The Core Text font
 @returns An initialized font descriptor
 */
+ (DTCoreTextFontDescriptor *)fontDescriptorForCTFont:(CTFontRef)ctFont;

/**
 Creates a font descriptor from a font attributes dictionary
 @param attributes The dictionary of font attributes
 @returns An initialized font descriptor
 */
- (id)initWithFontAttributes:(NSDictionary *)attributes;

/**
 Creates a font descriptor from a Core Text font descriptor
 @param ctFontDescriptor The Core Text font descriptor
 @returns An initialized font descriptor
 */
- (id)initWithCTFontDescriptor:(CTFontDescriptorRef)ctFontDescriptor;

/**
 Creates a font descriptor from a Core Text font
 @param ctFont The Core Text font
 @returns An initialized font descriptor
 */
- (id)initWithCTFont:(CTFontRef)ctFont;


/**
 @name Creating Fonts from Font Descriptors
 */

/**
 Creates a `CTFont` matching the receiver's attribute
 @returns a +1 owning reference of a Core Text font
 */
- (CTFontRef)newMatchingFont;

/**
 @name Specifying Font Attributes
 */


/**
 Sets the font attributes from a dictionary
 @param newAttributes The font attributes dictionary
 */
- (void)setFontAttributes:(NSDictionary *)newAttributes;

/**
 Retrieves a dictionary of font attributes
 */
- (NSDictionary *)fontAttributes;


/**
 The font family name of the described font
 */
@property (nonatomic, copy) NSString *fontFamily;

/**
 The font name of the described font
 */
@property (nonatomic, copy) NSString *fontName;

/**
 The point size of the described font
 */
@property (nonatomic) CGFloat pointSize;

/**
 Whether the described font has the bold trait
 */
@property (nonatomic) BOOL boldTrait;

/**
 Whether the described font has the italic trait
 */
@property (nonatomic) BOOL italicTrait;

/**
 Whether the described font has the expanded trait
 */
@property (nonatomic) BOOL expandedTrait;

/**
 Whether the described font has the condensed trait
 */
@property (nonatomic) BOOL condensedTrait;

/**
 Whether the described font has the monospace trait
 */
@property (nonatomic) BOOL monospaceTrait;

/**
 Whether the described font has the vertical trait
 */
@property (nonatomic) BOOL verticalTrait;

/**
 Whether the described font is optimized for use in User Interfaces
 */
@property (nonatomic) BOOL UIoptimizedTrait;

/**
 The symbolic traits of the receiver
 */
@property (nonatomic) CTFontSymbolicTraits symbolicTraits;

/**
 The stylistic class of the receiver
 */
@property (nonatomic) CTFontStylisticClass stylisticClass;

/**
 `YES` if the small caps style is enabled, `NO` if not
 */
@property (nonatomic) BOOL smallCapsFeature;

/**
 Determining if the font described by the receiver has native small caps support
 @returns `YES` if this font supports native small caps
 */
- (BOOL)supportsNativeSmallCaps;

/**
 Working with CSS
 */

/**
 The CSS style sheet representation of the receiver
 @returns A CSS style string
 */
- (NSString *)cssStyleRepresentation;


/**
 @name Global Font Overriding
 */

/**
 A call to the method is ideally placed into your app delegate. This loads all available system fonts into a look up table to allow DTCoreText to quickly find a specific combination of font-family and italic and bold attributes. Please refer to the [Programming Guide](../docs/Programming%20Guide.html) for information when you should be using this.
 
 Calling this does not replace entries already existing in the lookup table, for example loaded from the `DTCoreTextFontOverrides.plist` included in the app bundle.
 */
+ (void)asyncPreloadFontLookupTable;

/**
 Sets the font family to use if the font family in a font descriptor is invalid.
 
 The fallback font family cannot be `nil` and must be a valid font family. The default is **Times New Roman**. 
 @param fontFamily The font family
 */
+ (void)setFallbackFontFamily:(NSString *)fontFamily;

/**
 Returns the font family to use if the font family in a font descriptor is invalid. The default is **Times New Roman**.
 @returns The font family
 */
+ (NSString *)fallbackFontFamily;

/**
 Sets the global font name override to use when encountering a font family with given bold and italic attributes.
 @param fontName The font name to use
 @param fontFamily The font family to use this for
 @param bold The bold trait
 @param italic The italic trait
 */
+ (void)setOverrideFontName:(NSString *)fontName forFontFamily:(NSString *)fontFamily bold:(BOOL)bold italic:(BOOL)italic;

/**
 Retrieves the global font name override for a given font family with bold and italic traits.
 @param fontFamily The font family to retrieve the override for
 @param bold The bold trait
 @param italic The italic trait
 @returns The font name to use for this combination of parameters
 */
+ (NSString *)overrideFontNameforFontFamily:(NSString *)fontFamily bold:(BOOL)bold italic:(BOOL)italic;

/**
 Sets the global font name override to use when encountering small caps text in a font family with given bold and italic attributes.
 @param fontName The font name to use
 @param fontFamily The font family to use this for
 @param bold The bold trait
 @param italic The italic trait
 */
+ (void)setSmallCapsFontName:(NSString *)fontName forFontFamily:(NSString *)fontFamily bold:(BOOL)bold italic:(BOOL)italic;

/**
 Retrieves the global font name override to use for small caps text for a given font family with bold and italic traits.
 @param fontFamily The font family to retrieve the override for
 @param bold The bold trait
 @param italic The italic trait
 @returns The font name to use for this combination of parameters
 */
+ (NSString *)smallCapsFontNameforFontFamily:(NSString *)fontFamily bold:(BOOL)bold italic:(BOOL)italic;

@end
