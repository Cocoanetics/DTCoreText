//
//  DTHTMLElementA.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.03.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTHTMLElementA.h"

@implementation DTHTMLElementA
{
	DTColor *_highlightedTextColor;
}

- (void)applyStyleDictionary:(NSDictionary *)styles
{
	[super applyStyleDictionary:styles];
	
	// TODO: get the highlighted color from CSS
	self.highlightedTextColor = [DTColor redColor];
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
