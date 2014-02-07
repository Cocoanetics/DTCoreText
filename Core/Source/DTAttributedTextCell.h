//
//  DTAttributedTextCell.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 8/4/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextContentView.h"
#import "DTWeakSupport.h"

/**
 This class represents a tableview cell that contains an attributed text as its content.
 */
@interface DTAttributedTextCell : UITableViewCell

/**
 @name Creating Cells
 */

/**
 Creates a tableview cell with a given reuse identifier. 
 @param reuseIdentifier The reuse identifier to use for the cell
 @returns A prepared cell
 */
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

/**
 @name Setting Attributed Content
 */

/**
 The attributed string content of the receiver
 */
@property (nonatomic, strong) NSAttributedString *attributedString;

/**
 A delegate implementing DTAttributedTextContentViewDelegate to provide custom subviews for images and links.
 */
@property (nonatomic, DT_WEAK_PROPERTY) IBOutlet id <DTAttributedTextContentViewDelegate> textDelegate;

/**
 This method allows to set HTML text directly as content of the receiver. 
 
 This will be converted to an attributed string.
 @param html The HTML string to set as the receiver's text content
 */
- (void)setHTMLString:(NSString *)html;

/**
 This method allows to set HTML text directly as content of the receiver.
 
 This will be converted to an attributed string.
 @param html The HTML string to set as the receiver's text content
 @param options The options used for rendering the HTML
 */
- (void) setHTMLString:(NSString *)html options:(NSDictionary*) options;


/**
 @name Getting Information
 */

/**
 Determines the row height that is needed in a specific table view to show the entire text content. 
 
 The table view is necessary because from this the method can know the style. Also the accessory type needs to be set before calling this method because this reduces the available space.
 @note This value is only useful for table views with variable row height.
 @param tableView The table view to determine the height for.
 */
- (CGFloat)requiredRowHeightInTableView:(UITableView *)tableView;

/**
 Determines whether the cells built-in contentView is allowed to dictate the size available for text. If active then attributedTextContextView's height always matches the cell height.
 
 Set this to `YES` for use in fixed row height table views, leave it `NO` for flexible row height table views.
 */
@property (nonatomic, assign) BOOL hasFixedRowHeight;

/**
 The attributed text content view that the receiver uses to display the attributed text content.
 */
@property (nonatomic, readonly) DTAttributedTextContentView *attributedTextContextView;

@end
