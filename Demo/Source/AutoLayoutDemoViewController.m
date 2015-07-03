//
// AutoLayoutDemoViewController.m
// DTCoreText
//
// Created by David Whetstone on 5/8/15.
// Copyright (c) 2015 Drobnik.com. All rights reserved.
//

#import "AutoLayoutDemoViewController.h"

@interface AutoLayoutDemoViewController ()

@property (nonatomic, weak) IBOutlet DTAttributedTextContentView *textView;
@end

@implementation AutoLayoutDemoViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    NSString *html = @"<html><body>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</body></html>";
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    self.textView.attributedString = [[NSAttributedString alloc] initWithHTMLData:data documentAttributes:NULL];
}

@end