//
//  DTTextAttachment.m
//  CoreTextExtensions
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTTextAttachment.h"
#import "DTHTMLElement.h"
#import "CGUtils.h"
#import "NSAttributedString+HTML.h"
#import "NSData+Base64.h"

@implementation DTTextAttachment
{
	CGSize _originalSize;
	CGSize _displaySize;
	id contents;
    NSDictionary *_attributes;
    
    DTTextAttachmentType contentType;
	
	NSURL *_contentURL;
	NSURL *_hyperLinkURL;
}

+ (DTTextAttachment *)textAttachmentWithElement:(DTHTMLElement *)element options:(NSDictionary *)options
{
	// determine type
	DTTextAttachmentType attachmentType;
	
	if ([element.tagName isEqualToString:@"img"])
	{
		attachmentType = DTTextAttachmentTypeImage;
	}
	else if ([element.tagName isEqualToString:@"video"])
	{
		attachmentType = DTTextAttachmentTypeVideoURL;
	}
	else if ([element.tagName isEqualToString:@"iframe"])
	{
		attachmentType = DTTextAttachmentTypeIframe;
	}
	else if ([element.tagName isEqualToString:@"object"])
	{
		attachmentType = DTTextAttachmentTypeObject;
	}
	else
	{
		return nil;
	}
	
	// determine if there is a display size restriction
	CGSize maxImageSize = CGSizeZero;
	
	NSValue *maxImageSizeValue =[options objectForKey:DTMaxImageSize];
	if (maxImageSizeValue)
	{
		maxImageSize = [maxImageSizeValue CGSizeValue];
	}
	
	// width, height from tag
	CGSize displaySize = element.size; // width/height from attributes or CSS style
	CGSize originalSize = element.size;
	
	// get base URL
	NSURL *baseURL = [options objectForKey:NSBaseURLDocumentOption];
	
	// decode URL
	NSString *src = [element attributeForKey:@"src"];
	
	NSURL *contentURL = nil;
	UIImage *decodedImage = nil;
	
	
	// decode content URL
	if ([src hasPrefix:@"data:"])
	{
		NSRange range = [src rangeOfString:@"base64,"];
		
		if (range.length)
		{
			NSString *encodedData = [src substringFromIndex:range.location + range.length];
			NSData *decodedData = [NSData dataFromBase64String:encodedData];
			
			decodedImage = [UIImage imageWithData:decodedData];
			
			if (!displaySize.width || !displaySize.height)
			{
				displaySize = decodedImage.size;
			}
		}
	}
	else // normal URL
	{
		contentURL = [NSURL URLWithString:src];
		
		if (![contentURL scheme])
		{
			// possibly a relative url
			if (baseURL)
			{
				contentURL = [NSURL URLWithString:src relativeToURL:baseURL];
			}
			else
			{
				// file in app bundle
				NSString *path = [[NSBundle mainBundle] pathForResource:src ofType:nil];
				if (path) {
					// Prevent a crash if path turns up nil.
					contentURL = [NSURL fileURLWithPath:path];   
				}
			}
		}
	}
	
	DTTextAttachment *attachment = [[DTTextAttachment alloc] init];
	
	// for local images we can get their size by inspecting them
	if (attachmentType == DTTextAttachmentTypeImage)
	{
		// if it's a local file we need to inspect it to get it's dimensions
		if (!displaySize.width || !displaySize.height)
		{
			// inspect local file
			if ([contentURL isFileURL])
			{
				UIImage *image = [UIImage imageWithContentsOfFile:[contentURL path]];
				originalSize = image.size;
				
				if (!displaySize.width || !displaySize.height)
				{
					displaySize = originalSize;
				}
			}
			else
			{
				// remote image, we have to relayout once this size is known
				displaySize = CGSizeMake(1, 1); // one pixel so that loading is triggered
			}
		}
		
		// we copy the link because we might need for it making the custom view
		if (element.link)
		{
			attachment.hyperLinkURL = element.link;
		}
	}

	
	// if you have no display size we assume original size
	if (CGSizeEqualToSize(displaySize, CGSizeZero))
	{
		displaySize = originalSize;
	}
	
	// adjust the display size if there is a restriction and it's too large
	CGSize adjustedSize = displaySize;
	
	if (maxImageSize.width>0 && maxImageSize.height>0)
	{
		if (maxImageSize.width < displaySize.width || maxImageSize.height < displaySize.height)
		{
			adjustedSize = sizeThatFitsKeepingAspectRatio(displaySize, maxImageSize);
		}
		
		// still no display size? use max size
		if (CGSizeEqualToSize(displaySize, CGSizeZero))
		{
			adjustedSize = maxImageSize;
		}
	}
		
	attachment.contentType = attachmentType;
	attachment.contentURL = contentURL;
	attachment.contents = decodedImage;
	attachment.originalSize = originalSize;
	attachment.displaySize = adjustedSize;
	attachment.attributes = element.attributes;
	
	return attachment;
}


// makes a data URL of the image
- (NSString *)dataURLRepresentation
{
	if (!contents || contentType != DTTextAttachmentTypeImage)
	{
		return nil;
	}
	
	NSData *data = UIImagePNGRepresentation(contents);
	NSString *encoded = [data base64EncodedString];
	
	return [@"data:image/png;base64," stringByAppendingString:encoded];
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
