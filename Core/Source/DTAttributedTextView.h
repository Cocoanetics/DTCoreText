//
//  DTAttributedTextView.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextContentView.h"

@class DTAttributedTextView;

/**
 This view is designed to be a replacement for `UITextView`. It is a `UIScrollView` subclass and creates a <DTAttributedTextContentView> as content view for displaying the text
 */

@interface DTAttributedTextView : UIScrollView

/**
 @name Providing Content
 */

/**
 The attributed text to be displayed in the text content view of the receiver.
 */
@property (nonatomic, strong) NSAttributedString *attributedString;


/**
 A delegate implementing DTAttributedTextContentViewDelegate to provide custom subviews for images and links.
 */
@property (nonatomic, unsafe_unretained) IBOutlet id <DTAttributedTextContentViewDelegate> textDelegate;


/**
 @name Accessing Subviews
 */

/**
 References to the DTAttributedTextContentView that display the text. This is not named contentView because this class inherits from `UIScrollView` which has an internal property of this name
 */
@property (nonatomic, strong, readonly) DTAttributedTextContentView *attributedTextContentView;

/**
 A view to be displayed behind the text content view
 */
@property (nonatomic, strong) IBOutlet UIView *backgroundView;


/**
 @name Customizing Display
 */

/**
 If the content view of the receiver should draw links. Set to `NO` if displaying links as custom views via textDelegate;
 
 Defaults to `YES` if you supply your own link drawing  then set this property to NO and supply your custom view (e.g. <DTLinkButton>) via the <textDelegate>.
 */
@property (nonatomic, assign) BOOL shouldDrawLinks;

/**
 If the content view of the receiver should draw images. Set to `NO` if displaying images as custom views via textDelegate;
 
 Defaults to `YES` if you supply your own image drawing then set this property to NO and supply your custom image view (e.g. <DTLazyImageView>) via the <textDelegate>.
 */
@property (nonatomic, assign) BOOL shouldDrawImages;

/**
 @name User Interaction
 */

/**
 Scrolls the receiver to the anchor with the given name to the top.
 @param anchorName The name of the href anchor.
 @param animated `YES` if the movement should be animated.
 */
- (void)scrollToAnchorNamed:(NSString *)anchorName animated:(BOOL)animated;

@end
