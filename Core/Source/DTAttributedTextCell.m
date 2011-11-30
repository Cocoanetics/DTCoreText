//
//  DTAttributedTextCell.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 8/4/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextCell.h"
#import "DTAttributedTextContentView.h"

@implementation DTAttributedTextCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier accessoryType:(UITableViewCellAccessoryType)accessoryType
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) 
	{
		// this affects the space available for attributed content view
		self.accessoryType = accessoryType;

		CGFloat rightInset = 0;
		
		switch (accessoryType) 
		{
			case UITableViewCellAccessoryDisclosureIndicator:
			case UITableViewCellAccessoryCheckmark:
				rightInset = 20.0f;
				break;
			case UITableViewCellAccessoryDetailDisclosureButton:
				rightInset = 33.0f;
				break;
			case UITableViewCellAccessoryNone:
				break;
		}
		
		// cannot use autoresizing because this would cause more re-layouting than necessary		
		CGRect contentFrame = UIEdgeInsetsInsetRect(self.contentView.bounds, UIEdgeInsetsMake(0, 0, 0, rightInset));
		
		_attributedTextContextView = [[DTAttributedTextContentView alloc] initWithFrame:contentFrame];
		_attributedTextContextView.edgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
		[self.contentView addSubview:_attributedTextContextView];
    }
    return self;
}

- (void)dealloc
{
	[_attributedString release];
	[_attributedTextContextView release];
	
	[super dealloc];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	// after the first call here the content view size is correct
	_attributedTextContextView.frame = self.contentView.bounds;
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
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:NULL];
	self.attributedString = string;
	[string release];
}

- (void)setAttributedString:(NSAttributedString *)attributedString
{
	if (_attributedString != attributedString)
	{
		[_attributedString release];
		_attributedString = [attributedString retain];
		
		// passthrough
		_attributedTextContextView.attributedString = _attributedString;
	}
}

@synthesize attributedString = _attributedString;
@synthesize attributedTextContextView = _attributedTextContextView;

@end
