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

@synthesize numberOfLines = _numberOfLines;
@synthesize lineBreakMode = _lineBreakMode;
@synthesize truncationString = _truncationString;

- (DTCoreTextLayoutFrame *)layoutFrame
{
    _flexibleHeight = NO;
	DTCoreTextLayoutFrame * layoutFrame = [super layoutFrame];
    layoutFrame.numberOfLines = self.numberOfLines;
    layoutFrame.lineBreakMode = self.lineBreakMode;
    layoutFrame.truncationString = self.truncationString;
	return layoutFrame;
}


- (void)setNumberOfLines:(int)numLines
{
    if (numLines != _numberOfLines)
    {
        _numberOfLines = numLines;
        [self relayoutText];
    }
}

- (void)setLineBreakMode:(NSLineBreakMode)mode
{
    if (mode != _lineBreakMode)
    {
        _lineBreakMode = mode;
        [self relayoutText];
    }
}
- (void)setTruncationString:(NSAttributedString *)str
{
    if (str != _truncationString)
    {
        _truncationString = str;
        [self relayoutText];
    }
}

@end
