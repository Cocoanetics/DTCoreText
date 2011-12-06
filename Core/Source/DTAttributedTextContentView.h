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
- (id)initWithAttributedString:(NSAttributedString *)attributedString width:(CGFloat)width;

- (void)layoutSubviewsInRect:(CGRect)rect;
- (void)relayoutText;
- (void)removeAllCustomViews;
- (void)removeAllCustomViewsForLinks;

- (CGSize)attributedStringSizeThatFits:(CGFloat)width;
- (CGSize)suggestedFrameSizeToFitEntireStringConstraintedToWidth:(CGFloat)width; // obeys the edge insets

// properties are overwritten with locking to avoid problem with async drawing
@property (atomic, strong) DTCoreTextLayouter *layouter;
@property (atomic, strong) DTCoreTextLayoutFrame *layoutFrame;

@property (nonatomic, strong) NSMutableSet *customViews;

@property (nonatomic, copy) NSAttributedString *attributedString;
@property (nonatomic) UIEdgeInsets edgeInsets;
@property (nonatomic) BOOL drawDebugFrames;
@property (nonatomic) BOOL shouldDrawImages;
@property (nonatomic) BOOL shouldLayoutCustomSubviews;
@property (nonatomic) CGPoint layoutOffset;
@property (nonatomic) CGSize backgroundOffset;

@property (nonatomic, assign) IBOutlet id <DTAttributedTextContentViewDelegate> delegate;	// subtle simulator bug - use assign not __unsafe_unretained

@property (nonatomic, assign) dispatch_semaphore_t selfLock;


@end


@interface DTAttributedTextContentView (Tiling)

+ (void)setLayerClass:(Class)layerClass;
+ (Class)layerClass;

@end

