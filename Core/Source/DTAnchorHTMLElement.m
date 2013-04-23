//
//  DTHTMLElementA.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.03.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTAnchorHTMLElement.h"
#import "DTColor+HTML.h"

@implementation DTAnchorHTMLElement
{
	DTColor *_highlightedTextColor;
}

- (void)applyStyleDictionary:(NSDictionary *)styles
{
	[super applyStyleDictionary:styles];
	
	// get highlight color from a:active pseudo-selector
	NSString *activeColor = [styles objectForKey:@"active:color"];
	
	if (activeColor)
	{
		self.highlightedTextColor = [DTColor colorWithHTMLName:activeColor];
	}
}

- (NSAttributedString *)attributedString
{
	// super returns a mutable attributed string
	NSMutableAttributedString *mutableAttributedString = (NSMutableAttributedString *)[super attributedString];
	
	if (_highlightedTextColor)
	{
		NSRange range = NSMakeRange(0, [mutableAttributedString length]);
	
		// this additional attribute keeps the highlight color
		[mutableAttributedString addAttribute:DTLinkHighlightColorAttribute value:(id)_highlightedTextColor range:range];
		
		// we need to set the text color via the graphics context
		[mutableAttributedString addAttribute:(id)kCTForegroundColorFromContextAttributeName value:[NSNumber numberWithBool:YES] range:range];
	}
	
	return mutableAttributedString;
}

#pragma mark - Properties

@synthesize highlightedTextColor = _highlightedTextColor;

@end
