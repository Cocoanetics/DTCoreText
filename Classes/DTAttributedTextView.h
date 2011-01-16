//
//  DTAttributedTextView.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@class DTAttributedTextContentView, DTAttributedTextView;


@protocol DTAttributedTextViewDelegate <NSObject>

@optional

- (UIView *)attributedTextView:(DTAttributedTextView *)attributedTextView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame;

@end


@interface DTAttributedTextView : UIScrollView 
{
	DTAttributedTextContentView *contentView;
	
	id <DTAttributedTextViewDelegate> textDelegate;
}

@property (nonatomic, retain) NSAttributedString *string;

@property (nonatomic, readonly) DTAttributedTextContentView *contentView;

@property (nonatomic, assign) id <DTAttributedTextViewDelegate> textDelegate;

@end
