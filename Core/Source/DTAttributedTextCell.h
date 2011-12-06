//
//  DTAttributedTextCell.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 8/4/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@class DTAttributedTextContentView;

@interface DTAttributedTextCell : UITableViewCell

@property (nonatomic, strong) NSAttributedString *attributedString;
@property (nonatomic, readonly) DTAttributedTextContentView *attributedTextContextView;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier accessoryType:(UITableViewCellAccessoryType)accessoryType;

- (void)setHTMLString:(NSString *)html;

- (CGFloat)requiredRowHeightInTableView:(UITableView *)tableView;

@end
