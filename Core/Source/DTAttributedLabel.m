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

- (void) setupAttributedLabel
{
	// we want to relayout the text if height or width change
	self.relayoutMask = DTAttributedTextContentViewRelayoutOnHeightChanged | DTAttributedTextContentViewRelayoutOnWidthChanged;
	
	self.layoutFrameHeightIsConstrainedByBounds = YES; // height is not flexible
	self.shouldAddFirstLineLeading = NO;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self)
	{
		[self setupAttributedLabel];
	}
	
	return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[self setupAttributedLabel];
}

#pragma mark - Sizing

- (CGSize)intrinsicContentSize
{
	if (!self.layoutFrame) // creates new layout frame if possible
	{
		return CGSizeMake(-1, -1);  // UIViewNoIntrinsicMetric as of iOS 6
	}
	
	//  we have a layout frame and from this we get the needed size
	CGSize intrisicContentSize = [_layoutFrame intrinsicContentFrame].size;
	return CGSizeMake(intrisicContentSize.width + _edgeInsets.left + _edgeInsets.right,
					  intrisicContentSize.height + _edgeInsets.top + _edgeInsets.bottom);
}

#pragma mark - Properties 

- (NSInteger)numberOfLines
{
	return _numberOfLines;
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    if (numberOfLines != _numberOfLines)
    {
        _numberOfLines = numberOfLines;
        [self relayoutText];
    }
}

- (NSLineBreakMode)lineBreakMode
{
	return _lineBreakMode;
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    if (lineBreakMode != _lineBreakMode)
    {
        _lineBreakMode = lineBreakMode;
        [self relayoutText];
    }
}

- (NSAttributedString*)truncationString
{
	return _truncationString;
}

- (void)setTruncationString:(NSAttributedString *)truncationString
{
    if (![truncationString isEqualToAttributedString:_truncationString])
    {
        _truncationString = truncationString;
        [self relayoutText];
    }
}


@end
