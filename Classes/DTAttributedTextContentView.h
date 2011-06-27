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

@class DTAttributedTextContentView;
@class DTCoreTextLayoutFrame;

@protocol DTAttributedTextContentViewDelegate <NSObject>

@optional

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame;
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
    
    id <DTAttributedTextContentViewDelegate> _delegate;
	BOOL _delegateSupportsCustomViewsForAttachments;
	BOOL _delegateSupportsCustomViewsForLinks;
	BOOL _delegateSupportsGenericCustomViews;
	
	BOOL _isTiling;
	
	DTCoreTextLayouter *_layouter;
	DTCoreTextLayoutFrame *_layoutFrame;
	
	CGPoint _layoutOffset;
    CGSize _backgroundOffset;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString width:(CGFloat)width;

- (void)layoutSubviewsInRect:(CGRect)rect;
- (void)relayoutText;
- (void)removeAllCustomViews;

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

