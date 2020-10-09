//
//  DTAttributedTextView.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCompatibility.h"

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

#import <UIKit/UIKit.h>

#import "DTAttributedTextContentView.h"

@class DTAttributedTextView;

/**
 This view is designed to be a replacement for `UITextView`. It is a `UIScrollView` subclass and creates a <DTAttributedTextContentView> as content view for displaying the text.
 
 The content view of type <DTAttributedTextContentView> is created lazily. You should not set values on it directly if you use it in conjunction with this class for scrolling.
 */

@interface DTAttributedTextView : UIScrollView
{
	// ivars needed by subclasses
	DTAttributedTextContentView *_attributedTextContentView;
}

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
@property (nonatomic, DT_WEAK_PROPERTY) IBOutlet id <DTAttributedTextContentViewDelegate> textDelegate;


/**
 Performs a new layout pass on the receiver. This destroys the frame setter, calls relayoutText on the content view and marks the receiver as needing layout so that custom subviews get appropriately sized.
 */
- (void)relayoutText;

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
 @name Customizing Content View
 */

/**
 You can override this method to provide a different class to use for the content view. If you replace the content view class then it should inherit from <DTAttributedTextContentView> which is also the default.
 @returns The class to use for the content view.
 */
- (Class)classForContentView;

/**
 @name User Interaction
 */

/**
 Scrolls the receiver to the anchor with the given name to the top.
 @param anchorName The name of the href anchor.
 @param animated `YES` if the movement should be animated.
 */
- (void)scrollToAnchorNamed:(NSString *)anchorName animated:(BOOL)animated;

/**
 Scrolls the receiver until the text in the specified range is visible.
 @param range The range of text to scroll into view.
 @param animated `YES` if the movement should be animated.
 */
- (void)scrollRangeToVisible:(NSRange)range animated:(BOOL)animated;

/**
 @name Working with a Cursor
 */

/**
 Determines the closest string index to a point in the receiver's frame.
 
 This can be used to find the cursor position to position an input caret at.
 @param point The point
 @returns The resulting string index
 */
- (NSInteger)closestCursorIndexToPoint:(CGPoint)point;

/**
 The rectangle to draw a caret for a given index
 @param index The string index for which to determine a cursor frame
 @returns The cursor rectangle
 */
- (CGRect)cursorRectAtIndex:(NSInteger)index;

@end

#endif
