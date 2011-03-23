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

@class DTAttributedTextContentView;

@protocol DTAttributedTextContentViewDelegate <NSObject>

@optional

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame;

@end



@interface DTAttributedTextContentView : UIView 
{
	NSAttributedString *_attributedString;
	UIEdgeInsets edgeInsets;
	DTCoreTextLayouter *layouter;
	BOOL drawDebugFrames;
	NSMutableSet *customViews;
    
    id <DTAttributedTextContentViewDelegate> delegate;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString width:(CGFloat)width;
- (void)relayoutText;

@property (nonatomic, retain) DTCoreTextLayouter *layouter;
@property (nonatomic, retain) NSMutableSet *customViews;

@property (nonatomic, copy) NSAttributedString *attributedString;
@property (nonatomic) UIEdgeInsets edgeInsets;
@property (nonatomic) BOOL drawDebugFrames;


@property (nonatomic, assign) id <DTAttributedTextContentViewDelegate> delegate;




@end


@interface DTAttributedTextContentView (Tiling)

+ (void)setLayerClass:(Class)layerClass;
+ (Class)layerClass;

@end

