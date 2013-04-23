//
//  DTHTMLElementStylesheet.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 29.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTStylesheetHTMLElement.h"
#import "DTCSSStylesheet.h"

@implementation DTStylesheetHTMLElement

- (NSAttributedString *)attributedString
{
	return nil;
}

- (DTCSSStylesheet *)stylesheet
{
	NSString *text = [self text];
	
	return [[DTCSSStylesheet alloc] initWithStyleBlock:text];
}

@end
