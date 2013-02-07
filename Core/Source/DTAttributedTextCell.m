//
//  DTAttributedTextCell.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 8/4/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"
#import "DTAttributedTextCell.h"
#import "DTCSSStylesheet.h"

@implementation DTAttributedTextCell
{
	DTAttributedTextContentView *_attributedTextContextView;
	
	NSUInteger _htmlHash; // preserved hash to avoid relayouting for same HTML
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier accessoryType:(UITableViewCellAccessoryType)accessoryType
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self)
	{
		// don't know size jetzt because there's no string in it
		_attributedTextContextView = [[DTAttributedTextContentView alloc] initWithFrame:CGRectZero];
		_attributedTextContextView.edgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
		[self.contentView addSubview:_attributedTextContextView];
    }
    return self;
}

- (void)setNeedsLayout
{
	[super setNeedsLayout];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if (!self.superview)
	{
		return;
	}
	
	if (self.contentView.frame.origin.x==9.0f)
	{
		// "bug" in Tableview that sets the contentView first to {{9, 0}, {302, 102}} and then to {{10, 1}, {300, 99}}
		return;
	}
	
	CGFloat neededContentHeight = [self requiredRowHeightInTableView:(UITableView *)self.superview];
	
	// after the first call here the content view size is correct
	CGRect frame = CGRectMake(0, 0, self.contentView.bounds.size.width, neededContentHeight);
	_attributedTextContextView.frame = frame;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
	UITableView *tableView = (UITableView *)newSuperview;
	
	if (tableView.style == UITableViewStyleGrouped)
	{
		// need no background because otherwise this would overlap the rounded corners
		_attributedTextContextView.backgroundColor = [DTColor clearColor];
	}
	
	[super willMoveToSuperview:newSuperview];
}

- (CGFloat)requiredRowHeightInTableView:(UITableView *)tableView
{
	
	CGFloat contentWidth = tableView.frame.size.width;
	
	// reduce width for accessories
	switch (self.accessoryType)
	{
		case UITableViewCellAccessoryDisclosureIndicator:
		case UITableViewCellAccessoryCheckmark:
			contentWidth -= 20.0f;
			break;
		case UITableViewCellAccessoryDetailDisclosureButton:
			contentWidth -= 33.0f;
			break;
		case UITableViewCellAccessoryNone:
			break;
	}
	
	// reduce width for grouped table views
	if (tableView.style == UITableViewStyleGrouped)
	{
		// left and right 10 px margins on grouped table views
		contentWidth -= 20;
	}
	
	CGSize neededSize = [_attributedTextContextView suggestedFrameSizeToFitEntireStringConstraintedToWidth:contentWidth];
	
	// note: non-integer row heights caused trouble < iOS 5.0
	return neededSize.height;
}

#pragma mark Properties


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
	
    // Configure the view for the selected state
}

- (void)setHTMLString:(NSString *)html
{
	// we don't preserve the html but compare it's hash
	NSUInteger newHash = [html hash];
	
	if (newHash == _htmlHash)
	{
		return;
	}
	
	_htmlHash = newHash;
	
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTMLData:data documentAttributes:NULL];
	self.attributedString = string;
}

- (void)setAttributedString:(NSAttributedString *)attributedString
{
	// passthrough
	_attributedTextContextView.attributedString = attributedString;
}

- (NSAttributedString *)attributedString
{
	// passthrough
	return _attributedTextContextView.attributedString;
}

@synthesize attributedTextContextView = _attributedTextContextView;

@end
