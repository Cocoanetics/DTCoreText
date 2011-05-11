//
//  TextView.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextContentView.h"
#import "DTAttributedTextView.h"
#import "DTCoreTextLayoutFrame.h"

#import "DTTextAttachment.h"
#import "NSString+HTML.h"
#import "UIColor+HTML.h"

#import "DTLinkButton.h"

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
	self.contentMode = UIViewContentModeRedraw; // to avoid bitmap scaling effect on resize
	
	// possibly already set in NIB
	if (!self.backgroundColor)
	{
		self.backgroundColor = [UIColor whiteColor];
	}
	
	// set tile size if applicable
	CATiledLayer *layer = (id)self.layer;
	if ([layer isKindOfClass:[CATiledLayer class]])
	{
		CGSize tileSize = CGSizeMake(1024, 1024); // tiled layer reduzes with to fit
		layer.tileSize = tileSize;
	}
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

- (void)awakeFromNib
{
	[self setup];
}

- (void)dealloc 
{
	[self removeAllCustomViews];
	[customViews release];
	
	[_layouter release];
	[_layoutFrame release];
	[_attributedString release];
	
	[super dealloc];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    
    if (!_delegateSupportsCustomViews || !self.layoutFrame)
    {
		[self removeAllCustomViews];
		
        return;
    }
	
	// remove all existing custom views for links, other custom views we can adjust frame
	for (UIView *customView in [NSSet setWithSet:customViews])
	{
		if ([customView isKindOfClass:[DTLinkButton class]])
		{
			[customView removeFromSuperview];
			[customViews removeObject:customView];
		}
	}
	
	NSAttributedString *layoutString = self.layoutFrame.layouter.attributedString;
	
	for (DTCoreTextLayoutLine *oneLine in self.layoutFrame.lines)
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
				
                NSURL *linkURL = [layoutString attribute:@"DTLink" atIndex:stringRange.location longestEffectiveRange:&effectiveRange inRange:lineRange];
                
                if (linkURL)
                {
                    // compute bounding frame over potentially multiple (chinese) glyphs
                    
                    // make one link view for all glyphruns in this line
                    frameForSubview = [oneLine frameOfGlyphsWithRange:effectiveRange];
                    stringRange = effectiveRange;
                    
                    skipRunsBeforeLocation = effectiveRange.location+effectiveRange.length;
                }
                else
                {
                    // individual glyph run
                    frameForSubview = oneRun.frame;
                }
				
				if (CGRectIsEmpty(frameForSubview))
				{
					continue;
				}
                
                NSInteger tag = (TAG_BASE + stringRange.location);
                
                UIView *existingView = [self viewWithTag:tag];
                
                // only add if there is no view yet with this tag
                if (existingView)
                {
					// update frame
                    existingView.frame = oneRun.frame;
                }
                else 
                {
					// create new customView via delegate
                    NSAttributedString *string = [layoutString attributedSubstringFromRange:stringRange]; 
                    
                    UIView *view = [_delegate attributedTextContentView:self viewForAttributedString:string frame:frameForSubview];
                    
					// delegate responsible to set proper frame
                    if (view)
                    {
                        view.tag = tag;
                        
                        [self addSubview:view];
                        
                        [self.customViews addObject:view];
                    }
                }
            }
			
		}
	}
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	// needs clearing of background
	CGRect rect = CGContextGetClipBoundingBox(ctx);
	
	CGContextSetFillColorWithColor(ctx, [self.backgroundColor CGColor]);
	CGContextFillRect(ctx, rect);
	
    [self.layoutFrame drawInContext:ctx];
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
    [self.layoutFrame drawInContext:context];
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

- (NSString *)description
{
    NSString *extract = [[_layoutFrame.layouter.attributedString string] substringFromIndex:[self.layoutFrame visibleStringRange].location];
	
    if ([extract length]>10)
    {
        extract = [extract substringToIndex:10];
    }
	
    return [NSString stringWithFormat:@"<%@ %@ range:%@ '%@...'>", [self class], NSStringFromCGRect(self.frame),NSStringFromRange([self.layoutFrame visibleStringRange]), extract];
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

- (void)removeAllCustomViews
{
	// remove all existing custom views for links
	for (UIView *customView in [NSSet setWithSet:customViews])
	{
		[customView removeFromSuperview];
		[customViews removeObject:customView];
	}
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
		
		[self setNeedsDisplay];
	}
}

- (void)setFrame:(CGRect)frame
{
	CGRect previousFrame = self.frame;
	
	[super setFrame:frame];
	
	if (!CGRectEqualToRect(frame, previousFrame) && !CGRectIsEmpty(frame) && !(frame.size.height<0))
	{
		// if we have a layouter then it can create a new layoutFrame for us on redraw
		if (_layouter)
		{
			// next redraw will do new layout
			self.layoutFrame = nil;
		}
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
	if (!_layouter && _attributedString)
	{
		_layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:_attributedString];
	}
	
	return _layouter;
}

- (DTCoreTextLayoutFrame *)layoutFrame
{
	if (!_layoutFrame)
	{
		CGRect rect = UIEdgeInsetsInsetRect(self.bounds, edgeInsets);
		_layoutFrame = [self.layouter layoutFrameWithRect:rect range:NSMakeRange(0, 0)];
		[_layoutFrame retain];
	}
	return _layoutFrame;
}

- (void)setLayoutFrame:(DTCoreTextLayoutFrame *)layoutFrame
{
    if (_layoutFrame != layoutFrame)
    {
        [_layoutFrame release];
		
        _layoutFrame = [layoutFrame retain];
		
		[self setNeedsLayout];
		[self setNeedsDisplay];
    }
}

- (NSMutableSet *)customViews
{
	if (!customViews)
	{
		customViews = [[NSMutableSet alloc] init];
	}
	
	return customViews;
}

- (void)setDelegate:(id<DTAttributedTextContentViewDelegate>)delegate
{
	_delegate = delegate;
	
	_delegateSupportsCustomViews = [_delegate respondsToSelector:@selector(attributedTextContentView:viewForAttributedString:frame:)];
}

@synthesize layouter = _layouter;
@synthesize layoutFrame = _layoutFrame;
@synthesize attributedString = _attributedString;
@synthesize delegate = _delegate;
@synthesize edgeInsets;
@synthesize drawDebugFrames;
@synthesize customViews;

@end
