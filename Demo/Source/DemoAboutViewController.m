//
//  DemoAboutViewController.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 3/4/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DemoAboutViewController.h"

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
    // Do any additional setup after loading the view from its nib.
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"About" ofType:@"html"];
	NSData *data = [NSData dataWithContentsOfFile:path];
	
	NSDictionary *options;
	
	if (@available(iOS 13.0, *)) {
		options = @{DTDefaultTextColor: [UIColor labelColor], DTUseiOS6Attributes: @(YES)};
	} else {
		options = @{DTDefaultTextColor: [UIColor blackColor], DTUseiOS6Attributes: @(YES)};
	}
	
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithHTMLData:data options:options documentAttributes:NULL];

	self.attributedTextView.attributedString = attributedString;
	self.attributedTextView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
}

@end
