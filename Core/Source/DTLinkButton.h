//
//  DTLinkButton.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/16/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

/**
 Constant for highlighting notification
 */

extern NSString *DTLinkButtonDidHighlightNotification;

/**
 A button that corresponds to a hyperlink.
 
 Multiple parts of the same hyperlink synchronize their looks through the guid.
 */
@interface DTLinkButton : UIButton 


/**
 The URL that this button corresponds to.
 */
@property (nonatomic, copy) NSURL *URL;


/**
 The unique identifier (GUID) that all parts of the same hyperlink have in common.
 */
@property (nonatomic, copy) NSString *GUID;


/**
 The minimum size that the receiver should respond on hits with. Adjusts the bounds if they are smaller than the passed size.
 */
@property (nonatomic, assign) CGSize minimumHitSize;


/**
 A Boolean value that determines whether tapping the button causes it to show a gray rounded rectangle. Default is YES.
 */
@property(nonatomic) BOOL showsTouchWhenHighlighted;

/**
 The attributed string to be drawn for the link button.
 */
@property (nonatomic, retain) NSAttributedString *attributedString;


/**
 The attributed string to be drawn for the link button while it is highlighted.
 */
@property (nonatomic, retain) NSAttributedString *highlightedAttributedString;

@end
