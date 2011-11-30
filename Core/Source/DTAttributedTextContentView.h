//
//  TextView.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreText/CoreText.h>

#import "NSAttributedString+HTML.h"

#import "DTCoreTextLayouter.h"
#import "DTTextAttachment.h"

#ifndef __IPHONE_4_3
#define __IPHONE_4_3 40300
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_3

#define LAYOUTSTRING layoutLock
#define LAYOUTER layouterLock
#define LAYOUTFRAME layoutFrameLock
#define SELF selfLock

#define SYNCHRONIZE_START(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define SYNCHRONIZE_END(lock) dispatch_semaphore_signal(lock);

#else

#define LAYOUTSTRING self
#define LAYOUTER self
#define LAYOUTFRAME self
#define SELF self

#define SYNCHRONIZE_START(obj) @synchronized(obj)
#define SYNCHRONIZE_END(obj)

#endif


@class DTAttributedTextContentView;
@class DTCoreTextLayoutFrame;

@protocol DTAttributedTextContentViewDelegate <NSObject>

@optional

// called after a layout frame or a part of it is drawn
- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView didDrawLayoutFrame:(DTCoreTextLayoutFrame *)layoutFrame inContext:(CGContextRef)context;

// provide custom view for an attachment, e.g. an imageView for images
- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame;

// provide button to be placed over links, the identifier is used to link multiple parts of the same A tag
- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForLink:(NSURL *)url identifier:(NSString *)identifier frame:(CGRect)frame;

// old style
- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame;

@end



@interface DTAttributedTextContentView : UIView 
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
	
	id <DTAttributedTextContentViewDelegate> _delegate;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString width:(CGFloat)width;

- (void)layoutSubviewsInRect:(CGRect)rect;
- (void)relayoutText;
- (void)removeAllCustomViews;
- (void)removeAllCustomViewsForLinks;

- (CGSize)attributedStringSizeThatFits:(CGFloat)width;

@property (retain) DTCoreTextLayouter *layouter;
@property (retain) DTCoreTextLayoutFrame *layoutFrame;

@property (nonatomic, retain) NSMutableSet *customViews;

@property (nonatomic, copy) NSAttributedString *attributedString;
@property (nonatomic) UIEdgeInsets edgeInsets;
@property (nonatomic) BOOL drawDebugFrames;
@property (nonatomic) BOOL shouldDrawImages;
@property (nonatomic) BOOL shouldLayoutCustomSubviews;
@property (nonatomic) CGPoint layoutOffset;
@property (nonatomic) CGSize backgroundOffset;

@property (nonatomic, assign) IBOutlet id <DTAttributedTextContentViewDelegate> delegate;


@end


@interface DTAttributedTextContentView (Tiling)

+ (void)setLayerClass:(Class)layerClass;
+ (Class)layerClass;

@end

