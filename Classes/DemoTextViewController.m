//
//  DemoTextViewController.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DemoTextViewController.h"
#import "DTAttributedTextView.h"
#import "NSAttributedString+HTML.h"

@interface DemoTextViewController (PrivateMethods)
- (void)_segmentedControlChanged:(id)sender;
@end


@implementation DemoTextViewController

@synthesize fileName = _fileName;

#pragma mark NSObject

- (id)init {
	if ((self = [super init])) {
		NSArray *items = [[NSArray alloc] initWithObjects:@"View", @"Ranges", @"Chars", @"Data", nil];
		_segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
		[items release];
		
		_segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
		_segmentedControl.selectedSegmentIndex = 0;
		[_segmentedControl addTarget:self action:@selector(_segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
		self.navigationItem.titleView = _segmentedControl;		
	}
	return self;
}


- (void)dealloc {
	[_fileName release];
	[_segmentedControl release];
	[_textView release];
	[_rangeView release];
	[_charsView release];
	[_dataView release];
	[super dealloc];
}


#pragma mark UIViewController

- (void)loadView {
	[super loadView];
	
	CGRect frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
	
	// Create data view
	_dataView = [[UITextView alloc] initWithFrame:frame];
	_dataView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_dataView];
	
	// Create chars view
	_charsView = [[UITextView alloc] initWithFrame:frame];
	_charsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_charsView];
	
	// Create range view
	_rangeView = [[UITextView alloc] initWithFrame:frame];
	_rangeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_rangeView];
	
	// Create text view
	_textView = [[DTAttributedTextView alloc] initWithFrame:frame];
	_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_textView.backgroundColor = [UIColor lightGrayColor];
	[self.view addSubview:_textView];
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Load HTML data
	NSString *readmePath = [[NSBundle mainBundle] pathForResource:_fileName ofType:@"html"];
	NSString *html = [NSString stringWithContentsOfFile:readmePath encoding:NSUTF8StringEncoding error:NULL];
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	
	// Create attributed string from HTML
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:NULL];
	
	// Display string
	_textView.string = string;
	
	// Create range view
	NSMutableString *dumpOutput = [[NSMutableString alloc] init];
	NSDictionary *attributes = nil;
	NSRange effectiveRange = NSMakeRange(0, 0);
	
	while (attributes = [string attributesAtIndex:effectiveRange.location effectiveRange:&effectiveRange])
	{
		[dumpOutput appendFormat:@"Range: (%d, %d), %@\n\n", effectiveRange.location, effectiveRange.length, attributes];
		effectiveRange.location += effectiveRange.length;
		
		if (effectiveRange.location >= [string length])
		{
			break;
		}
	}
	_rangeView.text = dumpOutput;
	

	// Create characters view
	[dumpOutput setString:@""];
	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	for (NSInteger i = 0; i < [dump length]; i++)
	{
		char *bytes = (char *)[dump bytes];
		char b = bytes[i];
		
		[dumpOutput appendFormat:@"%x %c\n", b, b];
	}
	_charsView.text = dumpOutput;
	[dumpOutput release];
	
	// Data view
	_dataView.text = [data description];
}


- (void)viewDidAppear:(BOOL)animated {
	[self _segmentedControlChanged:nil];
}


#pragma mark Private Methods

- (void)_segmentedControlChanged:(id)sender {
	UIScrollView *selectedView = _textView;
	
	switch (_segmentedControl.selectedSegmentIndex) {
		case 1:
			selectedView = _rangeView;
			break;
		case 2:
			selectedView = _charsView;
			break;
		case 3:
			selectedView = _dataView;
			break;
	}
	
	[self.view bringSubviewToFront:selectedView];
	[selectedView flashScrollIndicators];
}

@end
