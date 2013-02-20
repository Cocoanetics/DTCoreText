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

#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_semaphore_t selfLock;  // GCD objects use ARC
#else
@property (nonatomic, assign) dispatch_semaphore_t selfLock;  // GCD objects don't use ARC
#endif

- (CTFramesetterRef)framesetter;
- (void)_discardFramesetter;

@end

#define SYNCHRONIZE_START(obj) dispatch_semaphore_wait(selfLock, DISPATCH_TIME_FOREVER);
#define SYNCHRONIZE_END(obj) dispatch_semaphore_signal(selfLock);

@implementation DTCoreTextLayouter
{
	CTFramesetterRef _framesetter;
	NSAttributedString *_attributedString;
	BOOL _shouldCacheLayoutFrames;
	NSCache *_layoutFrameCache;
}

@synthesize selfLock;

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
	if ((self = [super init]))
	{
		if (!attributedString)
		{
			return nil;
		}
		
		selfLock = dispatch_semaphore_create(1);
		self.attributedString = attributedString;
	}
	
	return self;
}

- (void)dealloc
{
	SYNCHRONIZE_START(self)	// just to be sure
	[self _discardFramesetter];
	SYNCHRONIZE_END(self)

#if !OS_OBJECT_USE_OBJC
	dispatch_release(selfLock);
#endif
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
		cacheKey = [NSString stringWithFormat:@"%ud-%@-%@", [_attributedString hash], NSStringFromCGRect(frame), NSStringFromRange(range)];
		
		DTCoreTextLayoutFrame *cachedLayoutFrame = [_layoutFrameCache objectForKey:cacheKey];
		
		if (cachedLayoutFrame)
		{
			return cachedLayoutFrame;
		}
	}

	@autoreleasepool {
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
	{
		// framesetter needs to go
		if (_framesetter)
		{
			CFRelease(_framesetter);
			_framesetter = NULL;
		}
	}
}

#pragma mark Properties
- (CTFramesetterRef)framesetter
{
	if (!_framesetter) // Race condition, could be null now but set when we get into the SYNCHRONIZE block - so do the test twice
	{
		SYNCHRONIZE_START(self)
		{
			if (!_framesetter)
			{
				_framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attributedString);
			}
		}
		SYNCHRONIZE_END(self)
	}
	return _framesetter;
}

- (void)setAttributedString:(NSAttributedString *)attributedString
{
	SYNCHRONIZE_START(self)
	{
		if (_attributedString != attributedString)
		{
			_attributedString = attributedString;
			
			[self _discardFramesetter];
			
			// clear the cache
			[_layoutFrameCache removeAllObjects];
		}
	}
	SYNCHRONIZE_END(self)
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
