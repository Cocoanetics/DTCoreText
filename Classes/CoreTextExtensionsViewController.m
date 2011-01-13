//
//  CoreTextExtensionsViewController.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "CoreTextExtensionsViewController.h"
#import "DTAttributedTextContentView.h"
#import "NSAttributedString+HTML.h"

@implementation CoreTextExtensionsViewController



/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
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



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
