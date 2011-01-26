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

@class DTAttributedTextView;


@interface DTAttributedTextContentView : UIView 
{
	NSAttributedString *_attributedString;
	
	DTAttributedTextView *parentView;
	
	UIEdgeInsets edgeInsets;
	
	DTCoreTextLayouter *layouter;
	
	BOOL drawDebugFrames;
	
	NSMutableSet *customViews;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString width:(CGFloat)width;
- (void)relayoutText;

@property (nonatomic, readonly, retain) DTCoreTextLayouter *layouter;

@property (nonatomic, copy) NSAttributedString *attributedString;
@property (nonatomic) UIEdgeInsets edgeInsets;
@property (nonatomic) BOOL drawDebugFrames;


@property (nonatomic, assign) DTAttributedTextView *parentView;



@end
