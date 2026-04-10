//
//  DemoAboutViewController.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 3/4/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DemoAboutViewController.h"
#import "DTCoreTextConstants.h"

@import DTCoreTextSwift;

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

	// The xib sets `view` AND `attributedTextView` to the same DTAttributedTextView,
	// so `self.view` is the scroll view directly. Explicitly request automatic
	// content inset adjustment so the nav bar and safe areas are honoured on
	// modern iOS (the default is .automatic but DTAttributedTextView sometimes
	// sets different content/scroll indicator insets in its init).
	self.attributedTextView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;

	NSString *path = [[NSBundle mainBundle] pathForResource:@"About" ofType:@"html"];
	NSData *data = [NSData dataWithContentsOfFile:path];

	NSDictionary *options = @{DTDefaultTextColor: [UIColor labelColor]};

	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithHTMLData:data options:options documentAttributes:NULL];

	self.attributedTextView.attributedString = attributedString;
	self.attributedTextView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
}

@end
