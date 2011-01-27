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
		[self setFontAttributes:attributes];
	}
	
	return self;
}

- (void)dealloc
{
	[fontFamily release];
	[fontName release];
	
	[super dealloc];
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
	
	// bundle in class
	retValue |= stylisticClass;
	
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
	
	if (fontName)
	{
		[tmpDict setObject:fontName forKey:(id)kCTFontNameAttribute];
	}
	
	[tmpDict setObject:[NSNumber numberWithFloat:pointSize] forKey:(id)kCTFontSizeAttribute];
	
	return [NSDictionary dictionaryWithDictionary:tmpDict];
}

#pragma mark Finding Font



- (void)normalize
{
	CTFontDescriptorRef fontDesc = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)[self fontAttributes]);
	
	if (fontDesc)
	{
		NSSet *set;
		
		if (self.fontFamily)
		{
			set = [NSSet setWithObjects:(id)kCTFontTraitsAttribute, (id)kCTFontFamilyNameAttribute, nil];
		}
		else 
		{
			set = [NSSet setWithObjects:(id)kCTFontTraitsAttribute, nil];
		}
		
		CFArrayRef matches = CTFontDescriptorCreateMatchingFontDescriptors(fontDesc, (CFSetRef)set);
		
		if (matches)
		{
			if (CFArrayGetCount(matches))
			{
				CTFontDescriptorRef matchingDesc = CFArrayGetValueAtIndex(matches, 0);
				
				CFDictionaryRef attributes = CTFontDescriptorCopyAttributes(matchingDesc);
				
				CFStringRef family = CTFontDescriptorCopyAttribute(matchingDesc, kCTFontFamilyNameAttribute);
				if (family)
				{
					self.fontFamily = (id)family;
					CFRelease(family);
				}
				
				if (attributes)
				{
					[self setFontAttributes:(id)attributes];
					CFRelease(attributes);
				}
			}
			else 
			{
				NSLog(@"No matches for %@", (id)fontDesc);
			}
			
			
			CFRelease(matches);
		}
		else 
		{
			NSLog(@"No matches for %@", (id)fontDesc);
		}
		
		CFRelease(fontDesc);
	}
	else 
	{
		NSLog(@"No matches for %@", [self fontAttributes]);
	}
	
	
}

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
	DTCoreTextFontDescriptor *newDesc = [[DTCoreTextFontDescriptor allocWithZone:zone] initWithFontAttributes:[self fontAttributes]];
	newDesc.pointSize = self.pointSize;
	if (stylisticClass)
	{
		newDesc.stylisticClass = self.stylisticClass;
	}
	
	return newDesc;
}


#pragma mark Properties
- (void)setStylisticClass:(CTFontStylisticClass)newClass
{
	self.fontFamily = nil;
	
	stylisticClass = newClass;
}


- (void)setFontAttributes:(NSDictionary *)attributes
{
	if (!attributes) 
	{
		self.fontFamily = nil;
		self.pointSize = 12;
		
		boldTrait = NO;
		italicTrait = NO;
		expandedTrait = NO;
		condensedTrait = NO;
		monospaceTrait = NO;
		verticalTrait = NO;
		UIoptimizedTrait = NO;
	}
	
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
	
	// stylistic class is bundled in the traits
	stylisticClass = traitsValue & kCTFontClassMaskTrait;
	
	
	NSNumber *pointNum = [attributes objectForKey:(id)kCTFontSizeAttribute];
	if (pointNum)
	{
		pointSize = [pointNum floatValue];
	}
	
	NSString *family = [attributes objectForKey:(id)kCTFontFamilyNameAttribute];
	
	if (family)
	{
		self.fontFamily = family;
	}
	
	NSString *name = [attributes objectForKey:(id)kCTFontNameAttribute];
	
	if (name)
	{
		self.fontName = name;
	}
	
}


@synthesize fontFamily;
@synthesize fontName;

@synthesize pointSize;
@synthesize boldTrait;
@synthesize italicTrait;
@synthesize expandedTrait;
@synthesize condensedTrait;
@synthesize monospaceTrait;
@synthesize verticalTrait;
@synthesize UIoptimizedTrait;

@synthesize stylisticClass;

@end

