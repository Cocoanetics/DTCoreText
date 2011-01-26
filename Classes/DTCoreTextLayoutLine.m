//
//  DTCoreTextLine.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextLayoutLine.h"
#import "DTCoreTextGlyphRun.h"

@interface DTCoreTextLayoutLine ()

@property (nonatomic, retain) NSArray *glyphRuns;

@end



@implementation DTCoreTextLayoutLine

- (id)initWithLine:(CTLineRef)line layoutFrame:(DTCoreTextLayoutFrame *)layoutFrame origin:(CGPoint)origin;
{
	if (self = [super init])
	{
		_layoutFrame = layoutFrame;
		
		_line = line;
		CFRetain(line);
		
		_baselineOrigin = origin;
		
		
		width = CTLineGetTypographicBounds(_line, &ascent, &descent, &leading);
		//CGRect lineImageBounds = CTLineGetImageBounds((CTLineRef)oneLine, context);
		
		trailingWhitespaceWidth = CTLineGetTrailingWhitespaceWidth(_line);

		_frame = CGRectMake(_baselineOrigin.x, _baselineOrigin.y - ascent, width, ascent + descent);
	}
	
	return self;
}

- (void)dealloc
{
	if (_line)
	{
		CFRelease(_line);
	}
	[_glyphRuns release];
	
	[super dealloc];
}

- (NSString *)description
{
	return [self.glyphRuns description];
}

//- (NSString *)description
//{
//	NSRange range = [self stringRange];
//	return [NSString stringWithFormat:@"<%@ loc=%d len=%d %@>", [self class], range.location, range.length, NSStringFromCGRect(_frame)];
//}

- (NSRange)stringRange
{
	CFRange range = CTLineGetStringRange(_line);
	
	return NSMakeRange(range.location, range.length);
}



- (CGRect)frame
{
	return _frame;
}

- (NSInteger)numberOfGlyphs
{
	NSInteger ret = 0;
	for (DTCoreTextGlyphRun *oneRun in self.glyphRuns)
	{
		ret += [oneRun numberOfGlyphs];
	}
	
	return ret;
}


#pragma mark Calculations
- (CGRect)frameOfGlyphAtIndex:(NSInteger)index
{
	for (DTCoreTextGlyphRun *oneRun in self.glyphRuns)
	{
		NSInteger count = [oneRun numberOfGlyphs];
		if (index >= count)
		{
			index -= count;
		}
		else 
		{
			return [oneRun frameOfGlyphAtIndex:index];
		}
	}
	
	return CGRectZero;
}

// bounds of an image encompassing the entire run
- (CGRect)imageBoundsInContext:(CGContextRef)context
{
	return CTLineGetImageBounds(_line, context);
}

#pragma mark Properties
- (NSArray *)glyphRuns
{
	if (!_glyphRuns)
	{
		CFArrayRef runs = CTLineGetGlyphRuns(_line);

		CGFloat offset = 0;
		
		NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:CFArrayGetCount(runs)];
		
		for (id oneRun in (NSArray *)runs)
		{
			CGPoint runOrigin = CGPointMake(_baselineOrigin.x + offset, _baselineOrigin.y);
			
			DTCoreTextGlyphRun *glyphRun = [[DTCoreTextGlyphRun alloc] initWithRun:(CTRunRef)oneRun layoutLine:self origin:runOrigin];
			[tmpArray addObject:glyphRun];
			[glyphRun release];
			
			offset += glyphRun.frame.size.width;
		}
		
		self.glyphRuns = [NSArray arrayWithArray:tmpArray];
	}
	
	return _glyphRuns;
}
	
	


@synthesize frame =_frame;
@synthesize glyphRuns = _glyphRuns;

@synthesize ascent;
@synthesize descent;
@synthesize leading;

@synthesize baselineOrigin = _baselineOrigin;

@end
