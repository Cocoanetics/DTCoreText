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
#import "NSString+HTML.h"
#import "UIColor+HTML.h"

#import <QuartzCore/QuartzCore.h>



#define TAG_BASE 9999

@interface DTAttributedTextContentView ()

- (void)setup;


@property (nonatomic, retain) DTCoreTextLayouter *layouter;
@property (nonatomic, retain) NSMutableSet *customViews;
@end



@implementation DTAttributedTextContentView

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
	{
		[self setup];
    }
    return self;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString width:(CGFloat)width
{
	if (self = [super initWithFrame:CGRectMake(0, 0, width, 0)])
	{
		[self setup];
		
		// causes appropriate sizing
		self.attributedString = attributedString;
		[self sizeToFit];
	}
	
	return self;
}

- (void)dealloc 
{
	[_attributedString release];
	[layouter release];
	[customViews release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[self setup];
}

- (void)setup
{
	self.contentMode = UIViewContentModeRedraw;
	self.userInteractionEnabled = YES;
	
	edgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
	
	self.opaque = NO;
	self.contentMode = UIViewContentModeTopLeft; // to avoid bitmap scaling effect on resize
	
	drawDebugFrames = NO;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	DTCoreTextLayoutFrame *layoutFrame = [self.layouter layoutFrameAtIndex:0];
	
	for (DTCoreTextLayoutLine *oneLine in layoutFrame.lines)
	{
		for (DTCoreTextGlyphRun *oneRun in oneLine.glyphRuns)
		{
			// add custom views if necessary
			if ([parentView.textDelegate respondsToSelector:@selector(attributedTextView:viewForAttributedString:frame:)])
			{
				NSRange stringRange = [oneRun stringRange];
				
				NSInteger tag = (TAG_BASE + stringRange.location);
				
				UIView *existingView = [self viewWithTag:tag];
				
				// only add if there is no view yet with this tag
				if (existingView)
				{
					existingView.frame = oneRun.frame;
				}
				else 
				{
					NSAttributedString *string = [_attributedString attributedSubstringFromRange:stringRange]; 
					
					UIView *view = [parentView.textDelegate attributedTextView:parentView viewForAttributedString:string frame:oneRun.frame];
					
					if (view)
					{
						view.frame = oneRun.frame;
						view.tag = tag;
						
						[self addSubview:view];
						
						[self.customViews addObject:view];
					}
				}
			}
		}
	}
}

- (void)drawRect:(CGRect)rect 
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// TODO: do all these settings make sense?
	CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
	CGContextSetAllowsAntialiasing(context, YES);
	CGContextSetShouldAntialias(context, YES);
	
	CGContextSetAllowsFontSubpixelQuantization(context, YES);
	CGContextSetShouldSubpixelQuantizeFonts(context, YES);
	
	CGContextSetShouldSmoothFonts(context, YES);
	CGContextSetAllowsFontSmoothing(context, YES);
	
	CGContextSetShouldSubpixelPositionFonts(context,YES);
	CGContextSetAllowsFontSubpixelPositioning(context, YES);
	
	
	DTCoreTextLayoutFrame *layoutFrame = [self.layouter layoutFrameAtIndex:0];
	
	if (drawDebugFrames)
	{
		CGFloat dashes[] = {10.0, 2.0};
		CGContextSetLineDash(context, 0, dashes, 2);
		
		CGPathRef framePath = [layoutFrame path];
		CGContextAddPath(context, framePath);
		CGContextStrokePath(context);
	}
	
	for (DTCoreTextLayoutLine *oneLine in layoutFrame.lines)
	{
		if (drawDebugFrames)
		{
			[[UIColor blueColor] set];
			
			CGContextSetLineDash(context, 0, NULL, 0);
			CGContextStrokeRect(context, oneLine.frame);
			
			CGContextMoveToPoint(context, oneLine.baselineOrigin.x-5.0, oneLine.baselineOrigin.y);
			CGContextAddLineToPoint(context, oneLine.baselineOrigin.x + oneLine.frame.size.width + 5.0, oneLine.baselineOrigin.y);
			CGContextStrokePath(context);
			
			CGContextSetRGBFillColor(context, 0, 0, 1, 0.1);
			
		}
		
		NSInteger runIndex = 0;
		
		for (DTCoreTextGlyphRun *oneRun in oneLine.glyphRuns)
		{
			if (drawDebugFrames)
			{
				if (runIndex%2)
				{
					CGContextSetRGBFillColor(context, 1, 0, 0, 0.2);
				}
				else 
				{
					CGContextSetRGBFillColor(context, 0, 1, 0, 0.2);
				}
				
				CGContextFillRect(context, oneRun.frame);
				runIndex ++;
			}
			
			
			// -------------- Draw Embedded Images
			DTTextAttachment *attachment = [oneRun.attributes objectForKey:@"DTTextAttachment"];
			
			if (attachment)
			{
				if ([attachment.contents isKindOfClass:[UIImage class]])
				{
					UIImage *image = (id)attachment.contents;
					
					CGRect imageBounds = CGRectMake(roundf(oneRun.frame.origin.x), roundf(oneRun.baselineOrigin.y - attachment.size.height), 
													attachment.size.width, attachment.size.height);
					
					
					[image drawInRect:imageBounds];
				}
			}
			
			
			// -------------- Line-Out
			
			CGRect runImageBounds = [oneRun imageBoundsInContext:context];
			
			// whitespace glyph at EOL has zero width, we don't want to stroke that
			if (runImageBounds.size.width>0)
			{
				if ([[oneRun.attributes objectForKey:@"_StrikeOut"] boolValue])
				{
					CGRect runStrokeBounds = oneRun.frame;
					
					runStrokeBounds.origin.y += roundf(oneRun.frame.size.height/2.0);
					
					// get text color or use black
					id color = [oneRun.attributes objectForKey:(id)kCTForegroundColorAttributeName];
					
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
					
					CGContextMoveToPoint(context, runStrokeBounds.origin.x, runStrokeBounds.origin.y);
					CGContextAddLineToPoint(context, runStrokeBounds.origin.x + runStrokeBounds.size.width, runStrokeBounds.origin.y);
					
					CGContextStrokePath(context);
				}
			}
		}
	}
	
	// Flip the coordinate system
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextScaleCTM(context, 1.0, -1.0);
	CGContextTranslateCTM(context, 0, -self.frame.size.height);

	
	//CGContextTranslateCTM(context, 0, -edgeInsets.top+edgeInsets.bottom);
	//[layoutFrame drawInContext:context];
	
	// instead of using the convenience method to draw the entire frame, we draw individual glyph runs

	for (DTCoreTextLayoutLine *oneLine in layoutFrame.lines)
	{
		for (DTCoreTextGlyphRun *oneRun in oneLine.glyphRuns)
		{
			CGContextSaveGState(context);
			
			CGContextSetTextPosition(context, oneLine.frame.origin.x, self.frame.size.height - oneRun.frame.origin.y - oneRun.ascent);
			
			
			NSArray *shadows = [oneRun.attributes objectForKey:@"_Shadows"];
			
			if (shadows)
			{
				for (NSDictionary *shadowDict in shadows)
				{
					UIColor *color = [shadowDict objectForKey:@"Color"];
					CGSize offset = [[shadowDict objectForKey:@"Offset"] CGSizeValue];
					CGFloat blur = [[shadowDict objectForKey:@"Blur"] floatValue];
					
					CGFloat scaleFactor = 1.0;
					if ([self respondsToSelector:@selector(contentScaleFactor)])
					{
						scaleFactor = [self contentScaleFactor];
					}
					
					
					// workaround for scale 1: strangely offset (1,1) with blur 0 does not draw any shadow, (1.01,1.01) does
					if (scaleFactor==1.0)
					{
						if (fabs(offset.width)==1.0)
						{
							offset.width *= 1.50;
						}
						
						if (fabs(offset.height)==1.0)
						{
							offset.height *= 1.50;
						}
					}
					
					CGContextSetShadowWithColor(context, offset, blur, color.CGColor);
					
					// draw once per shadow
					[oneRun drawInContext:context];
					
				}
			}
			else
			{
				[oneRun drawInContext:context];
			}
			
			CGContextRestoreGState(context);
			
		}
	}
	
}

- (CGSize)sizeThatFits:(CGSize)size
{
	if (size.width==0)
	{
		size.width = self.bounds.size.width;
	}
	
	CGSize neededSize = [self.layouter suggestedFrameSizeToFitEntireStringConstraintedToWidth:size.width-edgeInsets.left-edgeInsets.right];
	
	// increase by edge insets
	return CGSizeMake(size.width, ceilf(neededSize.height+edgeInsets.top+edgeInsets.bottom));
}


- (void)relayoutText
{
	// remove custom views
	[self.customViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	self.customViews = nil;
	
	CGSize neededSize = [self sizeThatFits:CGSizeZero];
	
	// set frame to fit text preserving origin
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, neededSize.width, neededSize.height);
	
	// need new layouter
	self.layouter = nil;
	
	[self setNeedsDisplay];
}


#pragma mark Properties
- (void)setEdgeInsets:(UIEdgeInsets)newEdgeInsets
{
	if (!UIEdgeInsetsEqualToEdgeInsets(newEdgeInsets, edgeInsets))
	{
		edgeInsets = newEdgeInsets;
		
		[self relayoutText];
	}
}

- (void)setAttributedString:(NSAttributedString *)string
{
	if (_attributedString != string)
	{
		[_attributedString release];
		
		_attributedString = [string copy];
		
		// need new layouter
		self.layouter = nil;
		
		// remove custom views
		[self.customViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
		self.customViews = nil;
		
		[self setNeedsDisplay];
	}
}

- (void)setFrame:(CGRect)newFrame
{
	if (!CGRectEqualToRect(newFrame, self.frame) && !CGRectIsEmpty(newFrame) && !(newFrame.size.height<0))
	{
		[super setFrame:newFrame];
		
		
		// next redraw will do new layout
		self.layouter = nil;
		
		// contentMode = topLeft, no automatic redraw on bounds change
		[self setNeedsDisplay];
	}
	else 
	{
		//NSLog(@"ignoring content set to: %@", NSStringFromCGRect(newFrame) );
	}
}

- (void)setDrawDebugFrames:(BOOL)newSetting
{
	if (drawDebugFrames != newSetting)
	{
		drawDebugFrames = newSetting;
		
		[self setNeedsDisplay];
	}
}

- (DTCoreTextLayouter *)layouter
{
	if (!layouter)
	{
		layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:_attributedString];
	}
	
	if (![layouter numberOfFrames])
	{
		[layouter addTextFrameWithFrame:UIEdgeInsetsInsetRect(self.bounds, edgeInsets)];
	}
	
	return layouter;
}

- (NSMutableSet *)customViews
{
	if (!customViews)
	{
		customViews = [[NSMutableSet alloc] init];
	}
	
	return customViews;
}

@synthesize layouter;
@synthesize attributedString = _attributedString;
@synthesize parentView;
@synthesize edgeInsets;
@synthesize drawDebugFrames;
@synthesize customViews;

@end
