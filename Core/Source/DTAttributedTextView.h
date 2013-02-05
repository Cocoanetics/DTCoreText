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

/**
 The attributed text to be displayed in the text content view of the receiver.
 */
@property (nonatomic, strong) NSAttributedString *attributedString;

/**
 References to the DTAttributedTextContentView that display the text. This is not named contentView because this class inherits from `UIScrollView` which has an internal property of this name
 */
@property (nonatomic, strong, readonly) DTAttributedTextContentView *attributedTextContentView;

/**
 A view to be displayed behind the text content view
 */
@property (nonatomic, strong) IBOutlet UIView *backgroundView;

/**
 A delegate implementing DTAttributedTextContentViewDelegate to provide custom subviews for images and links.
 */
@property (nonatomic, unsafe_unretained) IBOutlet id <DTAttributedTextContentViewDelegate> textDelegate;

/**
 If the content view of the receiver should draw links. Set to `NO` if displaying links as custom views via textDelegate;
 */
@property (nonatomic, assign) BOOL shouldDrawLinks;

/**
 Scrolls the receiver to the anchor with the given name to the top.
 @param anchorName The name of the href anchor.
 @param animated `YES` if the movement should be animated.
 */
- (void)scrollToAnchorNamed:(NSString *)anchorName animated:(BOOL)animated;

@end
