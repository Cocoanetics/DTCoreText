//
//  DTAttributedTextCell.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 8/4/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DTAttributedTextContentView;

@interface DTAttributedTextCell : UITableViewCell
{
	NSAttributedString *_attributedString;
	DTAttributedTextContentView *_attributedTextContextView;
	
	NSUInteger _htmlHash; // preserved hash to avoid relayouting for same HTML
}

@property (nonatomic, retain) NSAttributedString *attributedString;
@property (nonatomic, readonly) DTAttributedTextContentView *attributedTextContextView;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier accessoryType:(UITableViewCellAccessoryType)accessoryType;

- (void)setHTMLString:(NSString *)html;

@end
