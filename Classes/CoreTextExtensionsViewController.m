//
//  CoreTextExtensionsViewController.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "CoreTextExtensionsViewController.h"
#import "DTAttributedTextView.h"
#import "DTAttributedTextContentView.h"
#import "NSAttributedString+HTML.h"

@implementation CoreTextExtensionsViewController

- (void)loadView {
	DTAttributedTextView *textView = [[DTAttributedTextView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	textView.backgroundColor = [UIColor lightGrayColor];
	self.view = textView;
	[textView release];
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSString *readmePath = [[NSBundle mainBundle] pathForResource:@"README" ofType:@"html"];
	NSString *html = [NSString stringWithContentsOfFile:readmePath encoding:NSUTF8StringEncoding error:NULL];
	
	//NSString *html = @"e = mc<sup>2</sup>";
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:NULL];
	
	/*
	
	NSDictionary *attributes;
	
	NSRange effectiveRange = NSMakeRange(0, 0);
	
	while (attributes = [string attributesAtIndex:effectiveRange.location effectiveRange:&effectiveRange])
	{
		NSLog(@"Range: (%d, %d), %@", effectiveRange.location, effectiveRange.length, attributes);
		effectiveRange.location += effectiveRange.length;
		
		if (effectiveRange.location >= [string length])
		{
			break;
		}
	}
	
	
	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	
	for (int i=0; i<[dump length]; i++)
	{
		char *bytes = (char *)[dump bytes];
		
		char b = bytes[i];
		
		NSLog(@"%x %c", b, b);
	}
	
	
	NSLog(@"%@", dump); 
	
	 */
	[(DTAttributedTextContentView *)self.view setString:string];
}

@end
