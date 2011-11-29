//
//  DTMutableCoreTextLayoutFrame.h
//  DTRichTextEditor
//
//  Created by Oliver Drobnik on 11/23/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//

#import "DTCoreTextLayoutFrame.h"

@interface DTMutableCoreTextLayoutFrame : DTCoreTextLayoutFrame
{
	UIEdgeInsets _edgeInsets; // space between frame edges and text
}

// default initializer
- (id)initWithFrame:(CGRect)frame attributedString:(NSAttributedString *)attributedString;

- (void)relayoutText;

// replace the entire current string
- (void)setAttributedString:(NSAttributedString *)attributedString;

// incremental layouting
- (void)replaceTextInRange:(NSRange)range withText:(NSAttributedString *)text;

- (void)setFrame:(CGRect)frame;


@end
