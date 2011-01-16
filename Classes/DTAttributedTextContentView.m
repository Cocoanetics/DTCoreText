//
//  TextView.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextContentView.h"
#import "DTAttributedTextView.h"

#import "DTTextAttachment.h"
#import "NSAttributedString+HTML.h"
#import "NSString+HTML.h"
#import "UIColor+HTML.h"
#import <QuartzCore/QuartzCore.h>

#define DRAW_DEBUG_FRAMES 0

#define TAG_BASE 9999

@interface DTAttributedTextContentView ()

@property (nonatomic) CTFramesetterRef framesetter;
@property (nonatomic) CTFrameRef textFrame;

@end

@implementation DTAttributedTextContentView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.contentMode = UIViewContentModeRedraw;
		self.backgroundColor = [UIColor whiteColor];
		self.userInteractionEnabled = YES;
		
		edgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    }
    return self;
}

/*
 // Example: Using CATextLayer. But it ignores paragraph spacing!
 
 + (Class)layerClass
 {
 return [CATextLayer class];
 }
 
 - (void)awakeFromNib
 {
 NSString *readmePath = [[NSBundle mainBundle] pathForResource:@"README" ofType:@"html"];
 NSString *html = [NSString stringWithContentsOfFile:readmePath encoding:NSUTF8StringEncoding error:NULL];
 NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
 
 NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:NULL];
 
 CATextLayer *textLayer = (CATextLayer *)self.layer;
 
 textLayer.frame = CGRectInset(self.bounds, 10, 10);
 textLayer.string = string;
 textLayer.wrapped = YES;
 }
 
 */


- (void)drawRect:(CGRect)rect 
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Flip the coordinate system
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
#if DRAW_DEBUG_FRAMES
	CGFloat dashes[] = {1.0, 3.0};
	CGContextSetLineDash(context, 0, dashes, 2);
	CGContextStrokeRect(context, UIEdgeInsetsInsetRect(self.bounds, edgeInsets));
#endif
	
	
	// get lines
	CFArrayRef lines = CTFrameGetLines(self.textFrame);
	CGPoint *origins = malloc(sizeof(CGPoint)*[(NSArray *)lines count]);
	CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);
	NSInteger lineIndex = 0;
	
	CGContextSetTextPosition(context, 0, 0);
	
	for (id oneLine in (NSArray *)lines)
	{
		CGPoint lineOrigin = origins[lineIndex];
		lineOrigin.x += edgeInsets.left; // add inset 
		lineOrigin.y += edgeInsets.top; // add inset
		
		CFArrayRef runs = CTLineGetGlyphRuns((CTLineRef)oneLine);
		CGFloat lineAscent;
		CGFloat lineDescent;
		CGFloat lineLeading;
		CGFloat lineWidth = CTLineGetTypographicBounds((CTLineRef)oneLine, &lineAscent, &lineDescent, &lineLeading);
		CGRect lineBounds = CTLineGetImageBounds((CTLineRef)oneLine, context);
		
		lineBounds.origin.x += lineOrigin.x;
		lineBounds.origin.y += lineOrigin.y;
		lineBounds.size.height = lineAscent + lineDescent + 1;
		lineBounds.size.width = lineWidth;
		
#if DRAW_DEBUG_FRAMES
		[[UIColor blueColor] set];
		CGContextFillRect(context, CGRectMake(lineOrigin.x, lineOrigin.y, -5, 1));
		
		CGContextSetRGBFillColor(context, 0, 1, 0, 0.1);
		CGContextFillRect(context, lineBounds);
		
		int runIndex = 0;
#endif		
		
		lineIndex++;
		CGFloat offset = edgeInsets.left;
		
		for (id oneRun in (NSArray *)runs)
		{
			CGFloat runAscent = 0;
			CGFloat runDescent = 0;
			CGFloat runLeading = 0;
			
			CGFloat runWidth = CTRunGetTypographicBounds((CTRunRef) oneRun,
														 CFRangeMake(0, 0),
														 &runAscent,
														 &runDescent, &runLeading);
			
			CGRect runImageBounds = CTRunGetImageBounds((CTRunRef)oneRun, 
														context, CFRangeMake(0, 0));
			
			CGRect runBounds;
			runBounds.origin.x = offset;
			runBounds.origin.y = lineBounds.origin.y;
			runBounds.size.width = runWidth;
			runBounds.size.height = runAscent + runDescent + 1;
			
			NSDictionary *attributes = (NSDictionary *)CTRunGetAttributes((CTRunRef) oneRun);
			DTTextAttachment *attachment = [attributes objectForKey:@"DTTextAttachment"];
			
			if (attachment)
			{
				if ([attachment.contents isKindOfClass:[UIImage class]])
				{
					UIImage *image = (id)attachment.contents;
					
					CGRect imageBounds = CGRectMake(floorf(runBounds.origin.x), floorf(lineOrigin.y), 
													attachment.size.width, attachment.size.height);
					CGContextDrawImage(context, imageBounds, image.CGImage); 
				}
			}
			
			
			// image bounds is 0 wide on trailing newline, don't want to stroke that.
			if (runImageBounds.size.width>0)
			{
				if ([[attributes objectForKey:@"_StrikeOut"] boolValue])
				{
					CGRect runStrokeBounds = runBounds;
					
					runStrokeBounds.origin.y += roundf(runBounds.size.height/2.0);
					
					// get text color or use black
					id color = [attributes objectForKey:(id)kCTForegroundColorAttributeName];
					
					if (color)
					{
						CGContextSetStrokeColorWithColor(context, (CGColorRef)color);
					}
					else
					{
						CGContextSetGrayStrokeColor(context, 0, 1.0);
					}
					
					CGContextSetLineDash(context, 0, NULL, 0);
					CGContextSetLineWidth(context, 1);
					
					//CGFloat y = roundf(runStrokeBounds.origin.y + (runStrokeBounds.size.height+ runDescent)/2.0  );
					CGContextMoveToPoint(context, runStrokeBounds.origin.x, runStrokeBounds.origin.y);
					CGContextAddLineToPoint(context, runStrokeBounds.origin.x + runStrokeBounds.size.width, runStrokeBounds.origin.y);
					
					CGContextStrokePath(context);
				}
				
				
#if DRAW_DEBUG_FRAMES			
				if (runIndex%2)
				{
					CGContextSetRGBFillColor(context, 1, 0, 0, 0.2);
				}
				else 
				{
					CGContextSetRGBFillColor(context, 0, 1, 0, 0.2);
				}
				
				CGContextFillRect(context, runBounds);
				runIndex ++;
#endif
			}	
			
			//FIXME: Is there a better place to get the views? Problem: need context for coordinate calcs
			
			// add custom views if necessary
			if ([parentView.textDelegate respondsToSelector:@selector(attributedTextView:viewForAttributedString:frame:)])
			{
				CFRange range = CTRunGetStringRange((CTRunRef)oneRun);
				NSRange stringRange = {range.location, range.length};
				
				NSInteger tag = (TAG_BASE + stringRange.location);
				
				// only add if there is no view yet with this tag
				if (![self viewWithTag:tag])
				{
					NSAttributedString *string = [_string attributedSubstringFromRange:stringRange]; 
					
					
					// need to flip
					CGRect runFrame = CGRectMake(runBounds.origin.x, self.bounds.size.height - lineOrigin.y - runAscent, runBounds.size.width, runAscent + runDescent + 1.0);
					
					runFrame.origin.x = floorf(runFrame.origin.x);
					runFrame.origin.y = floorf(runFrame.origin.y);
					runFrame.size.width = ceilf(runFrame.size.width) + 1.0;
					runFrame.size.height = ceilf(runFrame.size.height);
					
					UIView *view = [parentView.textDelegate attributedTextView:parentView viewForAttributedString:string frame:runFrame];
					
					if (view)
					{
						view.frame = runFrame;
						view.tag = tag;
						
						[self addSubview:view];
					}
				}
			}
			offset += runWidth;
		}
	}
	
	// cleanup
	free(origins);
	
	
	// Draw
	CTFrameDraw(self.textFrame, context);
}


- (void)dealloc 
{
	if (framesetter)
	{
		CFRelease(framesetter);
	}
	
	if (textFrame)
	{
		CFRelease(textFrame);
	}
	
	[_string release];
	
	[super dealloc];
}


- (CGSize)sizeThatFits:(CGSize)size
{
	CGSize neededSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, CFRangeMake(0, 0), NULL, 
																	 CGSizeMake(self.bounds.size.width-3.0-edgeInsets.left-edgeInsets.right, CGFLOAT_MAX),
																	 NULL);
	
	return CGSizeMake(self.bounds.size.width, ceilf(neededSize.height+edgeInsets.top+edgeInsets.bottom));
}


#pragma mark Properties
- (CTFramesetterRef) framesetter
{
	if (!framesetter)
	{
		framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_string);
	}
	
	return framesetter;
}


- (CTFrameRef)textFrame
{
	if (!textFrame)
	{
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathAddRect(path, NULL, UIEdgeInsetsInsetRect(self.bounds, edgeInsets));
		
		textFrame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, 0), path, NULL);
		
		CGPathRelease(path);
	}
	
	return textFrame;
}


- (void)relayoutText
{
	if (framesetter)
	{
		CFRelease(framesetter);
		framesetter = nil;
	}
	
	if (textFrame)
	{
		CFRelease(textFrame);
		textFrame = nil;
	}
	
	CGSize neededSize = [self sizeThatFits:CGSizeZero];
	self.frame = CGRectMake(0, 0, neededSize.width, neededSize.height);
	
	[self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	
	[self setNeedsDisplay];
}

- (void)setEdgeInsets:(UIEdgeInsets)newEdgeInsets
{
	if (!UIEdgeInsetsEqualToEdgeInsets(newEdgeInsets, edgeInsets))
	{
		edgeInsets = newEdgeInsets;
		
		[self relayoutText];
	}
}

- (void)setString:(NSAttributedString *)string
{
	if (string != _string)
	{
		[_string release];
		
		_string = [string retain];
		[self relayoutText];
	}
}

@synthesize framesetter;
@synthesize textFrame;
@synthesize string = _string;
@synthesize parentView;
@synthesize edgeInsets;

@end
