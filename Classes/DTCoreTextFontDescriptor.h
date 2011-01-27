//
//  DTCoreTextFontDescriptor.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/26/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>


@interface DTCoreTextFontDescriptor : NSObject <NSCopying>
{
	NSString *fontFamily;
	NSString *fontName;
	
	CGFloat pointSize;
	
	// symbolic traits
	BOOL boldTrait;
	BOOL italicTrait;
	BOOL expandedTrait;
	BOOL condensedTrait;
	BOOL monospaceTrait;
	BOOL verticalTrait;
	BOOL UIoptimizedTrait;
	
	CTFontStylisticClass stylisticClass;
}

+ (DTCoreTextFontDescriptor *)fontDescriptorWithFontAttributes:(NSDictionary *)attributes;

- (id)initWithFontAttributes:(NSDictionary *)attributes;
- (void)setFontAttributes:(NSDictionary *)newAttributes;

- (void)normalize;

- (CTFontSymbolicTraits)symbolicTraits;
- (NSDictionary *)fontAttributes;

@property (nonatomic, copy) NSString *fontFamily;
@property (nonatomic, copy) NSString *fontName;

@property (nonatomic, assign) CGFloat pointSize;

@property (nonatomic) BOOL boldTrait;
@property (nonatomic) BOOL italicTrait;
@property (nonatomic) BOOL expandedTrait;
@property (nonatomic) BOOL condensedTrait;
@property (nonatomic) BOOL monospaceTrait;
@property (nonatomic) BOOL verticalTrait;
@property (nonatomic) BOOL UIoptimizedTrait;

@property (nonatomic) CTFontStylisticClass stylisticClass;


@end
