//
//  TextView.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreText/CoreText.h>

#import "NSAttributedString+HTML.h"

@class DTAttributedTextView;


@interface DTAttributedTextContentView : UIView {
	CTFramesetterRef framesetter;
	CTFrameRef textFrame;
	
	NSAttributedString *_attributedString;
	
	DTAttributedTextView *parentView;
	
	UIEdgeInsets edgeInsets;
}


- (void)relayoutText;

@property (nonatomic, readonly) CTFramesetterRef framesetter;
@property (nonatomic, readonly) CTFrameRef textFrame;

@property (retain) NSAttributedString *attributedString;
@property (nonatomic) UIEdgeInsets edgeInsets;

@property (nonatomic, assign) DTAttributedTextView *parentView;

@end
