//
//  TextView.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreText/CoreText.h>

@class DTAttributedTextView;


@interface DTAttributedTextContentView : UIView {
	CTFramesetterRef framesetter;
	CTFrameRef textFrame;
	
	NSAttributedString *_string;
	
	DTAttributedTextView *parentView;
	
	UIEdgeInsets edgeInsets;
}

@property (nonatomic, readonly) CTFramesetterRef framesetter;
@property (nonatomic, readonly) CTFrameRef textFrame;

@property (nonatomic, retain) NSAttributedString *string;

@property (nonatomic, assign) DTAttributedTextView *parentView;

@end
