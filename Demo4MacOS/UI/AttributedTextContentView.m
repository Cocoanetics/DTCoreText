//
//  DTAttributedTextContentView.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <DTCoreText/DTCoreText.h>
#import "AttributedTextContentView.h"
#import <DTCoreText/DTDictationPlaceholderTextAttachment.h>
#import <DTCoreText/DTCoreTextLayoutFrame+Cursor.h>
#import "DTBlockFunctions.h"

#if !__has_feature(objc_arc)
#error THIS CODE MUST BE COMPILED WITH ARC ENABLED!
#endif

NSString * const DTAttributedTextContentViewDidFinishLayoutNotification = @"DTAttributedTextContentViewDidFinishLayoutNotification";

@interface AttributedTextContentView () <CALayerDelegate>
{
	BOOL _shouldAddFirstLineLeading;
	BOOL _shouldDrawImages;
	BOOL _shouldDrawLinks;
	BOOL _shouldLayoutCustomSubviews;
	DTAttributedTextContentViewRelayoutMask _relayoutMask;
	
	NSMutableSet *customViews;
	NSMutableDictionary *customViewsForLinksIndex;
    
	BOOL _isTiling;
	BOOL _layoutFrameHeightIsConstrainedByBounds;
	
	DTCoreTextLayouter *_layouter;
	
	CGPoint _layoutOffset;
    CGSize _backgroundOffset;
	
	// lookup bitmask what delegate methods are implemented
	struct
	{
		unsigned int delegateSupportsCustomViewsForAttachments:1;
		unsigned int delegateSupportsCustomViewsForLinks:1;
		unsigned int delegateSupportsGenericCustomViews:1;
		unsigned int delegateSupportsNotificationBeforeDrawing:1;
		unsigned int delegateSupportsNotificationAfterDrawing:1;
		unsigned int delegateSupportsNotificationBeforeTextBoxDrawing:1;
	} _delegateFlags;
	
	DT_WEAK_VARIABLE id <AttributedTextContentViewDelegate> _delegate;
}

@property (nonatomic, strong) NSMutableDictionary *customViewsForLinksIndex;
@property (nonatomic, strong) NSMutableDictionary *customViewsForAttachmentsIndex;
@property (nonatomic, strong) NSMutableSet *customViews;

@property (nonatomic, strong) NSArray *accessibilityElements;

- (void)removeAllCustomViews;
- (void)removeAllCustomViewsForLinks;
- (void)removeSubviewsOutsideRect:(CGRect)rect;

@end

static Class _layerClassToUseForDTAttributedTextContentView = nil;

@implementation AttributedTextContentView (Tiling)

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


@implementation AttributedTextContentView (Cursor)

- (NSInteger)closestCursorIndexToPoint:(CGPoint)point
{
	return [self.layoutFrame closestCursorIndexToPoint:point];
}

- (CGRect)cursorRectAtIndex:(NSInteger)index
{
	return [self.layoutFrame cursorRectAtIndex:index];
}

@end


@implementation AttributedTextContentView

- (void)setup
{
	_shouldLayoutCustomSubviews = YES;
	
	// no extra leading is added by default
	_shouldAddFirstLineLeading = NO;
	
	// by default we draw images, if custom views are supported (by setting delegate) this is disabled
	// if you still want images to be drawn together with text then set it back to YES after setting delegate
	_shouldDrawImages = YES;
	
	// by default we draw links. If you don't want that because you want to highlight the text in
	// DTLinkButton set this property to NO and create a highlighted version of the attributed string
	_shouldDrawLinks = YES;
	
	_layoutFrameHeightIsConstrainedByBounds = NO; // we calculate the necessary height unemcumbered by bounds
	_relayoutMask = DTAttributedTextContentViewRelayoutOnWidthChanged;
	
	// possibly already set in NIB
	if (!self.backgroundColor)
	{
		self.backgroundColor = [DTColor whiteColor];
	}
	
	// set tile size if applicable
	CATiledLayer *layer = (id)self.layer;
	if ([layer isKindOfClass:[CATiledLayer class]])
	{
		// get larger dimension and multiply by scale
		NSScreen *mainScreen = [NSScreen mainScreen];
		CGFloat largerDimension = MAX(mainScreen.frame.size.width, mainScreen.frame.size.height);
		CGFloat scale = mainScreen.backingScaleFactor;
		
		// this way tiles cover entire screen regardless of orientation or scale
		CGSize tileSize = CGSizeMake(largerDimension * scale, largerDimension * scale);
		layer.tileSize = tileSize;
		
		_isTiling = YES;
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

- (void)awakeFromNib
{
	[super awakeFromNib];
	[self setup];
}

- (void)dealloc
{
	[self removeAllCustomViews];
}

- (NSString *)debugDescription
{
	NSString *extract = [[[_layoutFrame attributedStringFragment] string] substringFromIndex:[self.layoutFrame visibleStringRange].location];
	
	if ([extract length]>10)
	{
		extract = [extract substringToIndex:10];
	}
	
	return [NSString stringWithFormat:@"<%@ %@ range:%@ '%@...'>", [self class], NSStringFromCGRect(self.frame),NSStringFromRange([self.layoutFrame visibleStringRange]), extract];
}

- (BOOL)isFlipped {
	return YES;
}

- (void)layoutSubviewsInRect:(CGRect)rect
{
	// if we are called for partial (non-infinite) we remove unneeded custom subviews first
	if (!CGRectIsInfinite(rect))
	{
		[self removeSubviewsOutsideRect:rect];
	}
	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	DTCoreTextLayoutFrame *theLayoutFrame = self.layoutFrame;
	
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
	for (NSView *view in self.customViews)
	{
		view.hidden = YES;
	}
	
	for (DTCoreTextLayoutLine *oneLine in lines)
	{
		NSUInteger skipRunsBeforeLocation = 0;
		
		for (DTCoreTextGlyphRun *oneRun in oneLine.glyphRuns)
		{
			// add custom views if necessary
			NSRange runRange = [oneRun stringRange];
			CGRect frameForSubview = CGRectZero;
			
			if (runRange.location>=skipRunsBeforeLocation)
			{
				// see if it's a link
				NSRange effectiveRangeOfLink = runRange;
				
				// make sure that a link is only as long as the area to the next attachment or the current attachment itself
				DTTextAttachment *attachment = oneRun.attributes[NSAttachmentAttributeName];
				
				// if there is no attachment then the effectiveRangeOfAttachment contains the range until the next attachment
				NSURL *linkURL = oneRun.attributes[DTLinkAttribute];
				
				// avoid chaining together glyph runs for an attachment
				if (linkURL && !attachment)
				{
					NSInteger glyphIndex = [oneLine.glyphRuns indexOfObject:oneRun];
					
					// chain together this glyph run with following runs for combined link buttons
					for (NSInteger i=glyphIndex+1; i<[oneLine.glyphRuns count]; i++)
					{
						DTCoreTextGlyphRun *followingRun = oneLine.glyphRuns[i];
						NSURL *followingURL = followingRun.attributes[DTLinkAttribute];
						
						if (![[followingURL absoluteString] isEqualToString:[linkURL absoluteString]])
						{
							// following glyph run has different or no link URL
							break;
						}
						
						if (followingRun.attachment)
						{
							// do not join a following attachment to the combined link
							break;
						}
						
						// extend effective link range
						effectiveRangeOfLink = NSUnionRange(effectiveRangeOfLink, followingRun.stringRange);
					}
					
					// frame for link view includes for all joined glyph runs with same link in this line
					frameForSubview = [oneLine frameOfGlyphsWithRange:effectiveRangeOfLink];
					
					// this following glyph run link attribute is joined to link range
					skipRunsBeforeLocation = NSMaxRange(effectiveRangeOfLink);
				}
				else
				{
					// individual glyph run
					
					if (attachment)
					{
						// frame might be different due to image vertical alignment
						CGFloat ascender = [attachment ascentForLayout];
						CGFloat descender = [attachment descentForLayout];
						
						frameForSubview = CGRectMake(oneRun.frame.origin.x, oneLine.baselineOrigin.y - ascender, oneRun.frame.size.width, ascender+descender);
					}
					else
					{
						frameForSubview = oneRun.frame;
					}
				}
				
				// if there is an attachment then we continue even with empty frame, might be a lazily loaded image
				if ((frameForSubview.size.width<=0 || frameForSubview.size.height<=0) && !attachment)
				{
					continue;
				}
				
				NSNumber *indexKey = [NSNumber numberWithInteger:runRange.location];
				
				// offset layout if necessary
				if (!CGPointEqualToPoint(_layoutOffset, CGPointZero))
				{
					frameForSubview.origin.x += _layoutOffset.x;
					frameForSubview.origin.y += _layoutOffset.y;
				}
				
				// round frame
				frameForSubview.origin.x = floor(frameForSubview.origin.x);
				frameForSubview.origin.y = ceil(frameForSubview.origin.y);
				frameForSubview.size.width = round(frameForSubview.size.width);
				frameForSubview.size.height = round(frameForSubview.size.height);
				
				if (CGRectGetMinY(frameForSubview)> CGRectGetMaxY(rect) || CGRectGetMaxY(frameForSubview) < CGRectGetMinY(rect))
				{
					// is still outside even though the bounds of the line already intersect visible area
					continue;
				}
				
				if (attachment)
				{
					indexKey = [NSNumber numberWithInteger:[attachment hash]];
					NSView *existingAttachmentView = [self.customViewsForAttachmentsIndex objectForKey:indexKey];
					
					if (existingAttachmentView)
					{
						existingAttachmentView.hidden = NO;
						existingAttachmentView.frame = frameForSubview;
						
						existingAttachmentView.alphaValue = 1;
						
						[existingAttachmentView setNeedsLayout:YES];
						[existingAttachmentView setNeedsDisplay:YES];
						
						linkURL = nil; // prevent adding link button on top of image view
					}
					else
					{
						NSView *newCustomAttachmentView = nil;
						
						if ([attachment isKindOfClass:[DTDictationPlaceholderTextAttachment class]])
						{
							newCustomAttachmentView = [[NSView alloc] init];
							newCustomAttachmentView.frame = frameForSubview; // set fixed frame
						}
						else if (_delegateFlags.delegateSupportsCustomViewsForAttachments)
						{
							newCustomAttachmentView = [_delegate attributedTextContentView:self viewForAttachment:attachment frame:frameForSubview];
						}
						else if (_delegateFlags.delegateSupportsGenericCustomViews)
						{
							NSMutableAttributedString *string = [layoutString attributedSubstringFromRange:runRange].mutableCopy;
							[string addAttributes:oneRun.attributes range:NSMakeRange(0, string.length)];
							newCustomAttachmentView = [_delegate attributedTextContentView:self viewForAttributedString:string frame:frameForSubview];
						}
						
						if (newCustomAttachmentView)
						{
							// delegate responsible to set frame
							if (newCustomAttachmentView)
							{
								[self addSubview:newCustomAttachmentView];
								
								[self.customViews addObject:newCustomAttachmentView];
								[self.customViewsForAttachmentsIndex setObject:newCustomAttachmentView forKey:indexKey];
								
								linkURL = nil; // prevent adding link button on top of image view
							}
						}
					}
				}
				
				if (linkURL && (_delegateFlags.delegateSupportsCustomViewsForLinks || _delegateFlags.delegateSupportsGenericCustomViews))
				{
					NSView *existingLinkView = [self.customViewsForLinksIndex objectForKey:indexKey];
					
					// make sure that the frame height is no less than the line height for hyperlinks
					if (frameForSubview.size.height < oneLine.frame.size.height)
					{
						frameForSubview.origin.y = trunc(oneLine.frame.origin.y);
						frameForSubview.size.height = ceil(oneLine.frame.size.height);
					}
					
					if (existingLinkView)
					{
						existingLinkView.frame = frameForSubview;
						existingLinkView.hidden = NO;
					}
					else
					{
						NSView *newCustomLinkView = nil;
						
						// make sure that the frame height is no less than the line height for hyperlinks
						if (frameForSubview.size.height < oneLine.frame.size.height)
						{
							frameForSubview.origin.y = trunc(oneLine.frame.origin.y);
							frameForSubview.size.height = ceil(oneLine.frame.size.height);
						}
						
						if (_delegateFlags.delegateSupportsCustomViewsForLinks)
						{
							NSDictionary *attributes = [layoutString attributesAtIndex:runRange.location effectiveRange:NULL];
							
							NSString *guid = [attributes objectForKey:DTGUIDAttribute];
							newCustomLinkView = [_delegate attributedTextContentView:self viewForLink:linkURL identifier:guid frame:frameForSubview];
						}
						else if (_delegateFlags.delegateSupportsGenericCustomViews)
						{
							NSMutableAttributedString *string = [layoutString attributedSubstringFromRange:runRange].mutableCopy;
							[string addAttributes:oneRun.attributes range:NSMakeRange(0, string.length)];
							newCustomLinkView = [_delegate attributedTextContentView:self viewForAttributedString:string frame:frameForSubview];
						}
						
						// delegate responsible to set frame
						if (newCustomLinkView)
						{
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

- (void)layout
{
	if (!_isTiling && (self.bounds.size.width>1024.0 || self.bounds.size.height>1024.0))
	{
		if (![self.layer isKindOfClass:[CATiledLayer class]])
		{
			NSLog(@"Warning: A %@ with size %@ is using a non-tiled layer. Set the layer class to a CATiledLayer subclass with [DTAttributedTextContentView setLayerClass:[DTTiledLayerWithoutFade class]].", NSStringFromClass([self class]), NSStringFromCGSize(self.bounds.size));
		}
	}
	
	if (_shouldLayoutCustomSubviews)
	{
		[self layoutSubviewsInRect:CGRectInfinite];
	}
  
    [super layout];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	// needs clearing of background
	CGRect rect = CGContextGetClipBoundingBox(ctx);
	
	if (_backgroundOffset.height != 0 || _backgroundOffset.width != 0)
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
	
	DTCoreTextLayoutFrame *theLayoutFrame = self.layoutFrame; // this is synchronized
	
	// construct drawing options
	DTCoreTextLayoutFrameDrawingOptions options = DTCoreTextLayoutFrameDrawingDefault;
	
	if (!_shouldDrawImages)
	{
		options |= DTCoreTextLayoutFrameDrawingOmitAttachments;
	}
	
	if (!_shouldDrawLinks)
	{
		options |= DTCoreTextLayoutFrameDrawingOmitLinks;
	}
	
	if (_delegateFlags.delegateSupportsNotificationBeforeDrawing)
	{
		[_delegate attributedTextContentView:self willDrawLayoutFrame:theLayoutFrame inContext:ctx];
	}
	
	// need to prevent updating of string and drawing at the same time
	[theLayoutFrame drawInContext:ctx options:options];
	
	if (_delegateFlags.delegateSupportsNotificationAfterDrawing)
	{
		[_delegate attributedTextContentView:self didDrawLayoutFrame:theLayoutFrame inContext:ctx];
	}
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	[self.layoutFrame drawInContext:context options:DTCoreTextLayoutFrameDrawingDefault];
}

- (void)relayoutText
{
	DTBlockPerformSyncIfOnMainThreadElseAsync(^{

		// Make sure we actually have a superview and a previous layout before attempting to relayout the text.
		if (_layoutFrame && self.superview)
		{
			// need new layout frame, layouter can remain because the attributed string is probably the same
			self.layoutFrame = nil;
			
			// remove all links because they might have merged or split
			[self removeAllCustomViewsForLinks];
			
			if (_attributedString)
			{
				// triggers new layout
				CGSize neededSize = [self intrinsicContentSize];
				
				CGRect optimalFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, neededSize.width, neededSize.height);
				NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSValue valueWithRect:optimalFrame] forKey:@"OptimalFrame"];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:DTAttributedTextContentViewDidFinishLayoutNotification object:self userInfo:userInfo];
			}
			
			[self setNeedsLayout:YES];
			[self setNeedsDisplayInRect:self.bounds];
			
			if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)])
			{
            [self invalidateIntrinsicContentSize];
			}
		}
	});
}

- (void)removeAllCustomViewsForLinks
{
	NSArray *linkViews = [customViewsForLinksIndex allValues];
	
	for (NSView *customView in linkViews)
	{
		[customView removeFromSuperview];
		[customViews removeObject:customView];
	}
	
	[customViewsForLinksIndex removeAllObjects];
}

- (void)removeAllCustomViews
{
	NSSet *allCustomViews = [NSSet setWithSet:customViews];
	for (NSView *customView in allCustomViews)
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
	for (NSView *customView in allCustomViews)
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

#pragma mark - Sizing

- (void)setBounds:(CGRect)bounds {

    if (!CGSizeEqualToSize(self.bounds.size, bounds.size)) {
        _layoutFrame = nil;
        [self invalidateIntrinsicContentSize];
    }
    [super setBounds:bounds];
}

- (CGSize)intrinsicContentSize
{
	if (!self.layoutFrame) // creates new layout frame if possible
	{
		return CGSizeMake(-1, -1);  // UIViewNoIntrinsicMetric as of iOS 6
	}
	
	//  we have a layout frame and from this we get the needed size
	return CGSizeMake(_layoutFrame.frame.size.width + _edgeInsets.left + _edgeInsets.right, CGRectGetMaxY(_layoutFrame.frame) + _edgeInsets.bottom);
}

- (CGSize)sizeThatFits:(CGSize)size
{
	CGSize neededSize = [self intrinsicContentSize]; // creates layout frame if necessary
	
	if (neededSize.width>=0 && neededSize.height>=0)
	{
		return neededSize;
	}
	
	// return empty size plus padding
	return CGSizeMake(_edgeInsets.left + _edgeInsets.right, _edgeInsets.bottom + _edgeInsets.top);
}

- (CGRect)_frameForLayoutFrameConstraintedToWidth:(CGFloat)constrainWidth
{
	if (!isnormal(constrainWidth))
	{
		constrainWidth = self.bounds.size.width;
	}
	
	CGRect bounds = self.bounds;
	bounds.size.width = constrainWidth;
	CGRect rect = UIEdgeInsetsInsetRect(bounds, _edgeInsets);
	
	if (rect.size.width<=0)
	{
		// cannot create layout frame with negative or zero width
		return CGRectZero;
	}
	
	if (_layoutFrameHeightIsConstrainedByBounds)
	{
		if (rect.size.height<=0)
		{
			// cannot create layout frame with negative or zero height if flexible height is disabled
			return CGRectZero;
		}
		
		// already set height to bounds height
	}
	else
	{
		rect.size.height = CGFLOAT_HEIGHT_UNKNOWN; // necessary height set as soon as we know it.
	}
	
	return rect;
}

- (CGSize)suggestedFrameSizeToFitEntireStringConstraintedToWidth:(CGFloat)width
{
	// create a temporary frame, will be cached by the layouter for the given rect
	CGRect rect = [self _frameForLayoutFrameConstraintedToWidth:width];
	DTCoreTextLayoutFrame *tmpLayoutFrame = [self.layouter layoutFrameWithRect:rect range:NSMakeRange(0, 0)];
	
	// assign current layout frame properties to tmpLayoutFrame
	tmpLayoutFrame.numberOfLines = _numberOfLines;
	tmpLayoutFrame.lineBreakMode = _lineBreakMode;
	tmpLayoutFrame.truncationString = _truncationString;
	
	//  we have a layout frame and from this we get the needed size
	return CGSizeMake(tmpLayoutFrame.frame.size.width + _edgeInsets.left + _edgeInsets.right, CGRectGetMaxY(tmpLayoutFrame.frame) + _edgeInsets.bottom);
}

#pragma mark Properties
- (void)setEdgeInsets:(NSEdgeInsets)edgeInsets
{
	if (!UIEdgeInsetsEqualToEdgeInsets(edgeInsets, _edgeInsets))
	{
		_edgeInsets = edgeInsets;
		
		[self relayoutText];
		
		if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)])
		{
			[self invalidateIntrinsicContentSize];
		}
	}
}

- (void)setAttributedString:(NSAttributedString *)string
{
	if (_attributedString != string)
	{
		// keep the layouter, update string
		self.layouter.attributedString = string;
		
		_attributedString = [string copy];
		
		// only do relayout if there is a previous layout frame and visible
		if (_layoutFrame)
		{
			// new layout invalidates all positions for custom views
			[self removeAllCustomViews];
			
			// relayout only occurs if the view is visible
			[self relayoutText];
		}
		else
		{
			// this is needed or else no lazy layout will be triggered if there is no layout frame yet (before this is added to a superview)
			[self setNeedsLayout:YES];
			[self setNeedsDisplayInRect:self.bounds];
		}
		
		if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)])
		{
			[self invalidateIntrinsicContentSize];
		}
	}
}

- (void)setFrame:(CGRect)frame
{
	CGRect oldFrame = self.frame;
	
	[super setFrame:frame];
	
	if (!_layoutFrame)
	{
		return;
	}
	
	// having a layouter means we are responsible for layouting yourselves
	
	// relayout based on relayoutMask
	
	BOOL shouldRelayout = NO;
	
	if (_relayoutMask & DTAttributedTextContentViewRelayoutOnHeightChanged)
	{
		if (oldFrame.size.height != frame.size.height)
		{
			shouldRelayout = YES;
		}
	}
	
	if (_relayoutMask & DTAttributedTextContentViewRelayoutOnWidthChanged)
	{
		if (oldFrame.size.width != frame.size.width)
		{
			shouldRelayout = YES;
		}
	}
	
	if (shouldRelayout)
	{
		[self relayoutText];
	}
	
	if (oldFrame.size.height < frame.size.height)
	{
		// need to draw the newly visible area
		[self setNeedsDisplayInRect:CGRectMake(0, oldFrame.size.height, self.bounds.size.width, frame.size.height - oldFrame.size.height)];
	}
}

- (void)setShouldAddFirstLineLeading:(BOOL)shouldAddLeading
{
	if (_shouldAddFirstLineLeading != shouldAddLeading)
	{
		_shouldAddFirstLineLeading = shouldAddLeading;
		
		[self setNeedsDisplay:YES];
		
		if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)])
		{
			[self invalidateIntrinsicContentSize];
		}
	}
}

- (void)setShouldDrawImages:(BOOL)shouldDrawImages
{
	if (_shouldDrawImages != shouldDrawImages)
	{
		_shouldDrawImages = shouldDrawImages;
		
		[self setNeedsDisplay:YES];
		
		if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)])
		{
			[self invalidateIntrinsicContentSize];
		}
	}
}

- (void)setShouldDrawLinks:(BOOL)shouldDrawLinks
{
	if (_shouldDrawLinks != shouldDrawLinks)
	{
		_shouldDrawLinks = shouldDrawLinks;
		
		[self setNeedsDisplay:YES];
		
		if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)])
		{
			[self invalidateIntrinsicContentSize];
		}
	}
}

- (void)setBackgroundColor:(DTColor *)newColor
{
	self.wantsLayer = YES;
	_backgroundColor = newColor;
	
	if ([newColor alphaComponent]<1.0)
	{
		self.layer.opaque = NO;
	}
	else
	{
		self.layer.opaque = YES;
	}
}


- (DTCoreTextLayouter *)layouter
{
	@synchronized(self)
	{
		if (!_layouter)
		{
			if (_attributedString)
			{
				_layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:_attributedString];
				
				// allow frame caching if somebody uses the suggestedSize
				_layouter.shouldCacheLayoutFrames = YES;
			}
		}
		
		return _layouter;
	}
}

- (void)setLayouter:(DTCoreTextLayouter *)layouter
{
	@synchronized(self)
	{
		if (_layouter != layouter)
		{
			_layouter = layouter;
		}
	}
}

- (DTCoreTextLayoutFrame *)layoutFrame
{
	@synchronized(self)
	{
		DTCoreTextLayouter *theLayouter = self.layouter;
	
		if (!_layoutFrame)
		{
			// we can only layout if we have our own layouter
			if (theLayouter)
			{
				CGRect rect = UIEdgeInsetsInsetRect(self.bounds, _edgeInsets);
				
				if (rect.size.width<=0)
				{
					// cannot create layout frame with negative or zero width
					return nil;
				}
				
				if (_layoutFrameHeightIsConstrainedByBounds)
				{
					if (rect.size.height<=0)
					{
						// cannot create layout frame with negative or zero height if flexible height is disabled
						return nil;
					}
					
					// height already set
				}
				else
				{
					rect.size.height = CGFLOAT_HEIGHT_UNKNOWN; // necessary height set as soon as we know it.
				}
				
				_layoutFrame = [theLayouter layoutFrameWithRect:rect range:NSMakeRange(0, 0)];
				_layoutFrame.numberOfLines = _numberOfLines;
				_layoutFrame.lineBreakMode = _lineBreakMode;
				_layoutFrame.truncationString = _truncationString;

				// this must have been the initial layout pass
				CGSize neededSize = CGSizeMake(_layoutFrame.frame.size.width + _edgeInsets.left + _edgeInsets.right, CGRectGetMaxY(_layoutFrame.frame) + _edgeInsets.bottom);
				
				CGRect optimalFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, neededSize.width, neededSize.height);
				NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSValue valueWithRect:optimalFrame] forKey:@"OptimalFrame"];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:DTAttributedTextContentViewDidFinishLayoutNotification object:self userInfo:userInfo];
				
				if (_delegateFlags.delegateSupportsNotificationBeforeTextBoxDrawing)
				{
					DT_WEAK_VARIABLE AttributedTextContentView *weakself = self;
					
					[_layoutFrame setTextBlockHandler:^(DTTextBlock *textBlock, CGRect frame, CGContextRef context, BOOL *shouldDrawDefaultBackground) {
						
						AttributedTextContentView *strongself = weakself;
						
						BOOL result = [strongself->_delegate attributedTextContentView:strongself shouldDrawBackgroundForTextBlock:textBlock frame:frame context:context forLayoutFrame:strongself->_layoutFrame];
						
						if (shouldDrawDefaultBackground)
						{
							*shouldDrawDefaultBackground = result;
						}
						
					}];
				}
			}
		}
	
		return _layoutFrame;
	}
}

- (void)setLayoutFrame:(DTCoreTextLayoutFrame *)layoutFrame
{
	@synchronized(self)
	{
		if (_layoutFrame != layoutFrame)
		{
			[self removeAllCustomViewsForLinks];
			
			if (layoutFrame)
			{
				[self setNeedsLayout:YES];
				[self setNeedsDisplayInRect:self.bounds];
			}
			_layoutFrame = layoutFrame;
		}
	};
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

- (void)setDelegate:(id<AttributedTextContentViewDelegate>)delegate
{
	_delegate = delegate;
	
	_delegateFlags.delegateSupportsCustomViewsForAttachments = [_delegate respondsToSelector:@selector(attributedTextContentView:viewForAttachment:frame:)];
	_delegateFlags.delegateSupportsCustomViewsForLinks = [_delegate respondsToSelector:@selector(attributedTextContentView:viewForLink:identifier:frame:)];
	_delegateFlags.delegateSupportsGenericCustomViews = [_delegate respondsToSelector:@selector(attributedTextContentView:viewForAttributedString:frame:)];
	_delegateFlags.delegateSupportsNotificationBeforeDrawing = [_delegate respondsToSelector:@selector(attributedTextContentView:willDrawLayoutFrame:inContext:)];
	_delegateFlags.delegateSupportsNotificationAfterDrawing = [_delegate respondsToSelector:@selector(attributedTextContentView:didDrawLayoutFrame:inContext:)];
	_delegateFlags.delegateSupportsNotificationBeforeTextBoxDrawing = [_delegate respondsToSelector:@selector(attributedTextContentView:shouldDrawBackgroundForTextBlock:frame:context:forLayoutFrame:)];
	
	if (!_delegateFlags.delegateSupportsCustomViewsForLinks && !_delegateFlags.delegateSupportsGenericCustomViews)
	{
		[self removeAllCustomViewsForLinks];
	}
	
	// we don't draw the images if imageViews are provided by the delegate method
	// if you want images to be drawn even though you use custom views, set it back to YES after setting delegate
	if (_delegateFlags.delegateSupportsGenericCustomViews || _delegateFlags.delegateSupportsCustomViewsForAttachments)
	{
		_shouldDrawImages = NO;
	}
	else
	{
		_shouldDrawImages = YES;
	}
}

@synthesize layouter = _layouter;
@synthesize layoutFrame = _layoutFrame;
@synthesize attributedString = _attributedString;
@synthesize delegate = _delegate;
@synthesize edgeInsets = _edgeInsets;
@synthesize shouldDrawImages = _shouldDrawImages;
@synthesize shouldDrawLinks = _shouldDrawLinks;
@synthesize shouldLayoutCustomSubviews = _shouldLayoutCustomSubviews;
@synthesize layoutOffset = _layoutOffset;
@synthesize backgroundOffset = _backgroundOffset;

@synthesize customViews;
@synthesize customViewsForLinksIndex;
@synthesize customViewsForAttachmentsIndex;
@synthesize relayoutMask = _relayoutMask;

@synthesize accessibilityElements = _accessibilityElements;

@end

@implementation AttributedTextContentView (Drawing)

- (NSImage *)contentImageWithBounds:(CGRect)bounds options:(DTCoreTextLayoutFrameDrawingOptions)options
{
	return [NSImage imageWithSize:bounds.size flipped:YES drawingHandler:^BOOL(NSRect dstRect) {
		CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
		if(!context) {
			return NO;
		}

		CGContextTranslateCTM(context, -bounds.origin.x, -bounds.origin.y);

		[self.layoutFrame drawInContext:context options:options];

		return YES;
	}];
}

@end
