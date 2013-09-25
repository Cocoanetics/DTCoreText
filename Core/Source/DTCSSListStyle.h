//
//  DTCSSListStyle.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 8/11/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

/**
 List Styles
 */
typedef NS_ENUM(NSUInteger, DTCSSListStyleType)
{
	/**
	 The list style should be inherited from the parent
	 */
    DTCSSListStyleTypeInherit = 0,
	
	/**
	 No list style
	 */
    DTCSSListStyleTypeNone,
	
	/**
	 Circle bullet list style
	 */
    DTCSSListStyleTypeCircle,
	
	/**
	 Decimal number list style
	 */
    DTCSSListStyleTypeDecimal,

	/**
	 Decimal number list style with a leading zero
	 */
    DTCSSListStyleTypeDecimalLeadingZero,
	
	/**
	 Disc bullet list style
	 */
    DTCSSListStyleTypeDisc,
	
	/**
	 Square bullet list style
	 */
	DTCSSListStyleTypeSquare,
	
	/**
	 Numbered list style with uppercase letters
	 */
    DTCSSListStyleTypeUpperAlpha,
	
	/**
	 Numbered list style with uppercase letters
	 */
    DTCSSListStyleTypeUpperLatin,
	
	/**
	 Numbered list style with lowercase letters
	 */
    DTCSSListStyleTypeLowerAlpha,
	
	/**
	 Numbered list style with lowercase letters
	 */
    DTCSSListStyleTypeLowerLatin,
	
	/**
	 Plus bullet list style
	 */
    DTCSSListStyleTypePlus,
	
	/**
	 Underscore bullet list style
	 */
    DTCSSListStyleTypeUnderscore,
	
	
	/**
	 Image bullet list style
	 */
	DTCSSListStyleTypeImage,
	
	/**
	 Value used to represent an invalid list style
	 */
	DTCSSListStyleTypeInvalid = NSIntegerMax
};

/**
 List Marker Positions
 */
typedef NS_ENUM(NSUInteger, DTCSSListStylePosition)
{
	/**
	 List position should be inherited
	 */
	DTCSSListStylePositionInherit = 0,
	
	/**
	 List prefix position inside
	 */
	DTCSSListStylePositionInside,
	
	/**
	 List prefix position outside
	 */
	DTCSSListStylePositionOutside,
	
	/**
	 Value used to represent an invalid list style position
	 */
	DTCSSListStylePositionInvalid = NSIntegerMax
};


/**
 This class is the equivalent of `NSTextList` on Mac with the added handling of the marker position.
 */
@interface DTCSSListStyle : NSObject


/**
 @name Getting Types from Strings
 */

/**
 Convert a string into a list style type.

 @param string The string to convert
 */
+ (DTCSSListStyleType)listStyleTypeFromString:(NSString *)string;


/**
 Convert a string into a marker position.
 
 @param string The string to convert
 */
+ (DTCSSListStylePosition)listStylePositionFromString:(NSString *)string;

/**
 @name Creating List Styles
 */

/**
 Creates a list style from the passed CSS style dictionary

 @param styles A CSS style dictionary from which the construct a suitable list style
 */
- (id)initWithStyles:(NSDictionary *)styles;

/**
 @name Working with CSS Styles
 */

/**
 Update the receiver from the CSS styles dictionary passed
 
 @param styles A dictionary of CSS styles.
 */
- (void)updateFromStyleDictionary:(NSDictionary *)styles;


/**
 @name Working with Prefixes
 */


/**
 Returns the prefix for lists of the receiver's settings.
 
 @param counter The counter value to use for ordered lists.
 @returns The prefix string to prepend to list items.
 */
- (NSString *)prefixWithCounter:(NSInteger)counter;


/**
 @name Managing Item Numbering
 */


/**
 Sets the starting item number for the text list.
 
 The default value is `1`. This value will be used only for ordered lists, and ignored in other cases.
 
 @param itemNum The item number.
 */
- (void)setStartingItemNumber:(NSInteger)itemNum;


/**
 Returns the starting item number for the text list.
 
 The default value is `1`. This value will be used only for ordered lists, and ignored in other cases.
 @returns The item number.
 */
- (NSInteger)startingItemNumber;


/**
 @name Comparing Lists
 */

/**
 Determine if another list style has equivalent settings. Note that this does not mean that they are identical, only that they look the same.
 @param otherListStyle The other list style to compare the receiver with
 @returns `YES` if the other list style has the same values
 */
- (BOOL)isEqualToListStyle:(DTCSSListStyle *)otherListStyle;


/**
 @name Getting Information about Lists
 */

/**
 Returns if the receiver is an ordered or unordered list
 
 @returns `YES` if the receiver is ordered, `NO` if it is unordered
 */
- (BOOL)isOrdered;

/**
 If the list style is inherited.
 
 @warn This is not implemented.
 */
@property (nonatomic, assign) BOOL inherit; 


/**
 The type of the text list. See DTCSSListStyleType for available types
 */
@property (nonatomic, assign) DTCSSListStyleType type;


/**
 The position of the marker in the prefix. See DTCSSListStylePosition for available positions.
 */
@property (nonatomic, assign) DTCSSListStylePosition position;


/**
 The image name to use for the marker
 */
@property (nonatomic, copy) NSString *imageName;


@end
