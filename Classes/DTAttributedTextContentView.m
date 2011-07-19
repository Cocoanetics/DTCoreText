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

@interface DTAttributedTextContentView ()

@property (nonatomic, retain) NSMutableDictionary *customViewsForLinksIndex;
@property (nonatomic, retain) NSMutableDictionary *customViewsForAttachmentsIndex;

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

- (void)setup
{
	self.contentMode = UIViewContentModeTopLeft; // to avoid bitmap scaling effect on resize
	shouldLayoutCustomSubviews = YES;
	
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
	[customViewsForLinksIndex release];
	[customViewsForAttachmentsIndex release];
	
	[_layouter release];
	[_layoutFrame release];
	[_attributedString release];
	
	[super dealloc];
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
	
	
	NSAttributedString *layoutString = self.layoutFrame.layouter.attributedString;
	
	@synchronized(layoutString)
	{
		NSArray *lines;
		if (CGRectIsInfinite(rect))
		{
			lines = [self.layoutFrame lines];
		}
		else
		{
			lines = [self.layoutFrame linesVisibleInRect:rect];
		}
		
		// hide all customViews
		for (UIView *view in self.customViews)
		{
			view.hidden = YES;
		}
		
		for (DTCoreTextLayoutLine *oneLine in lines)
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
					
					if (_delegateSupportsCustomViewsForAttachments || _delegateSupportsGenericCustomViews)
					{
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
							
							DTTextAttachment *attachment = oneRun.attachment;
							
							if (attachment)
							{
								if (_delegateSupportsCustomViewsForAttachments)
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
										newCustomAttachmentView.tag = stringRange.location;
										[self addSubview:newCustomAttachmentView];
										
										[self.customViews addObject:newCustomAttachmentView];
										[self.customViewsForAttachmentsIndex setObject:newCustomAttachmentView forKey:indexKey];
										
										linkURL = nil; // prevent adding link button on top of image view
									}
								}
							}
						}
					}
					
					
					if (linkURL && (_delegateSupportsCustomViewsForLinks || _delegateSupportsGenericCustomViews))
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
							
							if (_delegateSupportsCustomViewsForLinks)
							{
								NSDictionary *attributes = [layoutString attributesAtIndex:stringRange.location effectiveRange:NULL];
								
								NSString *guid = [attributes objectForKey:@"DTGUID"];
								newCustomLinkView = [_delegate attributedTextContentView:self viewForLink:linkURL identifier:guid frame:frameForSubview];
							}
							else if (_delegateSupportsGenericCustomViews)
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
	
	// need to prevent updating of string and drawing at the same time
	@synchronized(self.layoutFrame.layouter.attributedString)
	{
		[self.layoutFrame drawInContext:ctx drawImages:shouldDrawImages];
	}
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
	
	// this returns an incorrect size before 4.2
	//	CGSize neededSize = [self.layouter suggestedFrameSizeToFitEntireStringConstraintedToWidth:size.width-edgeInsets.left-edgeInsets.right];
	
	return neededSize;
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
	// need new layouter
	self.layouter = nil;
	self.layoutFrame = nil;
	
	// remove custom views
	[self removeAllCustomViewsForLinks];
	
	if (_attributedString)
	{
		// triggers new layout
		CGSize neededSize = [self sizeThatFits:self.bounds.size];
		
		// set frame to fit text preserving origin
		self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, neededSize.width, neededSize.height);
	}
	
	[self setNeedsDisplay];
	[self setNeedsLayout];
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
		[_attributedString release];
		
		_attributedString = [string copy];
		
		[self relayoutText];
	}
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	
	if (!_layoutFrame) 
	{
		return;	
	}
	
	CGSize sizeThatFits = [self sizeThatFits:self.bounds.size];
	
	if (!CGSizeEqualToSize(frame.size, sizeThatFits))
	{
		if (_layouter)
		{
			// layouter means we are responsible for layouting yourselves
			[self relayoutText];
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
	@synchronized(_layouter)
	{
		if (!_layouter)
		{
			if (_attributedString)
			{
				_layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:_attributedString];
			}
		}
		
		return _layouter;
	}
}

- (void)setLayouter:(DTCoreTextLayouter *)layouter
{
	@synchronized(layouter)
	{
		if (_layouter != layouter)
		{
			[_layouter release];
			_layouter = [layouter retain];
		}
	}
}

- (DTCoreTextLayoutFrame *)layoutFrame
{
	@synchronized(_layoutFrame)
	{
		if (!_layoutFrame)
		{
			// we can only layout if we have our own layouter
			if (self.layouter)
			{
				CGRect rect = UIEdgeInsetsInsetRect(self.bounds, edgeInsets);
				rect.size.height = CGFLOAT_OPEN_HEIGHT; // necessary height set as soon as we know it.
				
				_layoutFrame = [self.layouter layoutFrameWithRect:rect range:NSMakeRange(0, 0)];
				[_layoutFrame retain];
			}
		}
		return _layoutFrame;
	}
}

- (void)setLayoutFrame:(DTCoreTextLayoutFrame *)layoutFrame
{
	@synchronized(layoutFrame)
	{
		if (_layoutFrame != layoutFrame)
		{
			[_layoutFrame release];
			
			_layoutFrame = [layoutFrame retain];
			
			[self removeAllCustomViewsForLinks];
			
			if (layoutFrame)
			{
				[self setNeedsLayout];
				[self setNeedsDisplay];
			}
		}
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
	
	_delegateSupportsCustomViewsForAttachments = [_delegate respondsToSelector:@selector(attributedTextContentView:viewForAttachment:frame:)];
	_delegateSupportsCustomViewsForLinks = [_delegate respondsToSelector:@selector(attributedTextContentView:viewForLink:identifier:frame:)];
	_delegateSupportsGenericCustomViews = [_delegate respondsToSelector:@selector(attributedTextContentView:viewForAttributedString:frame:)]; 
	
	if (!_delegateSupportsCustomViewsForLinks && ! _delegateSupportsCustomViewsForAttachments && ! _delegateSupportsGenericCustomViews)
	{
		[self removeAllCustomViews];
	}
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
