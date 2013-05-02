//
//  NSDictionary+DTRichText.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 7/21/11.
//  Copyright 2011 Cocoanetics. All rights reserved.
//

@class DTCoreTextParagraphStyle;
@class DTCoreTextFontDescriptor;

/**
 Convenience methods for editors dealing with Core Text attribute dictionaries.
 */
@interface NSDictionary (DTRichText)

/**
 @name Getting State information
 */

/**
 Whether the font in the receiver's attributes is bold.
 @returns `YES` if the text has a bold trait
 */
- (BOOL)isBold;

/**
 Whether the font in the receiver's attributes is italic.
 @returns `YES` if the text has an italic trait
 */
- (BOOL)isItalic;

/**
 Whether the receiver's attributes contains underlining.
 @returns `YES` if the text is underlined
 */
- (BOOL)isUnderline;

/**
 Whether the receiver's attributes contain a DTTextAttachment
 @returns `YES` if ther is an attachment
 */
- (BOOL)hasAttachment;

/**
 @name Getting Style Information
 */

/**
 Retrieves the DTCoreTextParagraphStyle from the receiver's attributes. This supports both `CTParagraphStyle` as well as `NSParagraphStyle` as a possible representation of the text's paragraph style.
 @returns The paragraph style
 */
- (DTCoreTextParagraphStyle *)paragraphStyle;

/**
 Retrieves the DTCoreTextFontDescriptor from the receiver's attributes. This supports both `CTFont` as well as `UIFont` as a possible representation of the text's font.
 @returns The font descriptor
 */
- (DTCoreTextFontDescriptor *)fontDescriptor;

@end
