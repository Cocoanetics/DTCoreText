//
//  DTAttributedLabel.m
//  DTCoreText
//
//  Created by Brian Kenny on 1/17/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTAttributedLabel.h"
#import "DTCoreTextLayoutFrame.h"

@implementation DTAttributedLabel

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

- (void)sizeToFit
{
	CGSize size = [self suggestedFrameSizeToFitEntireStringConstraintedToWidth:CGFLOAT_OPEN_HEIGHT];
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, size.width, size.height);
}

@synthesize numberOfLines = _numberOfLines;
@synthesize lineBreakMode = _lineBreakMode;
@synthesize truncationString = _truncationString;

@end
