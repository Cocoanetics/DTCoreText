//
//  DTAttributedTextView.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextView.h"

#import "DTAttributedTextContentView.h"

@implementation DTAttributedTextView


- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
    }
    return self;
}


- (void)layoutSubviews
{
	self.contentView; // trigger adding if not happened
}

- (void)dealloc 
{
	[contentView release];
	
    [super dealloc];
}

#pragma mark Properties
- (DTAttributedTextContentView *)contentView
{
	if (!contentView)
	{
		contentView = [[DTAttributedTextContentView alloc] initWithFrame:self.bounds];
		[self addSubview:self.contentView];
	}		
	
	return contentView;
}


- (void)setString:(NSAttributedString *)string
{
	self.contentView.string = string;
	self.contentSize = contentView.bounds.size;
	
	CGSize size1 = contentView.bounds.size;
	CGSize size2 = self.contentSize;
	
	NSLog(@"%@ %@", NSStringFromCGSize(size1), NSStringFromCGSize(size2));
}

@synthesize string;
@synthesize contentView;

@end
