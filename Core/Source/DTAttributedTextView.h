//
//  DTAttributedTextView.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextContentView.h"

@class DTAttributedTextView;

@interface DTAttributedTextView : UIScrollView
{
	DTAttributedTextContentView *contentView;
	UIView *backgroundView;
}

@property (nonatomic, strong) NSAttributedString *attributedString;

@property (nonatomic, strong, readonly) DTAttributedTextContentView *contentView;
@property (nonatomic, strong) IBOutlet UIView *backgroundView;

@property (nonatomic, unsafe_unretained) IBOutlet id <DTAttributedTextContentViewDelegate> textDelegate;


/**
 Scrolls the receiver to the anchor with the given name to the top.
 @param anchorName The name of the href anchor.
 @param animated `YES` if the movement should be animated.
 */
- (void)scrollToAnchorNamed:(NSString *)anchorName animated:(BOOL)animated;

@end
