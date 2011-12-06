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

// Commented code useful to find deadlocks
#define SYNCHRONIZE_START(lock) /* NSLog(@"LOCK: FUNC=%s Line=%d", __func__, __LINE__), */dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define SYNCHRONIZE_END(lock) dispatch_semaphore_signal(lock) /*, NSLog(@"UN-LOCK")*/;

@interface DTAttributedTextContentView ()
{
	NSAttributedString *_attributedString;
	UIEdgeInsets edgeInsets;
	BOOL drawDebugFrames;
	BOOL shouldDrawImages;
	BOOL shouldLayoutCustomSubviews;
	
	NSMutableSet *customViews;
	NSMutableDictionary *customViewsForLinksIndex;
	NSMutableDictionary *customViewsForAttachmentsIndex;
    
	BOOL _isTiling;
	
	DTCoreTextLayouter *_layouter;
	DTCoreTextLayoutFrame *_layoutFrame;
	
	CGPoint _layoutOffset;
    CGSize _backgroundOffset;
	
	// lookup bitmask what delegate methods are implemented
	struct 
	{
		unsigned int delegateSupportsCustomViewsForAttachments:1;
		unsigned int delegateSupportsCustomViewsForLinks:1;
		unsigned int delegateSupportsGenericCustomViews:1;
		unsigned int delegateSupportsNotificationAfterDrawing:1;
	} _delegateFlags;
	
	__unsafe_unretained id <DTAttributedTextContentViewDelegate> _delegate;
}

@property (nonatomic, strong) NSMutableDictionary *customViewsForLinksIndex;
@property (nonatomic, strong) NSMutableDictionary *customViewsForAttachmentsIndex;

- (void)removeAllCustomViews;
- (void)removeSubviewsOutsideRect:(CGRect)rect;
- (void)removeAllCustomViewsForLinks;

@end

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
@synthesize selfLock;

- (void)setup
{
	self.contentMode = UIViewContentModeTopLeft; // to avoid bitmap scaling effect on resize
	shouldLayoutCustomSubviews = YES;
	
	// by default we draw images, if custom views are supported (by setting delegate) this is disabled
	// if you still want images to be drawn together with text then set it back to YES after setting delegate
	shouldDrawImages = YES;
	
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
		
		_isTiling = YES;
	}
	
	[self selfLock];
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
	self = [self initWithFrame:CGRectMake(0, 0, width, 0)];
	
	if (self)
	{		
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
	
	dispatch_release(selfLock);
}

- (void)layoutSubviewsInRect:(CGRect)rect
{
	// if we are called for partial (non-infinate) we remove unneeded custom subviews first
	if (!CGRectIsInfinite(rect))
	{
		[self removeSubviewsOutsideRect:rect];
	}
	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	DTCoreTextLayoutFrame *theLayoutFrame = self.layoutFrame;

	SYNCHRONIZE_START(selfLock)
	{
		NSAttributedString *layoutString = [theLayoutFrame attributedStringFragment];
		NSArray *lines;
		if (CGRectIsInfinite(rect))
		{
			lines = [theLayoutFrame lines];
		}
		else
		{
			lines = [theLayoutFrame linesVisibleInRect:rect];
		}
		
		// hide all customViews
		for (UIView *view in self.customViews)
		{
			view.hidden = YES;
		}
		
		for (DTCoreTextLayoutLine *oneLine in lines)
		{
			NSRange lineRange = [oneLine stringRange];
			
			NSUInteger skipRunsBeforeLocation = 0;
			
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
					
					NSNumber *indexKey = [NSNumber numberWithInteger:stringRange.location];
					
					// offset layout if necessary
					if (!CGPointEqualToPoint(_layoutOffset, CGPointZero))
					{
						frameForSubview.origin.x += _layoutOffset.x;
						frameForSubview.origin.y += _layoutOffset.y;
					}
					
					// round frame
					frameForSubview.origin.x = floorf(frameForSubview.origin.x);
					frameForSubview.origin.y = ceilf(frameForSubview.origin.y);
					frameForSubview.size.width = roundf(frameForSubview.size.width);
					frameForSubview.size.height = roundf(frameForSubview.size.height);
					
					
					if (CGRectGetMinY(frameForSubview)> CGRectGetMaxY(rect) || CGRectGetMaxY(frameForSubview) < CGRectGetMinY(rect))
					{
						// is still outside even though the bounds of the line already intersect visible area
						continue;
					}
					
					if (_delegateFlags.delegateSupportsCustomViewsForAttachments || _delegateFlags.delegateSupportsGenericCustomViews)
					{
						DTTextAttachment *attachment = oneRun.attachment;
						
						if (attachment)
						{
							indexKey = [NSNumber numberWithInteger:[attachment hash]];
							
							UIView *existingAttachmentView = [self.customViewsForAttachmentsIndex objectForKey:indexKey];
							
							if (existingAttachmentView)
							{
								existingAttachmentView.hidden = NO;
								existingAttachmentView.frame = frameForSubview;
								
								existingAttachmentView.alpha = 1;
								[existingAttachmentView setNeedsLayout];
								[existingAttachmentView setNeedsDisplay];
								
								linkURL = nil; // prevent adding link button on top of image view
							}
							else
							{
								UIView *newCustomAttachmentView = nil;
								
								
								if (_delegateFlags.delegateSupportsCustomViewsForAttachments)
								{
									newCustomAttachmentView = [_delegate attributedTextContentView:self viewForAttachment:attachment frame:frameForSubview];
								}
								else
								{
									NSAttributedString *string = [layoutString attributedSubstringFromRange:stringRange]; 
									newCustomAttachmentView = [_delegate attributedTextContentView:self viewForAttributedString:string frame:frameForSubview];
								}
								
								if (newCustomAttachmentView)
								{
									// delegate responsible to set frame
									if (newCustomAttachmentView)
									{
										newCustomAttachmentView.tag = [indexKey integerValue];
										[self addSubview:newCustomAttachmentView];
										
										[self.customViews addObject:newCustomAttachmentView];
										[self.customViewsForAttachmentsIndex setObject:newCustomAttachmentView forKey:indexKey];
										
										linkURL = nil; // prevent adding link button on top of image view
									}
								}
							}
						}
					}
					
					
					if (linkURL && (_delegateFlags.delegateSupportsCustomViewsForLinks || _delegateFlags.delegateSupportsGenericCustomViews))
					{
						UIView *existingLinkView = [self.customViewsForLinksIndex objectForKey:indexKey];
						
						if (existingLinkView)
						{						
							existingLinkView.frame = frameForSubview;
							existingLinkView.hidden = NO;
						}
						else
						{
							UIView *newCustomLinkView = nil;
							
							if (_delegateFlags.delegateSupportsCustomViewsForLinks)
							{
								NSDictionary *attributes = [layoutString attributesAtIndex:stringRange.location effectiveRange:NULL];
								
								NSString *guid = [attributes objectForKey:@"DTGUID"];
								newCustomLinkView = [_delegate attributedTextContentView:self viewForLink:linkURL identifier:guid frame:frameForSubview];
							}
							else if (_delegateFlags.delegateSupportsGenericCustomViews)
							{
								NSAttributedString *string = [layoutString attributedSubstringFromRange:stringRange]; 
								newCustomLinkView = [_delegate attributedTextContentView:self viewForAttributedString:string frame:frameForSubview];
							}
							
							// delegate responsible to set frame
							if (newCustomLinkView)
							{
								newCustomLinkView.tag = stringRange.location;
								[self addSubview:newCustomLinkView];
								
								[self.customViews addObject:newCustomLinkView];
								[self.customViewsForLinksIndex setObject:newCustomLinkView forKey:indexKey];
							}
						}
					}
				}
			}
		}
		
		[CATransaction commit];
	}
	SYNCHRONIZE_END(selfLock)
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if (shouldLayoutCustomSubviews)
	{
		[self layoutSubviewsInRect:CGRectInfinite];
	}
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	// needs clearing of background
	CGRect rect = CGContextGetClipBoundingBox(ctx);
	
	if (_backgroundOffset.height || _backgroundOffset.width)
	{
		CGContextSetPatternPhase(ctx, _backgroundOffset);
	}
	
	CGContextSetFillColorWithColor(ctx, [self.backgroundColor CGColor]);
	CGContextFillRect(ctx, rect);
	
	// offset layout if necessary
	if (!CGPointEqualToPoint(_layoutOffset, CGPointZero))
	{
		CGAffineTransform transform = CGAffineTransformMakeTranslation(_layoutOffset.x, _layoutOffset.y);
		CGContextConcatCTM(ctx, transform);
	}
	
	DTCoreTextLayoutFrame *theLayoutFrame = self.layoutFrame;
	
	// need to prevent updating of string and drawing at the same time
	SYNCHRONIZE_START(selfLock)
	{
		[theLayoutFrame drawInContext:ctx drawImages:shouldDrawImages];
		
		if (_delegateFlags.delegateSupportsNotificationAfterDrawing)
		{
			[_delegate attributedTextContentView:self didDrawLayoutFrame:theLayoutFrame inContext:ctx];
		}
	}
	SYNCHRONIZE_END(selfLock)
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
	
	CGSize neededSize = CGSizeMake(size.width, CGRectGetMaxY(self.layoutFrame.frame) + edgeInsets.bottom);
	
	return neededSize;
}

- (CGSize)suggestedFrameSizeToFitEntireStringConstraintedToWidth:(CGFloat)width
{
	if (!isnormal(width))
	{
		width = self.bounds.size.width;
	}

	CGSize neededSize = [self.layouter suggestedFrameSizeToFitEntireStringConstraintedToWidth:width-edgeInsets.left-edgeInsets.right];
	
	// add vertical insets
	neededSize.height += edgeInsets.top + edgeInsets.bottom;
	
	return neededSize;
}

- (CGSize)attributedStringSizeThatFits:(CGFloat)width
{
	if (!isnormal(width))
	{
		width = self.bounds.size.width;
	}
	
	// attributedStringSizeThatFits: returns an unreliable measure prior to 4.2 for very long documents.
	CGSize neededSize = [self.layouter suggestedFrameSizeToFitEntireStringConstraintedToWidth:width-edgeInsets.left-edgeInsets.right];
	return neededSize;
}


- (NSString *)description
{
	NSString *extract = [[[_layoutFrame attributedStringFragment] string] substringFromIndex:[self.layoutFrame visibleStringRange].location];
	
	if ([extract length]>10)
	{
		extract = [extract substringToIndex:10];
	}
	
	return [NSString stringWithFormat:@"<%@ %@ range:%@ '%@...'>", [self class], NSStringFromCGRect(self.frame),NSStringFromRange([self.layoutFrame visibleStringRange]), extract];
}

- (void)relayoutText
{
    // Make sure we actually have a superview before attempting to relayout the text.
    if (self.superview) {
        // need new layouter
        self.layouter = nil;
        self.layoutFrame = nil;
        
        // remove all links because they might have merged or split
        [self removeAllCustomViewsForLinks];
        
        if (_attributedString)
        {
            // triggers new layout
            CGSize neededSize = [self sizeThatFits:self.bounds.size];
            
            // set frame to fit text preserving origin
            // call super to avoid endless loop
            [self willChangeValueForKey:@"frame"];
            super.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, neededSize.width, neededSize.height);
            [self didChangeValueForKey:@"frame"];
        }
        
        [self setNeedsDisplay];
        [self setNeedsLayout];
    }
}

- (void)removeAllCustomViewsForLinks
{
	NSArray *linkViews = [customViewsForLinksIndex allValues];
	
	for (UIView *customView in linkViews)
	{
		[customView removeFromSuperview];
		[customViews removeObject:customView];
	}
	
	[customViewsForLinksIndex removeAllObjects];
}

- (void)removeAllCustomViews
{
	NSSet *allCustomViews = [NSSet setWithSet:customViews];
	for (UIView *customView in allCustomViews)
	{
		[customView removeFromSuperview];
		[customViews removeObject:customView];
	}
	
	[customViewsForAttachmentsIndex removeAllObjects];
	[customViewsForLinksIndex removeAllObjects];
}

- (void)removeSubviewsOutsideRect:(CGRect)rect
{
	NSSet *allCustomViews = [NSSet setWithSet:customViews];
	for (UIView *customView in allCustomViews)
	{
		if (CGRectGetMinY(customView.frame)> CGRectGetMaxY(rect) || CGRectGetMaxY(customView.frame) < CGRectGetMinY(rect))
		{
			NSNumber *indexKey = [NSNumber numberWithInteger:customView.tag];
			
			[customView removeFromSuperview];
			[customViews removeObject:customView];
			
			[customViewsForAttachmentsIndex removeObjectForKey:indexKey];
			[customViewsForLinksIndex removeObjectForKey:indexKey];
		}
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
		
		_attributedString = [string copy];
		
		// new layout invalidates all positions for custom views
		[self removeAllCustomViews];
		
		[self relayoutText];
	}
}

- (void)setFrame:(CGRect)frame //relayoutText:(BOOL)relayoutText
{
	CGRect oldFrame = self.frame;
	
	[super setFrame:frame];
	
	if (!_layoutFrame) 
	{
		return;	
	}
	
	BOOL frameDidChange = !CGRectEqualToRect(oldFrame, frame);
	
	// having a layouter means we are responsible for layouting yourselves
	if (frameDidChange)
	{
		[self relayoutText];
	}
}

//- (void)setFrame:(CGRect)frame
//{
//	// sizeToFit also calls this, but we want to be able to avoid relayouting
//	[self setFrame:frame relayoutText:_relayoutTextOnFrameChange];
//}

- (void)setDrawDebugFrames:(BOOL)newSetting
{
	if (drawDebugFrames != newSetting)
	{
		drawDebugFrames = newSetting;
		
		[self setNeedsDisplay];
	}
}

- (void)setShouldDrawImages:(BOOL)newSetting
{
	if (shouldDrawImages != newSetting)
	{
		shouldDrawImages = newSetting;
		
		[self setNeedsDisplay];
	}
}

- (void)setBackgroundColor:(UIColor *)newColor
{
	super.backgroundColor = newColor;
	
	if ([newColor alpha]<1.0)
	{
		self.opaque = NO;
	}
	else 
	{
		self.opaque = YES;
	}
}


- (DTCoreTextLayouter *)layouter
{
	SYNCHRONIZE_START(selfLock)
	{
		if (!_layouter)
		{
			if (_attributedString)
			{
				_layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:_attributedString];
			}
		}
	}
	SYNCHRONIZE_END(selfLock)
	
	return _layouter;
}

- (void)setLayouter:(DTCoreTextLayouter *)layouter
{
	SYNCHRONIZE_START(selfLock)
	{
		if (_layouter != layouter)
		{
			_layouter = layouter;
		}
	}
	SYNCHRONIZE_END(selfLock)
}

- (DTCoreTextLayoutFrame *)layoutFrame
{
	DTCoreTextLayouter *theLayouter = self.layouter;
	
	if (!_layoutFrame)
	{
		// prevent unnecessary locking if we don't need to create new layout frame
		SYNCHRONIZE_START(selfLock)
		{
			// Test again - small window where another thread could have been setting this value
			if (!_layoutFrame)
			{
				// we can only layout if we have our own layouter
				if (theLayouter)
				{
					CGRect rect = UIEdgeInsetsInsetRect(self.bounds, edgeInsets);
					rect.size.height = CGFLOAT_OPEN_HEIGHT; // necessary height set as soon as we know it.
					
					_layoutFrame = [theLayouter layoutFrameWithRect:rect range:NSMakeRange(0, 0)];
				}
			}
		}
		SYNCHRONIZE_END(selfLock)
	}
	
	return _layoutFrame;
}

- (void)setLayoutFrame:(DTCoreTextLayoutFrame *)layoutFrame
{
	SYNCHRONIZE_START(selfLock)
	{
		if (_layoutFrame != layoutFrame)
		{
			[self removeAllCustomViewsForLinks];
			
			if (layoutFrame)
			{
				[self setNeedsLayout];
				[self setNeedsDisplay];
			}
			_layoutFrame = layoutFrame;
		}
	}
	SYNCHRONIZE_END(selfLock)
}

- (NSMutableSet *)customViews
{
	if (!customViews)
	{
		customViews = [[NSMutableSet alloc] init];
	}
	
	return customViews;
}

- (NSMutableDictionary *)customViewsForLinksIndex
{
	if (!customViewsForLinksIndex)
	{
		customViewsForLinksIndex = [[NSMutableDictionary alloc] init];
	}
	
	return customViewsForLinksIndex;
}

- (NSMutableDictionary *)customViewsForAttachmentsIndex
{
	if (!customViewsForAttachmentsIndex)
	{
		customViewsForAttachmentsIndex = [[NSMutableDictionary alloc] init];
	}
	
	return customViewsForAttachmentsIndex;
}

- (void)setDelegate:(id<DTAttributedTextContentViewDelegate>)delegate
{
	_delegate = delegate;
	
	_delegateFlags.delegateSupportsCustomViewsForAttachments = [_delegate respondsToSelector:@selector(attributedTextContentView:viewForAttachment:frame:)];
	_delegateFlags.delegateSupportsCustomViewsForLinks = [_delegate respondsToSelector:@selector(attributedTextContentView:viewForLink:identifier:frame:)];
	_delegateFlags.delegateSupportsGenericCustomViews = [_delegate respondsToSelector:@selector(attributedTextContentView:viewForAttributedString:frame:)];
	_delegateFlags.delegateSupportsNotificationAfterDrawing = [_delegate respondsToSelector:@selector(attributedTextContentView:didDrawLayoutFrame:inContext:)];
	
	if (!_delegateFlags.delegateSupportsCustomViewsForLinks && !_delegateFlags.delegateSupportsGenericCustomViews)
	{
		[self removeAllCustomViewsForLinks];
	}
	
	// we don't draw the images if imageViews are provided by the delegate method
	// if you want images to be drawn even though you use custom views, set it back to YES after setting delegate
	if (_delegateFlags.delegateSupportsGenericCustomViews || _delegateFlags.delegateSupportsCustomViewsForAttachments)
	{
		shouldDrawImages = NO;
	}
	else
	{
		shouldDrawImages = YES;
	}
}


- (dispatch_semaphore_t)selfLock
{
	if (!selfLock)
	{
		selfLock = dispatch_semaphore_create(1);
	}
	
	return selfLock;
}


@synthesize layouter = _layouter;
@synthesize layoutFrame = _layoutFrame;
@synthesize attributedString = _attributedString;
@synthesize delegate = _delegate;
@synthesize edgeInsets;
@synthesize drawDebugFrames;
@synthesize shouldDrawImages;
@synthesize shouldLayoutCustomSubviews;
@synthesize layoutOffset = _layoutOffset;
@synthesize backgroundOffset = _backgroundOffset;

@synthesize customViews;
@synthesize customViewsForLinksIndex;
@synthesize customViewsForAttachmentsIndex;

@end
