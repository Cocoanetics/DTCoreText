//
//  DemoTextViewController.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DemoTextViewController.h"
#import "DTAttributedTextView.h"
#import "DTAttributedTextContentView.h"
#import "NSAttributedString+HTML.h"
#import "DTTextAttachment.h"

#import "DTLinkButton.h"
#import "DTLazyImageView.h"

#import <QuartzCore/QuartzCore.h>

#import <MediaPlayer/MediaPlayer.h>

@interface DemoTextViewController ()
- (void)_segmentedControlChanged:(id)sender;

- (void)linkPushed:(DTLinkButton *)button;
- (void)linkLongPressed:(UILongPressGestureRecognizer *)gesture;
- (void)debugButton:(UIBarButtonItem *)sender;

@property (nonatomic, retain) NSMutableSet *mediaPlayers;

@end


@implementation DemoTextViewController

#pragma mark NSObject

- (id)init {
	if ((self = [super init])) {
		NSArray *items = [[NSArray alloc] initWithObjects:@"View", @"Ranges", @"Chars", @"Data", @"HTML", nil];
		_segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
		[items release];
		
		_segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
		_segmentedControl.selectedSegmentIndex = 0;
		[_segmentedControl addTarget:self action:@selector(_segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
		self.navigationItem.titleView = _segmentedControl;	
		
		// toolbar
		UIBarButtonItem *spacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
		UIBarButtonItem *debug = [[[UIBarButtonItem alloc] initWithTitle:@"Debug Frames" style:UIBarButtonItemStyleBordered target:self action:@selector(debugButton:)] autorelease];
		NSArray *toolbarItems = [NSArray arrayWithObjects:spacer, debug, nil];
		[self setToolbarItems:toolbarItems];
		
		
		// register notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lazyImageDidFinishLoading:) name:@"DTLazyImageViewDidFinishLoading" object:nil];
	}
	return self;
}


- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_fileName release];
	[_segmentedControl release];
	[_textView release];
	[_rangeView release];
	[_charsView release];
	[_dataView release];
	[_htmlView release];
	[baseURL release];
	
	[lastActionLink release];
	[mediaPlayers release];
	
	[super dealloc];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


#pragma mark UIViewController

- (void)loadView {
	[super loadView];
	
	CGRect frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
	
	// Create data view
	_dataView = [[UITextView alloc] initWithFrame:frame];
	_dataView.editable = NO;
	_dataView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_dataView];
	
	// Create chars view
	_charsView = [[UITextView alloc] initWithFrame:frame];
	_charsView.editable = NO;
	_charsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_charsView];
	
	// Create range view
	_rangeView = [[UITextView alloc] initWithFrame:frame];
	_rangeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_rangeView.editable = NO;
	[self.view addSubview:_rangeView];

	// Create html view
	_htmlView = [[UITextView alloc] initWithFrame:frame];
	_htmlView.editable = NO;
	_htmlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_htmlView];

	// Create text view
	[DTAttributedTextContentView setLayerClass:[CATiledLayer class]];
	_textView = [[DTAttributedTextView alloc] initWithFrame:frame];
	_textView.textDelegate = self;
	_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:_textView];
}


- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Load HTML data
	NSString *readmePath = [[NSBundle mainBundle] pathForResource:_fileName ofType:nil];
	NSString *html = [NSString stringWithContentsOfFile:readmePath encoding:NSUTF8StringEncoding error:NULL];
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	
	// Create attributed string from HTML
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0], NSTextSizeMultiplierDocumentOption, [NSValue valueWithCGSize:CGSizeMake(200, 150)], DTMaxImageSize,
													 @"Times New Roman", DTDefaultFontFamily,  @"purple", DTDefaultLinkColor, nil]; // @"green",DTDefaultTextColor,
	
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data options:options documentAttributes:NULL];
	
	// Display string
	_textView.contentView.edgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
	_textView.attributedString = string;
	
	// Data view
	_dataView.text = [data description];
	
	[string release];
}


- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	
	CGRect bounds = self.view.bounds;
	_textView.frame = bounds;
	
	[self _segmentedControlChanged:nil];
	[_textView setContentInset:UIEdgeInsetsMake(0, 0, 44, 0)];
	[_textView setScrollIndicatorInsets:UIEdgeInsetsMake(0, 0, 44, 0)];
	[self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// now the bar is up so we can autoresize again
	_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	// fill other tabs
	// Create range view
	NSMutableString *dumpOutput = [[NSMutableString alloc] init];
	NSDictionary *attributes = nil;
	NSRange effectiveRange = NSMakeRange(0, 0);
	
	if ([_textView.attributedString length])
	{
		
		while ((attributes = [_textView.attributedString attributesAtIndex:effectiveRange.location effectiveRange:&effectiveRange]))
		{
			[dumpOutput appendFormat:@"Range: (%d, %d), %@\n\n", effectiveRange.location, effectiveRange.length, attributes];
			effectiveRange.location += effectiveRange.length;
			
			if (effectiveRange.location >= [_textView.attributedString length])
			{
				break;
			}
		}
	}
	_rangeView.text = dumpOutput;
	
	
	// Create characters view
	[dumpOutput setString:@""];
	NSData *dump = [[_textView.attributedString string] dataUsingEncoding:NSUTF8StringEncoding];
	for (NSInteger i = 0; i < [dump length]; i++)
	{
		char *bytes = (char *)[dump bytes];
		char b = bytes[i];
		
		[dumpOutput appendFormat:@"%x %c\n", b, b];
	}
	_charsView.text = dumpOutput;
	[dumpOutput release];
	
	// Create HTML view
	_htmlView.text = [_textView.attributedString htmlString];
}

- (void)viewWillDisappear:(BOOL)animated;
{
	[self.navigationController setToolbarHidden:YES animated:YES];
	
	// stop all playing media
	for (MPMoviePlayerController *player in self.mediaPlayers)
	{
		[player stop];
	}
	
	[super viewWillDisappear:animated];
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
		case 4:
			selectedView = _htmlView;
			break;
	}
	
	[self.view bringSubviewToFront:selectedView];
	[selectedView flashScrollIndicators];
}


#pragma mark Custom Views on Text
- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForLink:(NSURL *)url identifier:(NSString *)identifier frame:(CGRect)frame
{
	DTLinkButton *button = [[[DTLinkButton alloc] initWithFrame:frame] autorelease];
	button.url = url;
	button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough
	button.guid = identifier;
	
	// use normal push action for opening URL
	[button addTarget:self action:@selector(linkPushed:) forControlEvents:UIControlEventTouchUpInside];
	
	// demonstrate combination with long press
	UILongPressGestureRecognizer *longPress = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(linkLongPressed:)] autorelease];
	[button addGestureRecognizer:longPress];
	
	return button;
}

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame
{
	if (attachment.contentType == DTTextAttachmentTypeVideoURL)
	{
		NSURL *url = (id)attachment.contentURL;
		
		// we could customize the view that shows before playback starts
		UIView *grayView = [[[UIView alloc] initWithFrame:frame] autorelease];
		grayView.backgroundColor = [UIColor blackColor];
		
		MPMoviePlayerController *player =[[[MPMoviePlayerController alloc] initWithContentURL:url] autorelease];
		
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_4_2
		NSString *airplayAttr = [attachment.attributes objectForKey:@"x-webkit-airplay"];
		if ([airplayAttr isEqualToString:@"allow"])
		{
			if ([player respondsToSelector:@selector(setAllowsAirPlay:)])
			{
				player.allowsAirPlay = YES;
			}
		}
#endif
		
		NSString *controlsAttr = [attachment.attributes objectForKey:@"controls"];
		if (controlsAttr)
		{
			player.controlStyle = MPMovieControlStyleEmbedded;
		}
		else
		{
			player.controlStyle = MPMovieControlStyleNone;
		}
		
		NSString *loopAttr = [attachment.attributes objectForKey:@"loop"];
		if (loopAttr)
		{
			player.repeatMode = MPMovieRepeatModeOne;
		}
		else
		{
			player.repeatMode = MPMovieRepeatModeNone;
		}
		
		NSString *autoplayAttr = [attachment.attributes objectForKey:@"autoplay"];
		if (autoplayAttr)
		{
			player.shouldAutoplay = YES;
		}
		else
		{
			player.shouldAutoplay = NO;
		}
		
		[player prepareToPlay];
		[self.mediaPlayers addObject:player];
		
		player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		player.view.frame = grayView.bounds;
		[grayView addSubview:player.view];
		
		return grayView;
	}
	else if (attachment.contentType == DTTextAttachmentTypeImage)
	{
		// if the attachment has a hyperlinkURL then this is currently ignored
		DTLazyImageView *imageView = [[[DTLazyImageView alloc] initWithFrame:frame] autorelease];
		if (attachment.contents)
		{
			imageView.image = attachment.contents;
		}
		
		// url for deferred loading
		imageView.url = attachment.contentURL;
		
		return imageView;
	}
	
	return nil;
}


#pragma mark Actions

- (void)linkPushed:(DTLinkButton *)button
{
	[[UIApplication sharedApplication] openURL:[button.url absoluteURL]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
		[[UIApplication sharedApplication] openURL:[self.lastActionLink absoluteURL]];
	}
}

- (void)linkLongPressed:(UILongPressGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		DTLinkButton *button = (id)[gesture view];
		button.highlighted = NO;
		self.lastActionLink = button.url;
		
		if ([[UIApplication sharedApplication] canOpenURL:[button.url absoluteURL]])
		{
			UIActionSheet *action = [[[UIActionSheet alloc] initWithTitle:[[button.url absoluteURL] description] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open in Safari", nil] autorelease];
			[action showFromRect:button.frame inView:button.superview animated:YES];
		}
	}
}

- (void)debugButton:(UIBarButtonItem *)sender
{
	_textView.contentView.drawDebugFrames = !_textView.contentView.drawDebugFrames;
	[DTCoreTextLayoutFrame setShouldDrawDebugFrames:_textView.contentView.drawDebugFrames];
	[self.view setNeedsDisplay];
}

#pragma mark Notifications
- (void)lazyImageDidFinishLoading:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	NSURL *url = [userInfo objectForKey:@"ImageURL"];
	CGSize imageSize = [[userInfo objectForKey:@"ImageSize"] CGSizeValue];
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"contentURL == %@", url];
	
	// update all attachments that matchin this URL (possibly multiple images with same size)
	for (DTTextAttachment *oneAttachment in [_textView.contentView.layoutFrame textAttachmentsWithPredicate:pred])
	{
		oneAttachment.originalSize = imageSize;
		
		if (!CGSizeEqualToSize(imageSize, oneAttachment.displaySize))
		{
			oneAttachment.displaySize = imageSize;
		}
	}
	
	// redo layout
	// here we're layouting the entire string, might be more efficient to only relayout the paragraphs that contain these attachments
	[_textView.contentView relayoutText];
}

#pragma mark Properties

- (NSMutableSet *)mediaPlayers
{
	if (!mediaPlayers)
	{
		mediaPlayers = [[NSMutableSet alloc] init];
	}
	
	return mediaPlayers;
}

@synthesize fileName = _fileName;
@synthesize lastActionLink;
@synthesize mediaPlayers;
@synthesize baseURL;


@end
