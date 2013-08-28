//
//  DTTextAttachment.m
//  DTCoreText
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTTextAttachment.h"
#import "DTCoreText.h"
#import "DTUtils.h"

#import "DTBase64Coding.h"
#import "DTDictationPlaceholderTextAttachment.h"
#import "DTIframeTextAttachment.h"
#import "DTImageTextAttachment.h"
#import "DTObjectTextAttachment.h"
#import "DTVideoTextAttachment.h"

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
	[DTTextAttachment registerClass:[DTImageTextAttachment class] forTagName:@"img" withClassName:nil];
	[DTTextAttachment registerClass:[DTVideoTextAttachment class] forTagName:@"video" withClassName:nil];
	[DTTextAttachment registerClass:[DTIframeTextAttachment class] forTagName:@"iframe" withClassName:nil];
	[DTTextAttachment registerClass:[DTObjectTextAttachment class] forTagName:@"object" withClassName:nil];
}

+ (DTTextAttachment *)textAttachmentWithElement:(DTHTMLElement *)element options:(NSDictionary *)options
{
	[DTTextAttachment textAttachmentWithElement:element andClassName:nil options:options];
}

+ (DTTextAttachment *)textAttachmentWithElement:(DTHTMLElement *)element andClassName:(NSString *)className options:(NSDictionary *)options
{
    Class class = [DTTextAttachment registeredClassForTagName:element.name withClassName:className];
	
	if (!class)
	{
		return nil;
	}
    
	DTTextAttachment *attachment = [class alloc];
	
	return [attachment initWithElement:element options:options];
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
	[DTTextAttachment registerClass:class forTagName:tagName withClassName:nil];
}

+ (void)registerClass:(Class)class forTagName:(NSString *)tagName withClassName:(NSString *)className
{
	if (className == nil)
		className = @"";
	if (tagName == nil)
		tagName = @"";

	Class previousClass = [DTTextAttachment registeredClassForTagName:tagName withClassName:className];

	if (previousClass) {
		NSLog(@"Warning: replacing previously registered class '%@' for tag name '%@' and DOM class '%@' with '%@'", NSStringFromClass(previousClass), tagName, className, NSStringFromClass(class));
	}

	NSMutableDictionary *tagDict = [_classForTagNameLookup objectForKey:tagName];
	if (!tagDict) {
		tagDict = [NSMutableDictionary dictionaryWithObject:class forKey:className];
	} else {
		[tagDict setObject:class forKey:className];
	}

	[_classForTagNameLookup setObject:tagDict forKey:tagName];
}

+ (Class)registeredClassForTagName:(NSString *)tagName
{
	return [DTTextAttachment registeredClassForTagName:tagName withClassName:nil];
}

+ (Class)registeredClassForTagName:(NSString *)tagName withClassName:(NSString *)className
{
	if (className == nil)
		className = @"";
	if (tagName == nil)
		tagName = @"";

	NSMutableDictionary *tagDict = [_classForTagNameLookup objectForKey:tagName];

    if (tagDict) {
        Class obj = [tagDict objectForKey:className];
        
        if ([className isEqualToString:@""] && !obj) {
            return nil;
        }
        
        if (!obj) {
            obj = [DTTextAttachment registeredClassForTagName:nil withClassName:className];
            if (!obj) {
                obj = [DTTextAttachment registeredClassForTagName:tagName withClassName:nil];
                if (!obj) return nil;
            }
        }
        
        return obj;
    } else {
        return nil;
    }
}

#pragma mark Properties
/** Mutator for originalSize. Sets displaySize to the same value as originalSize. 
 @param The CGSize to store in originalSize. */
- (void)setOriginalSize:(CGSize)originalSize
{
	if (!CGSizeEqualToSize(originalSize, _originalSize))
	{
		_originalSize = originalSize;
		
		if (!_displaySize.width || !_displaySize.height)
		{
			[self setDisplaySize:_originalSize withMaxDisplaySize:_maxImageSize];
		}
	}
}

- (void)setDisplaySize:(CGSize)displaySize withMaxDisplaySize:(CGSize)maxDisplaySize
{
	if (_originalSize.width && _originalSize.height)
	{
		// width and/or height missing
		if (displaySize.width==0 && displaySize.height==0)
		{
			displaySize = _originalSize;
		}
		else if (!displaySize.width && displaySize.height)
		{
			// width missing, calculate it
			CGFloat factor = _originalSize.height / displaySize.height;
			displaySize.width = roundf(_originalSize.width / factor);
		}
		else if (displaySize.width>0 && displaySize.height==0)
		{
			// height missing, calculate it
			CGFloat factor = _originalSize.width / displaySize.width;
			displaySize.height = roundf(_originalSize.height / factor);
		}
	}

	if (maxDisplaySize.width>0 && maxDisplaySize.height>0)
	{
		if (maxDisplaySize.width < displaySize.width || maxDisplaySize.height < displaySize.height)
		{
			displaySize = sizeThatFitsKeepingAspectRatio(displaySize, maxDisplaySize);
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
