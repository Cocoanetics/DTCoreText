//
//  CoreTextExtensionsViewController.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "CoreTextExtensionsViewController.h"
#import "DTAttributedTextView.h"
#import "NSAttributedString+HTML.h"

@implementation CoreTextExtensionsViewController

- (void)loadView {
	// Create text view
	DTAttributedTextView *textView = [[DTAttributedTextView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	textView.backgroundColor = [UIColor lightGrayColor];
	self.view = textView;
	[textView release];
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Load HTML data
	NSString *readmePath = [[NSBundle mainBundle] pathForResource:@"README" ofType:@"html"];
	NSString *html = [NSString stringWithContentsOfFile:readmePath encoding:NSUTF8StringEncoding error:NULL];
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	
	// Create attributed string from HTML
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:NULL];
	
	// Display string
	[(DTAttributedTextView *)self.view setString:string];
}

@end
