//
//  DTCoreTextLayouter.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextLayouter.h"

@interface DTCoreTextLayouter ()

@property (nonatomic, strong) NSMutableArray *frames;

- (void)_discardFramesetter;

@end


@implementation DTCoreTextLayouter
{
	CTFramesetterRef _framesetter;
	NSAttributedString *_attributedString;
	BOOL _shouldCacheLayoutFrames;
	NSCache *_layoutFrameCache;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
	if ((self = [super init]))
	{
		if (!attributedString)
		{
			return nil;
		}
		
		self.attributedString = attributedString;
	}
	
	return self;
}

- (void)dealloc
{
	[self _discardFramesetter];
}

- (DTCoreTextLayoutFrame *)layoutFrameWithRect:(CGRect)frame range:(NSRange)range
{
	DTCoreTextLayoutFrame *newFrame = nil;
	NSString *cacheKey = nil;
	
	// need to have a non zero
	if (!(frame.size.width > 0 && frame.size.height > 0))
	{
		return nil;
	}
	
	if (_shouldCacheLayoutFrames)
	{
		cacheKey = [NSString stringWithFormat:@"%lud-%@-%@", (unsigned long)[_attributedString hash], NSStringFromCGRect(frame), NSStringFromRange(range)];
		
		DTCoreTextLayoutFrame *cachedLayoutFrame = [_layoutFrameCache objectForKey:cacheKey];
		
		if (cachedLayoutFrame)
		{
			return cachedLayoutFrame;
		}
	}

	@autoreleasepool
	{
		newFrame = [[DTCoreTextLayoutFrame alloc] initWithFrame:frame layouter:self range:range];
	};
	
	if (newFrame && _shouldCacheLayoutFrames)
	{
		[_layoutFrameCache setObject:newFrame forKey:cacheKey];
	}
	
	return newFrame;
}

- (void)_discardFramesetter
{
	// framesetter needs to go
	if (_framesetter)
	{
		CFRelease(_framesetter);
		_framesetter = NULL;
	}
}

#pragma mark Properties

- (CTFramesetterRef)framesetter
{
	@synchronized(self)
	{
		if (!_framesetter)
		{
			_framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attributedString);
		}
		
		
		return _framesetter;
	}
}

- (void)setAttributedString:(NSAttributedString *)attributedString
{
	@synchronized(self)
	{
		if (_attributedString != attributedString)
		{
			_attributedString = attributedString;
			
			[self _discardFramesetter];
			
			// clear the cache
			[_layoutFrameCache removeAllObjects];
		}
	}
}

- (NSAttributedString *)attributedString
{
	return _attributedString;
}

- (void)setShouldCacheLayoutFrames:(BOOL)shouldCacheLayoutFrames
{
	if (_shouldCacheLayoutFrames != shouldCacheLayoutFrames)
	{
		_shouldCacheLayoutFrames = shouldCacheLayoutFrames;
		
		if (shouldCacheLayoutFrames)
		{
			_layoutFrameCache = [[NSCache alloc] init];
		}
		else
		{
			_layoutFrameCache = nil;
		}
	}
}

@synthesize attributedString = _attributedString;
@synthesize framesetter = _framesetter;
@synthesize shouldCacheLayoutFrames = _shouldCacheLayoutFrames;

@end
