//
//  TextView.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextContentView.h"
#import "DTTextAttachment.h"
#import "NSAttributedString+HTML.h"
#import "NSString+HTML.h"
#import "UIColor+HTML.h"
#import <QuartzCore/QuartzCore.h>

#define DRAW_DEBUG_FRAMES 0

@interface DTAttributedTextContentView ()

@property (nonatomic) CTFramesetterRef framesetter;
@property (nonatomic) CTFrameRef textFrame;

@end

@implementation DTAttributedTextContentView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.contentMode = UIViewContentModeRedraw;
		self.backgroundColor = [UIColor whiteColor];
		self.opaque = YES;
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
	
	UIGraphicsPushContext(context);
	
	//CGContext(context);
	
	// Flip the coordinate system
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	// Draw
	CTFrameDraw(self.textFrame, context);

	//UIGraphicsPopContext();

	
	//CGContextRestoreGState(context);
//	CGContextSetTextPosition(context, 0, 0);
//	CGContextScaleCTM(context, 1.0, -1.0);
//	CGContextTranslateCTM(context, 0, -self.bounds.size.height);
	
	
#if DRAW_DEBUG_FRAMES
	CGFloat dashes[] = {1.0, 3.0};
	CGContextSetLineDash(context, 0, dashes, 2);
	CGContextStrokeRect(context, CGRectInset(self.bounds, 10, 10));
#endif
	
	
	// get lines
	CFArrayRef lines = CTFrameGetLines(textFrame);
	CGPoint *origins = malloc(sizeof(CGPoint)*[(NSArray *)lines count]);
	CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);
	NSInteger lineIndex = 0;
	
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextSetTextPosition(context, 0, 0);
	
	for (id oneLine in (NSArray *)lines)
	{
		CGPoint lineOrigin = origins[lineIndex];
		lineOrigin.x += 10.0; // add inset 
		lineOrigin.y += 10.0; // add inset
		
		CFArrayRef runs = CTLineGetGlyphRuns((CTLineRef)oneLine);
		CGFloat lineAscent;
		CGFloat lineDescent;
		CGFloat lineLeading;
		CGFloat lineWidth = CTLineGetTypographicBounds((CTLineRef)oneLine, &lineAscent, &lineDescent, &lineLeading);
		CGRect lineBounds = CTLineGetImageBounds((CTLineRef)oneLine, context);
		//Bounds((CTLineRef)oneLine, context);
				
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
		CGFloat offset = 10;
		
		for (id oneRun in (NSArray *)runs)
		{
			CGFloat runAscent = 0;
			CGFloat runDescent = 0;
			CGFloat runLeading = 0;
			
			CGFloat runWidth = CTRunGetTypographicBounds((CTRunRef) oneRun,
													  CFRangeMake(0, 0),
													  &runAscent,
													  &runDescent, &runLeading);
			
			CGRect runBounds = CTRunGetImageBounds((CTRunRef)oneRun, 
													 context, CFRangeMake(0, 0));
			
			
			runBounds.origin.x = offset;
			runBounds.origin.y = lineBounds.origin.y;
			runBounds.size.width = runWidth;
			runBounds.size.height = runAscent + runDescent + 1;
	
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
			
			
			NSDictionary *attributes = (NSDictionary *)CTRunGetAttributes((CTRunRef) oneRun);
			
			DTTextAttachment *attachment = [attributes objectForKey:@"DTTextAttachment"];
			
			if (attachment)
			{
				if ([attachment.contents isKindOfClass:[UIImage class]])
				{
					UIImage *image = (id)attachment.contents;

					//[[UIColor whiteColor] set];
					//CGContextFillRect(context, runBounds);
					
					CGRect imageBounds = CGRectMake(floorf(runBounds.origin.x), floorf(runBounds.origin.y + lineDescent), 
													attachment.size.width, attachment.size.height);
					CGContextDrawImage(context, imageBounds, image.CGImage); 
					//[image drawInRect:runBounds]; 
				}
			}
			
			BOOL strikeOut = [[attributes objectForKey:@"_StrikeOut"] boolValue];
			
			if (strikeOut)
			{
				CGRect runStrokeBounds = runBounds;

				// don't draw too far to the right
				if (runStrokeBounds.origin.x + runStrokeBounds.size.width > CGRectGetMaxX(lineBounds))
				{
					runStrokeBounds.size.width = CGRectGetMaxX(lineBounds) - runStrokeBounds.origin.x ;
				}
				
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
			
			offset += runWidth;
			
		}
	}
	
	// cleanup
	free(origins);
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
																	 CGSizeMake(self.bounds.size.width-23.0, CGFLOAT_MAX),
																	 NULL);
	
	return CGSizeMake(self.bounds.size.width, ceilf(neededSize.height+20));
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
		CGPathAddRect(path, NULL, CGRectInset(self.bounds, 10, 10));
		
		textFrame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, 0), path, NULL);
		
		CGPathRelease(path);
	}
	
	return textFrame;
}


- (void)setString:(NSAttributedString *)string
{
	if (string != _string)
	{
		[_string release];
		
		/*
		
		NSMutableAttributedString *tmpStr =[string mutableCopy];
		// create the delegate
		CTRunDelegateCallbacks callbacks;
		callbacks.version = kCTRunDelegateCurrentVersion;
		callbacks.dealloc = MyDeallocationCallback;
		callbacks.getAscent = MyGetAscentCallback;
		callbacks.getDescent = MyGetDescentCallback;
		callbacks.getWidth = MyGetWidthCallback;
		CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, NULL);
		
		// set the delegate as an attribute
		NSDictionary *dict = [NSDictionary dictionaryWithObject:(id)delegate forKey:(id)kCTRunDelegateAttributeName] ;
		[tmpStr setAttributes:dict range:NSMakeRange(0, [tmpStr	length])];
		//CFAttributedStringSetAttribute((CFMutableAttributedStringRef)tmpStr, CFRangeMake(0, [tmp), , delegate);
		
		 CFRelease(delegate);
		
		_string = [tmpStr copy];
		[tmpStr release];
		 */
		
		_string = [string retain];
		
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
		
		[self setNeedsDisplay];
	}
}

@synthesize framesetter;
@synthesize textFrame;
@synthesize string = _string;

@end
