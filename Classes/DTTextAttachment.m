//
//  DTTextAttachment.m
//  CoreTextExtensions
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTTextAttachment.h"


@implementation DTTextAttachment

- (void) dealloc
{
	[contents release];
	[_contentURL release];
	[_hyperLinkURL release];
	[_attributes release];
	
	[super dealloc];
}


#pragma mark Properties

- (void)setOriginalSize:(CGSize)originalSize
{
	_originalSize = originalSize;
	self.displaySize = _originalSize;
}

- (id)contents
{
	if (!contents)
	{
		if (contentType == DTTextAttachmentTypeImage && _contentURL && [_contentURL isFileURL])
		{
			UIImage *image = [UIImage imageWithContentsOfFile:[_contentURL path]];
			
			return image;
		}
	}
	
	return contents;
}

@synthesize originalSize = _originalSize;
@synthesize displaySize = _displaySize;
@synthesize contents;
@synthesize contentType;
@synthesize contentURL = _contentURL;
@synthesize hyperLinkURL = _hyperLinkURL;
@synthesize attributes = _attributes;

@end
