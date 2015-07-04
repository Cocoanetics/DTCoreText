//
//  DTTextAttachment.m
//  DTCoreText
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTTextAttachment.h"
#import "DTCoreGraphicsUtils.h"
#import "DTHTMLElement.h"
#import "DTDictationPlaceholderTextAttachment.h"
#import "DTIframeTextAttachment.h"
#import "DTImageTextAttachment.h"
#import "DTObjectTextAttachment.h"
#import "DTVideoTextAttachment.h"
#import "NSCoder+DTCompatibility.h"

#import <DTFoundation/DTLog.h>


static NSMutableDictionary *_classForTagNameLookup = nil;

@interface DTTextAttachment ()

@end

@implementation DTTextAttachment
{
	NSURL *_hyperLinkURL;
	NSString *_hyperLinkGUID;
	
	CGFloat _fontLeading;
	CGFloat _fontAscent;
	CGFloat _fontDescent;
}

+ (void)initialize
{
	// this gets called from each subclass
	// prevent calling from children
	if (self != [DTTextAttachment class])
	{
		return;
	}
	
	_classForTagNameLookup = [[NSMutableDictionary alloc] init];
	
	// register standard tags
	[DTTextAttachment registerClass:[DTImageTextAttachment class] forTagName:@"img"];
	[DTTextAttachment registerClass:[DTVideoTextAttachment class] forTagName:@"video"];
	[DTTextAttachment registerClass:[DTIframeTextAttachment class] forTagName:@"iframe"];
	[DTTextAttachment registerClass:[DTObjectTextAttachment class] forTagName:@"object"];
}

+ (DTTextAttachment *)textAttachmentWithElement:(DTHTMLElement *)element options:(NSDictionary *)options
{
	Class class = [DTTextAttachment registeredClassForTagName:element.name];
	
	if (!class)
	{
		return nil;
	}

	DTTextAttachment *attachment = [class alloc];
	
	return [attachment initWithElement:element options:options];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super init];
	if (self) {
		_displaySize = [aDecoder decodeCGSizeForKey:@"displaySize"];
		_originalSize = [aDecoder decodeCGSizeForKey:@"originalSize"];
		_maxImageSize = [aDecoder decodeCGSizeForKey:@"maxImageSize"];
		_contentURL = [aDecoder decodeObjectForKey:@"contentURL"];
		_attributes = [aDecoder decodeObjectForKey:@"attributes"];
		_verticalAlignment = [aDecoder decodeIntegerForKey:@"verticalAlignment"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeCGSize:_displaySize forKey:@"displaySize"];
	[aCoder encodeCGSize:_originalSize forKey:@"originalSize"];
	[aCoder encodeCGSize:_maxImageSize forKey:@"maxImageSize"];
	[aCoder encodeObject:_contentURL forKey:@"contentURL"];
	[aCoder encodeObject:_attributes forKey:@"attributes"];
	[aCoder encodeInteger:_verticalAlignment forKey:@"verticalAlignment"];
}

- (id)initWithElement:(DTHTMLElement *)element options:(NSDictionary *)options
{
	self = [super init];
	
	if (self)
	{
		// width, height from tag
		_originalSize = element.size; // initially not known
		
		// determine if there is a display size restriction
		_maxImageSize = CGSizeZero;
		
		NSValue *maxImageSizeValue =[options objectForKey:DTMaxImageSize];
		if (maxImageSizeValue)
		{
#if TARGET_OS_IPHONE
			_maxImageSize = [maxImageSizeValue CGSizeValue];
#else
			_maxImageSize = [maxImageSizeValue sizeValue];
#endif
		}
		
		// set the display size from the original size, restricted to the max size
		[self setDisplaySize:_originalSize withMaxDisplaySize:_maxImageSize];

		_attributes = element.attributes;
	}
	
	return self;
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

#pragma mark - Subclass Customization

+ (void)registerClass:(Class)class forTagName:(NSString *)tagName
{
	Class previousClass = [DTTextAttachment registeredClassForTagName:tagName];

	if (previousClass)
	{
		DTLogDebug(@"Replacing previously registered class '%@' for tag name '%@' with '%@'", NSStringFromClass(previousClass), tagName, NSStringFromClass(class));
	}
	
	[_classForTagNameLookup setObject:class forKey:tagName];
}

+ (Class)registeredClassForTagName:(NSString *)tagName
{
	return [_classForTagNameLookup objectForKey:tagName];
}

#pragma mark Properties
/** Mutator for originalSize. Sets displaySize to the same value as originalSize. 
 @param originalSize The CGSize to store in originalSize. */
- (void)setOriginalSize:(CGSize)originalSize
{
	if (!CGSizeEqualToSize(originalSize, _originalSize))
	{
		_originalSize = originalSize;
		
		if (_displaySize.width==0 || _displaySize.height==0)
		{
			[self setDisplaySize:_originalSize withMaxDisplaySize:_maxImageSize];
		}
	}
}

- (void)setDisplaySize:(CGSize)displaySize withMaxDisplaySize:(CGSize)maxDisplaySize
{
	if (_originalSize.width!=0 && _originalSize.height!=0)
	{
		// width and/or height missing
		if (displaySize.width==0 && displaySize.height==0)
		{
			displaySize = _originalSize;
		}
		else if (displaySize.width==0 && displaySize.height!=0)
		{
			// width missing, calculate it
			CGFloat factor = _originalSize.height / displaySize.height;
			displaySize.width = round(_originalSize.width / factor);
		}
		else if (displaySize.width!=0 && displaySize.height==0)
		{
			// height missing, calculate it
			CGFloat factor = _originalSize.width / displaySize.width;
			displaySize.height = round(_originalSize.height / factor);
		}
	}

	if (maxDisplaySize.width>0 && maxDisplaySize.height>0)
	{
		if (maxDisplaySize.width < displaySize.width || maxDisplaySize.height < displaySize.height)
		{
			displaySize = DTCGSizeThatFitsKeepingAspectRatio(displaySize, maxDisplaySize);
		}
	}
	
	_displaySize = displaySize;
}

- (void)setDisplaySize:(CGSize)displaySize
{
	_displaySize = displaySize;
}

@synthesize originalSize = _originalSize;
@synthesize displaySize = _displaySize;
@synthesize contentURL = _contentURL;
@synthesize hyperLinkURL = _hyperLinkURL;
@synthesize attributes = _attributes;
@synthesize verticalAlignment = _verticalAlignment;
@synthesize hyperLinkGUID = hyperLinkGUID;

@end
