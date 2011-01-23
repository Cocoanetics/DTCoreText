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
	UIView *backgroundView;
	
	id <DTAttributedTextViewDelegate> textDelegate;
}

@property (nonatomic, retain) NSAttributedString *attributedString;

@property (nonatomic, readonly) DTAttributedTextContentView *contentView;
@property (nonatomic, retain) UIView *backgroundView;

@property (nonatomic, assign) id <DTAttributedTextViewDelegate> textDelegate;

@end
