//
//  TextView.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>


@interface DTAttributedTextContentView : UIView {
	CTFramesetterRef framesetter;
	CTFrameRef textFrame;
	
	NSAttributedString *_string;
}

@property (nonatomic, readonly) CTFramesetterRef framesetter;
@property (nonatomic, readonly) CTFrameRef textFrame;

@property (nonatomic, retain) NSAttributedString *string;


@end
