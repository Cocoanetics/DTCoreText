//
//  DTTextAttachmentVideo.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 22.04.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"

@implementation DTTextAttachmentVideo

- (id)initWithElement:(DTHTMLElement *)element options:(NSDictionary *)options
{
	self = [super initWithElement:element options:options];
	
	if (self)
	{
		// get base URL
		NSURL *baseURL = [options objectForKey:NSBaseURLDocumentOption];
		NSString *src = [element.attributes objectForKey:@"src"];
		
		// content URL
		_contentURL = [NSURL URLWithString:src relativeToURL:baseURL];
	}
	
	return self;
}

@end
