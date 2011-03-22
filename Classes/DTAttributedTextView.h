//
//  DTAttributedTextView.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextContentView.h"

@class DTAttributedTextView;

@interface DTAttributedTextView : UIScrollView <DTAttributedTextContentViewDelegate>
{
	DTAttributedTextContentView *contentView;
	UIView *backgroundView;
}

@property (nonatomic, retain) NSAttributedString *attributedString;

@property (nonatomic, readonly) DTAttributedTextContentView *contentView;
@property (nonatomic, retain) UIView *backgroundView;

@end
