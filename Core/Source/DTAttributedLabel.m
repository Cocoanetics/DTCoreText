//
//  DTAttributedLabel.m
//  DTCoreText
//
//  Created by Brian Kenny on 1/17/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTAttributedLabel.h"
#import "DTCoreTextLayoutFrame.h"
#import <QuartzCore/QuartzCore.h>

@implementation DTAttributedLabel

+ (Class)layerClass
{
	// most likely the label will be less than a screen size and so we don't want any tiling behavior
	return [CALayer class];
}

- (DTCoreTextLayoutFrame *)layoutFrame
{
    self.layoutFrameHeightIsConstrainedByBounds = YES; // height is not flexible
	DTCoreTextLayoutFrame * layoutFrame = [super layoutFrame];
    layoutFrame.numberOfLines = self.numberOfLines;
    layoutFrame.lineBreakMode = self.lineBreakMode;
    layoutFrame.truncationString = self.truncationString;
	layoutFrame.noLeadingOnFirstLine = YES;
	return layoutFrame;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self)
	{
		// we want to relayout the text if height or width change
		self.relayoutMask = DTAttributedTextContentViewRelayoutOnHeightChanged | DTAttributedTextContentViewRelayoutOnWidthChanged;
	}
	
	return self;
}

#pragma mark - Sizing

- (CGSize)intrinsicContentSize
{
	if (!self.layoutFrame) // creates new layout frame if possible
	{
		return CGSizeMake(-1, -1);  // UIViewNoIntrinsicMetric as of iOS 6
	}
	
	//  we have a layout frame and from this we get the needed size
	return [_layoutFrame intrinsicContentFrame].size;
}

#pragma mark - Properties 

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    if (numberOfLines != _numberOfLines)
    {
        _numberOfLines = numberOfLines;
        [self relayoutText];
    }
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    if (lineBreakMode != _lineBreakMode)
    {
        _lineBreakMode = lineBreakMode;
        [self relayoutText];
    }
}

- (void)setTruncationString:(NSAttributedString *)trunctionString
{
    if (trunctionString != _truncationString)
    {
        _truncationString = trunctionString;
        [self relayoutText];
    }
}

@synthesize numberOfLines = _numberOfLines;
@synthesize lineBreakMode = _lineBreakMode;
@synthesize truncationString = _truncationString;

@end
