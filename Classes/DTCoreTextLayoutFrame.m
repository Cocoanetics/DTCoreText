//
//  DTCoreTextLayoutFrame.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextLayoutFrame.h"
#import "DTCoreTextLayouter.h"
#import "DTCoreTextLayoutLine.h"

@interface DTCoreTextLayoutFrame ()

@property (nonatomic, retain) NSArray *lines;

@end



@implementation DTCoreTextLayoutFrame

- (id)initWithFrame:(CGRect)frame layouter:(DTCoreTextLayouter *)layouter
{
	if (self = [super init])
	{
		_frame = frame;
		
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathAddRect(path, NULL, frame);
		_textFrame = CTFramesetterCreateFrame(layouter.framesetter, CFRangeMake(0, 0), path, NULL);
		CGPathRelease(path);
		
		_layouter = layouter;
	}
	
	return self;
}

- (void)dealloc
{
	if (_textFrame)
	{
		CFRelease(_textFrame);
	}
	[super dealloc];
}

- (NSString *)description
{
	return [self.lines description];
}

- (NSArray *)lines
{
	if (!_lines)
	{
		// get lines
		CFArrayRef lines = CTFrameGetLines(_textFrame);
		
		if (!lines)
		{
			// probably no string set
			return nil;
		}
		
		CGPoint *origins = malloc(sizeof(CGPoint)*[(NSArray *)lines count]);
		CTFrameGetLineOrigins(_textFrame, CFRangeMake(0, 0), origins);
		
		NSMutableArray *tmpLines = [NSMutableArray arrayWithCapacity:CFArrayGetCount(lines)];;
		
		NSInteger lineIndex = 0;
		
		for (id oneLine in (NSArray *)lines)
		{
			CGPoint lineOrigin = origins[lineIndex];
			lineOrigin.y = _frame.size.height - lineOrigin.y + self.frame.origin.y;
			lineOrigin.x += self.frame.origin.x;

			DTCoreTextLayoutLine *newLine = [[DTCoreTextLayoutLine alloc] initWithLine:(CTLineRef)oneLine layoutFrame:self origin:lineOrigin];
			[tmpLines addObject:newLine];
			[newLine release];
			
			lineIndex++;
		}
		
		self.lines = [NSArray arrayWithArray:tmpLines];
		
		free(origins);
	}
	
	return _lines;
}

- (CGPathRef)path
{
	return CTFrameGetPath(_textFrame);
}

- (void)drawInContext:(CGContextRef)context
{
	if (!_textFrame || !context)
	{
		return;
	}
	
	CTFrameDraw(_textFrame, context);
}

- (NSRange)visibleStringRange
{
	CFRange range = CTFrameGetVisibleStringRange(_textFrame);
	
	return NSMakeRange(range.location, range.length);
}


#pragma mark Calculations
- (NSInteger)lineIndexForGlyphIndex:(NSInteger)index
{
	NSInteger retIndex = 0;
	for (DTCoreTextLayoutLine *oneLine in self.lines)
	{
		NSInteger count = [oneLine numberOfGlyphs];
		if (index >= count)
		{
			index -= count;
		}
		else 
		{
			return retIndex;
		}
		
		retIndex++;
	}
	
	return NSIntegerMax;
}

- (CGRect)frameOfGlyphAtIndex:(NSInteger)index
{
	for (DTCoreTextLayoutLine *oneLine in self.lines)
	{
		NSInteger count = [oneLine numberOfGlyphs];
		if (index >= count)
		{
			index -= count;
		}
		else 
		{
			return [oneLine frameOfGlyphAtIndex:index];
		}
	}
	
	return CGRectZero;
}

#pragma mark Properties
@synthesize frame = _frame;
@synthesize layouter = _layouter;
@synthesize lines = _lines;

@end
