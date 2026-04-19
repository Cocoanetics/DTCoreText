//
//  DemoAboutViewController.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 3/4/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DemoAboutViewController.h"
#import "DTCoreTextConstants.h"

@import DTCoreText;

@interface DemoAboutViewController ()

@end

@implementation DemoAboutViewController

- (id)init
{
    self = [super initWithNibName:@"DemoAboutViewController" bundle:nil];
    if (self)
	 {
        // Custom initialization
		 self.navigationItem.title = @"About DTCoreText";
    }
    return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	// self.view IS the DTAttributedTextView scroll view (wired from the XIB),
	// so it extends behind the translucent nav bar. Ask UIKit to include the
	// nav-bar / safe-area insets in the scroll view's adjustedContentInset so
	// the text never draws underneath the bar.
	self.attributedTextView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;

	NSString *path = [[NSBundle mainBundle] pathForResource:@"About" ofType:@"html"];
	NSData *data = [NSData dataWithContentsOfFile:path];

	NSDictionary *options = @{DTDefaultTextColor: [UIColor labelColor]};

	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithHTMLData:data options:options documentAttributes:NULL];

	self.attributedTextView.attributedString = attributedString;
	self.attributedTextView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
}

@end
