//
//  DTHTMLElementAttachment.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 26.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTTextAttachmentHTMLElement.h"

#import "DTHTMLElement.h"
#import "DTTextAttachment.h"
#import "DTCoreTextParagraphStyle.h"
#import "NSMutableAttributedString+HTML.h"

@implementation DTTextAttachmentHTMLElement
{
	CGSize _maxDisplaySize;
}

- (id)initWithName:(NSString *)name attributes:(NSDictionary *)attributes options:(NSDictionary *)options
{
	self = [super initWithName:name attributes:attributes];
	
	if (self)
	{
		// make appropriate attachment
		DTTextAttachment *attachment = [DTTextAttachment textAttachmentWithElement:self options:options];
		
		// add it to tag
		_textAttachment = attachment;
		
		// to avoid much too much space before the image
		if (nil == _paragraphStyle)
			_paragraphStyle = [[DTCoreTextParagraphStyle alloc] init];

		_paragraphStyle.lineHeightMultiple = 1;
		
		// specifying line height interferes with correct positioning
		_paragraphStyle.minimumLineHeight = 0;
		_paragraphStyle.maximumLineHeight = 0;
		
		// remember the maximum display size
		_maxDisplaySize = CGSizeZero;
		
		NSValue *maxImageSizeValue =[options objectForKey:DTMaxImageSize];
		if (maxImageSizeValue)
		{
#if TARGET_OS_IPHONE
			_maxDisplaySize = [maxImageSizeValue CGSizeValue];
#else
			_maxDisplaySize = [maxImageSizeValue sizeValue];
#endif
		}
	}
	
	return self;
}

- (NSAttributedString *)attributedString
{
	@synchronized(self)
	{
		NSDictionary *attributes = [self attributesForAttributedStringRepresentation];
		
		// ignore text, use unicode object placeholder
		NSMutableAttributedString *tmpString = [[NSMutableAttributedString alloc] initWithString:UNICODE_OBJECT_PLACEHOLDER attributes:attributes];
		
		// block-level elements get space trimmed and a newline
		if (self.displayStyle != DTHTMLElementDisplayStyleInline)
		{
			[tmpString appendString:@"\n"];
		}
		
		return tmpString;
	}
}

// workaround, because we don't support float yet. float causes the image to be its own block
- (DTHTMLElementDisplayStyle)displayStyle
{
	if ([super floatStyle]==DTHTMLElementFloatStyleNone)
	{
		return [super displayStyle];
	}
	
	return DTHTMLElementDisplayStyleBlock;
}

- (void)applyStyleDictionary:(NSDictionary *)styles
{
	// element size is determined in super (tag attribute and style)
	[super applyStyleDictionary:styles];
	
	// at this point we have the size from width/height attribute or style in _size
	
	// set original size if it was previously unknown
	if (CGSizeEqualToSize(CGSizeZero, _textAttachment.originalSize))
	{
		_textAttachment.originalSize = _size;
	}
	
	NSString *widthString = [styles objectForKey:@"width"];
	NSString *heightString = [styles objectForKey:@"height"];

	if (widthString.length > 1 && [widthString hasSuffix:@"%"])
	{
		CGFloat scale = (CGFloat)([[widthString substringToIndex:widthString.length - 1] floatValue] / 100.0);
		
		_size.width = _maxDisplaySize.width * scale;
	}
	
	if (heightString.length > 1 && [heightString hasSuffix:@"%"])
	{
		CGFloat scale = (CGFloat)([[heightString substringToIndex:heightString.length - 1] floatValue] / 100.0);
		
		_size.height = _maxDisplaySize.height * scale;
	}
	// update the display size
	[_textAttachment setDisplaySize:_size withMaxDisplaySize:_maxDisplaySize];
}

@end
