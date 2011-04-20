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


static Class _layerClassToUseForDTAttributedTextContentView = nil;

@implementation DTAttributedTextContentView (Tiling)

+ (void)setLayerClass:(Class)layerClass
{
    _layerClassToUseForDTAttributedTextContentView = layerClass;
}

+ (Class)layerClass
{
    if (_layerClassToUseForDTAttributedTextContentView)
    {
        return _layerClassToUseForDTAttributedTextContentView;
    }
    
    return [CALayer class];
}

@end



@implementation DTAttributedTextContentView

- (void)setup
{
	self.contentMode = UIViewContentModeRedraw;
	self.userInteractionEnabled = YES;
	
	self.opaque = NO;
	self.contentMode = UIViewContentModeTopLeft; // to avoid bitmap scaling effect on resize
	
	drawDebugFrames = NO;
}

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
    self = [super initWithFrame:CGRectMake(0, 0, width, 0)];
    
	if (self)
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

- (void)layoutSubviews
{
	[super layoutSubviews];
    
    if (![delegate respondsToSelector:@selector(attributedTextContentView:viewForAttributedString:frame:)])
    {
        return;
    }
	
	DTCoreTextLayoutFrame *layoutFrame = [self.layouter layoutFrameAtIndex:0];
	
	for (DTCoreTextLayoutLine *oneLine in layoutFrame.lines)
	{
        NSRange lineRange = [oneLine stringRange];
        
        NSInteger skipRunsBeforeLocation = 0;
        
		for (DTCoreTextGlyphRun *oneRun in oneLine.glyphRuns)
		{
			// add custom views if necessary
            NSRange stringRange = [oneRun stringRange];
            CGRect frameForSubview = CGRectZero;
            
            
            if (stringRange.location>=skipRunsBeforeLocation)
            {
                // see if it's a link
                NSRange effectiveRange;
                NSURL *linkURL = [_attributedString attribute:@"DTLink" atIndex:stringRange.location longestEffectiveRange:&effectiveRange inRange:lineRange];
                
                if (linkURL)
                {
                    // compute bounding frame over potentially multiple (chinese) glyphs
                    
                    // make one link view for all glyphruns in this line
                    NSLog(@"%@", linkURL);
                    
                    frameForSubview = [oneLine frameOfGlyphsWithRange:effectiveRange];
                    stringRange = effectiveRange;
                    
                    skipRunsBeforeLocation = effectiveRange.location+effectiveRange.length;
                }
                else
                {
                    // individual glyph run
                    frameForSubview = oneRun.frame;
                }
                
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
                    
                    UIView *view = [delegate attributedTextContentView:self viewForAttributedString:string frame:frameForSubview];
                    
                    if (view)
                    {
                        view.frame = frameForSubview;
                        view.tag = tag;
                        
                        [self addSubview:view];
                        
                        [self.customViews addObject:view];
                    }
                }
            }
			
		}
	}
}

-(void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
    DTCoreTextLayoutFrame *frame = [self.layouter layoutFrameAtIndex:0];
    
    [frame drawInContext:context];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawLayer:self.layer inContext:context];
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
		
        // set tile size if applicable
        CATiledLayer *layer = (id)self.layer;
        if ([layer isKindOfClass:[CATiledLayer class]])
        {
            CGSize tileSize = CGSizeMake(newFrame.size.width, 1024);
            
            if ([self respondsToSelector:@selector(contentScaleFactor)])
            {
                CGFloat scaleFactor = [self contentScaleFactor];
                tileSize.width *= scaleFactor;
                tileSize.height *= scaleFactor;
            }
            
            layer.tileSize = tileSize;
        }
        
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
@synthesize delegate;
@synthesize edgeInsets;
@synthesize drawDebugFrames;
@synthesize customViews;

@end
