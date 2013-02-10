//
//  DTAttributedTextCell.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 8/4/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@class DTAttributedTextContentView;

/**
 This class represents a tableview cell that contains an attributed text as its content.
 */
@interface DTAttributedTextCell : UITableViewCell

/**
 @name Creating Cells
 */

/**
 Creates a tableview cell with a given reuse identifier. 
 
 Because this determines the space available for the text the accessory type of the cell needs also be passed.
 @param reuseIdentifier The reuse identifier to use for the cell
 @param accessoryType The accessory type to use
 @returns A prepared cell
 */
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier accessoryType:(UITableViewCellAccessoryType)accessoryType;

/**
 @name Setting Attributed Content
 */

/**
 The attributed string content of the receiver
 */
@property (nonatomic, strong) NSAttributedString *attributedString;


/**
 This method allows to set HTML text directly as content of the receiver. 
 
 This will be converted to an attributed string.
 @param html The HTML string to set as the receiver's text content
 */
- (void)setHTMLString:(NSString *)html;


/**
 @name Getting Information
 */

/**
 Determines the row height that is needed in a specific table view to show the entire text content. 
 
 The table view is necessary because from this the method can know the
 @param tableView The table view to determine the height for.
 */
- (CGFloat)requiredRowHeightInTableView:(UITableView *)tableView;

/**
 The attributed text content view that the receiver uses to display the attributed text content.
 */
@property (nonatomic, readonly) DTAttributedTextContentView *attributedTextContextView;

@end
