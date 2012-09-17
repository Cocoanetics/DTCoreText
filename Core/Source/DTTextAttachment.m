//
//  DTTextAttachment.m
//  CoreTextExtensions
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTTextAttachment.h"
#import "DTCoreText.h"
#import "NSData+DTBase64.h"

@implementation DTTextAttachment
{
	CGSize _originalSize;
	CGSize _displaySize;
	DTTextAttachmentVerticalAlignment _verticalAlignment;
	id contents;
    NSDictionary *_attributes;
    
    DTTextAttachmentType contentType;
	
	NSURL *_contentURL;
	NSURL *_hyperLinkURL;
	
	CGFloat _fontLeading;
	CGFloat _fontAscent;
	CGFloat _fontDescent;
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
	DTImage *decodedImage = nil;
	
	
	// decode content URL
	if (src != nil) { // guard against img with no src
		if ([src hasPrefix:@"data:"])
		{
			NSRange range = [src rangeOfString:@"base64,"];
			
			if (range.length)
			{
				NSString *encodedData = [src substringFromIndex:range.location + range.length];
				NSData *decodedData = [NSData dataFromBase64String:encodedData];
				
				decodedImage = [[DTImage alloc] initWithData:decodedData];
				
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
				DTImage *image = [[DTImage alloc] initWithContentsOfFile:[contentURL path]];
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
			adjustedSize = sizeThatFitsKeepingAspectRatio2(displaySize, maxImageSize);
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
	if ((contents==nil) || contentType != DTTextAttachmentTypeImage)
	{
		return nil;
	}
	
	DTImage *image = (DTImage *)contents;
	NSData *data = [image dataForPNGRepresentation];
	NSString *encoded = [data base64EncodedString];
	
	return [@"data:image/png;base64," stringByAppendingString:encoded];
}

- (void)adjustVerticalAlignmentForFont:(CTFontRef)font
{
	_fontLeading = CTFontGetLeading(font);
	_fontAscent = CTFontGetAscent(font);
	_fontDescent = CTFontGetDescent(font);
}

- (CGFloat)ascentForLayout
{
	switch (_verticalAlignment) 
	{
		case DTTextAttachmentVerticalAlignmentBaseline:
		{
			return _displaySize.height;
		}
		case DTTextAttachmentVerticalAlignmentTop:
		{
			return _fontAscent;
		}	
		case DTTextAttachmentVerticalAlignmentCenter:
		{
			CGFloat halfHeight = (_fontAscent + _fontDescent) / 2.0f;
			
			return halfHeight - _fontDescent + _displaySize.height/2.0f;
		}
		case DTTextAttachmentVerticalAlignmentBottom:
		{
			return _displaySize.height - _fontDescent;
		}
	}
}

- (CGFloat)descentForLayout
{
	switch (_verticalAlignment) 
	{
		case DTTextAttachmentVerticalAlignmentBaseline:
		{
			return 0;
		}	
		case DTTextAttachmentVerticalAlignmentTop:
		{
			return _displaySize.height - _fontAscent;
		}	
		case DTTextAttachmentVerticalAlignmentCenter:
		{
			CGFloat halfHeight = (_fontAscent + _fontDescent) / 2.0f;
			
			return halfHeight - _fontAscent + _displaySize.height/2.0f;
		}	
		case DTTextAttachmentVerticalAlignmentBottom:
		{
			return _fontDescent;
		}
	}
}

#pragma mark Properties
/** Mutator for originalSize. Sets displaySize to the same value as originalSize. 
 @param The CGSize to store in originalSize. */
- (void)setOriginalSize:(CGSize)originalSize
{
	_originalSize = originalSize;
	self.displaySize = _originalSize;
}

/** 
 Accessor for the contents instance variable. If the content type is DTTextAttachmentTypeImage this returns a DTImage instance of the contents.
 @returns Contents. If it is an image, a DTImage instance is returned. Otherwise it is returned as is. 
 */
- (id)contents
{
	if (!contents)
	{
		if (contentType == DTTextAttachmentTypeImage && _contentURL && [_contentURL isFileURL])
		{
			DTImage *image = [[DTImage alloc] initWithContentsOfFile:[_contentURL path]];
			
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
@synthesize verticalAlignment = _verticalAlignment;
@synthesize hyperLinkGUID;

@end
