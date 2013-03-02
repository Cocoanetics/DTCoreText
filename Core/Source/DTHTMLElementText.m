//
//  DTHTMLElementText.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 26.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLElementText.h"
#import "NSString+HTML.h"
#import "DTCoreTextFontDescriptor.h"
#import "NSAttributedString+SmallCaps.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
#import "UIFont+DTCoreText.h"
#endif

@implementation DTHTMLElementText
{
	NSString *_text;
}

- (void)_appendHTMLToString:(NSMutableString *)string indentLevel:(NSUInteger)indentLevel
{
	// indent to the level
	for (int i=0; i<indentLevel; i++)
	{
		[string appendString:@"   "];
	}
	
	[string appendFormat:@"\"%@\"\n", [_text stringByNormalizingWhitespace]];
}

- (NSAttributedString *)attributedString
{
	@synchronized(self)
	{
		NSString *text;
		
		if (_preserveNewlines)
		{
			text = _text;
			
			// PRE ignores the first \n
			if ([text hasPrefix:@"\n"])
			{
				text = [text substringFromIndex:1];
			}
			
			// PRE ignores the last \n
			if ([text hasSuffix:@"\n"])
			{
				text = [text substringWithRange:NSMakeRange(0, [text length]-1)];
			}
			
			// replace paragraph breaks with line breaks
			// useing \r as to not confuse this with line feeds, but still get a single paragraph
			text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];
		}
		else if (_containsAppleConvertedSpace)
		{
			// replace nbsp; with regular space
			text = [_text stringByReplacingOccurrencesOfString:UNICODE_NON_BREAKING_SPACE withString:@" "];
		}
		else
		{
			text = [_text stringByNormalizingWhitespace];
		}
		
		NSDictionary *attributes = [self attributesDictionary];
		
		if (self.fontVariant == DTHTMLElementFontVariantNormal)
		{
			// make a new attributed string from the text
			return [[NSAttributedString alloc] initWithString:text attributes:attributes];
		}
		else
		{
			if ([self.fontDescriptor supportsNativeSmallCaps])
			{
				DTCoreTextFontDescriptor *smallDesc = [self.fontDescriptor copy];
				smallDesc.smallCapsFeature = YES;
				
				CTFontRef smallerFont = [smallDesc newMatchingFont];
				NSMutableDictionary *smallAttributes = [attributes mutableCopy];
				
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
				if (___useiOS6Attributes)
				{
					UIFont *font = [UIFont fontWithCTFont:smallerFont];
					
					[smallAttributes setObject:font forKey:NSFontAttributeName];
					CFRelease(smallerFont);
				}
				else
#endif
				{
					[smallAttributes setObject:CFBridgingRelease(smallerFont) forKey:(id)kCTFontAttributeName];
				}
				
				return [[NSAttributedString alloc] initWithString:_text attributes:smallAttributes];
			}
			else
			{
				return [NSAttributedString synthesizedSmallCapsAttributedStringWithText:_text attributes:attributes];
			}
		}
	}
}

#pragma mark - Properties

@synthesize text = _text;

@end
