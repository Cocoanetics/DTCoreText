//
//  DTCoreTextFontDescriptor.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/26/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextFontDescriptor.h"


@implementation DTCoreTextFontDescriptor


+ (DTCoreTextFontDescriptor *)fontDescriptorWithFontAttributes:(NSDictionary *)attributes
{
	return [[[DTCoreTextFontDescriptor alloc] initWithFontAttributes:attributes] autorelease];
}

- (id)initWithFontAttributes:(NSDictionary *)attributes
{
	if (self = [super init])
	{
		if (attributes) 
		{
			NSDictionary *traitsDict = [attributes objectForKey:(id)kCTFontTraitsAttribute];
			
			CTFontSymbolicTraits traitsValue = [[traitsDict objectForKey:(id)kCTFontSymbolicTrait ] unsignedIntValue];
			
			if (traitsValue & kCTFontBoldTrait)
			{
				boldTrait = YES;
			}
			
			if (traitsValue & kCTFontItalicTrait)
			{
				italicTrait = YES;
			}
			
			if (traitsValue & kCTFontExpandedTrait)
			{
				expandedTrait = YES;
			}
			
			if (traitsValue & kCTFontCondensedTrait)
			{
				condensedTrait = YES;
			}
			
			if (traitsValue & kCTFontMonoSpaceTrait)
			{
				monospaceTrait = YES;
			}
			
			if (traitsValue & kCTFontVerticalTrait)
			{
				verticalTrait = YES;
			}
			
			if (traitsValue & kCTFontUIOptimizedTrait)
			{
				UIoptimizedTrait = YES;
			}
			
			pointSize = [[attributes objectForKey:(id)kCTFontSizeAttribute] floatValue];
			
			self.fontFamily = [attributes objectForKey:(id)kCTFontFamilyNameAttribute];
		}
	}
	
	return self;
}


- (CTFontSymbolicTraits)symbolicTraits
{
	CTFontSymbolicTraits retValue = 0;
	
	
	if (boldTrait)
	{
		retValue |= kCTFontBoldTrait;
	}
		
	if (italicTrait)
	{
		retValue |= kCTFontItalicTrait;
	}
	
	if (expandedTrait)
	{
		retValue |= kCTFontExpandedTrait;
	}
	
	if (condensedTrait)
	{
		retValue |= kCTFontCondensedTrait;
	}
	
	if (monospaceTrait)
	{
		retValue |= kCTFontMonoSpaceTrait;
	}
	
	if (verticalTrait)
	{
		retValue |= kCTFontVerticalTrait;
	}
	
	if (UIoptimizedTrait)
	{
		retValue |= kCTFontUIOptimizedTrait;
	}
	
	return retValue;
}

- (NSDictionary *)fontAttributes
{
	
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *traitsDict = [NSMutableDictionary dictionary];
	
	CTFontSymbolicTraits symbolicTraits = [self symbolicTraits];
	
	if (symbolicTraits)
	{
		[traitsDict setObject:[NSNumber numberWithUnsignedInt:symbolicTraits] forKey:(id)kCTFontSymbolicTrait];
	}
	
	if ([traitsDict count])
	{
		[tmpDict setObject:traitsDict forKey:(id)kCTFontTraitsAttribute];
	}
	
	if (fontFamily)
	{
		[tmpDict setObject:fontFamily forKey:(id)kCTFontFamilyNameAttribute];
	}
	
	[tmpDict setObject:[NSNumber numberWithFloat:pointSize] forKey:(id)kCTFontSizeAttribute];
	
	return [NSDictionary dictionaryWithDictionary:tmpDict];
}

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
	DTCoreTextFontDescriptor *newDesc = [[DTCoreTextFontDescriptor allocWithZone:zone] initWithFontAttributes:[self fontAttributes]];
	newDesc.pointSize = self.pointSize;
	
	return newDesc;
}


#pragma mark Properties

@synthesize fontFamily;

@synthesize pointSize;
@synthesize boldTrait;
@synthesize italicTrait;
@synthesize expandedTrait;
@synthesize condensedTrait;
@synthesize monospaceTrait;
@synthesize verticalTrait;
@synthesize UIoptimizedTrait;

@end

