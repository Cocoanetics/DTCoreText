//
//  DemoTextViewController.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DemoTextViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

#import "DTTiledLayerWithoutFade.h"
#import "DemoWebVideoView.h"


@interface DemoTextViewController ()
- (void)_segmentedControlChanged:(id)sender;

- (void)linkPushed:(DTLinkButton *)button;
- (void)linkLongPressed:(UILongPressGestureRecognizer *)gesture;
- (void)debugButton:(UIBarButtonItem *)sender;

@property (nonatomic, strong) NSMutableSet *mediaPlayers;
@property (nonatomic, strong) NSArray *contentViews;

@end


@implementation DemoTextViewController
{
	NSString *_fileName;
	
	UISegmentedControl *_segmentedControl;
	UISegmentedControl *_htmlOutputTypeSegment;
	
	DTAttributedTextView *_textView;
	UITextView *_rangeView;
	UITextView *_charsView;
	UITextView *_htmlView;
	UITextView *_iOS6View;
	
	NSURL *baseURL;
	
	// private
	NSURL *lastActionLink;
	NSMutableSet *mediaPlayers;
	
	BOOL _needsAdjustInsetsOnLayout;
}


#pragma mark NSObject

- (id)init
{
	self = [super init];
	if (self)
	{
		NSMutableArray *items = [[NSMutableArray alloc] initWithObjects:@"View", @"Ranges", @"Chars", @"HTML", nil];
		
#ifdef DTCORETEXT_SUPPORT_NS_ATTRIBUTES
		if (floor(NSFoundationVersionNumber) >= DTNSFoundationVersionNumber_iOS_6_0)
		{
			[items addObject:@"iOS 6"];
		}
#endif
		
		_segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
		_segmentedControl.selectedSegmentIndex = 0;
		[_segmentedControl addTarget:self action:@selector(_segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
		self.navigationItem.titleView = _segmentedControl;	
		
		[self _updateToolbarForMode];
		
		_needsAdjustInsetsOnLayout = YES;
		
		self.automaticallyAdjustsScrollViewInsets = YES;
	}
	return self;
}


- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UIViewController

- (void)_updateToolbarForMode
{
	NSMutableArray *toolbarItems = [NSMutableArray array];
	
	UIBarButtonItem *debug = [[UIBarButtonItem alloc] initWithTitle:@"Debug Frames" style:UIBarButtonItemStylePlain target:self action:@selector(debugButton:)];
	[toolbarItems addObject:debug];
	
	UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[toolbarItems addObject:space];
	
	UIBarButtonItem *screenshot = [[UIBarButtonItem alloc] initWithTitle:@"Screenshot" style:UIBarButtonItemStylePlain target:self action:@selector(screenshot:)];
	[toolbarItems addObject:screenshot];
	
	if (_segmentedControl.selectedSegmentIndex == 3)
	{
		if (!_htmlOutputTypeSegment)
		{
			_htmlOutputTypeSegment = [[UISegmentedControl alloc] initWithItems:@[@"Document", @"Fragment"]];
			_htmlOutputTypeSegment.selectedSegmentIndex = 0;
			
			[_htmlOutputTypeSegment addTarget:self action:@selector(_htmlModeChanged:) forControlEvents:UIControlEventValueChanged];
		}
	
		UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
		[toolbarItems addObject:spacer];
	
		UIBarButtonItem *htmlMode = [[UIBarButtonItem alloc] initWithCustomView:_htmlOutputTypeSegment];
	
		[toolbarItems addObject:htmlMode];
	}

	[self setToolbarItems:toolbarItems];
}

- (void)loadView {
	[super loadView];
	
	CGRect frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
	
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
	_textView = [[DTAttributedTextView alloc] initWithFrame:frame];
	
	// we draw images and links via subviews provided by delegate methods
	_textView.shouldDrawImages = NO;
	_textView.shouldDrawLinks = NO;
	_textView.textDelegate = self; // delegate for custom sub views
	
	// gesture for testing cursor positions
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	[_textView addGestureRecognizer:tap];
	
	// set an inset. Since the bottom is below a toolbar inset by 44px
	[_textView setScrollIndicatorInsets:UIEdgeInsetsMake(0, 0, 44, 0)];
	_textView.contentInset = UIEdgeInsetsMake(10, 10, 54, 10);

	_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:_textView];
	
	// create a text view to for testing iOS 6 compatibility
	// Create html view
	_iOS6View = [[UITextView alloc] initWithFrame:frame];
	_iOS6View.editable = NO;
	_iOS6View.contentInset = UIEdgeInsetsMake(10, 0, 10, 0);
	_iOS6View.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_iOS6View];
	
	self.contentViews = @[_charsView, _rangeView, _htmlView, _textView, _iOS6View];
}


- (NSAttributedString *)_attributedStringForSnippetUsingiOS6Attributes:(BOOL)useiOS6Attributes
{
	// Load HTML data
	NSString *readmePath = [[NSBundle mainBundle] pathForResource:_fileName ofType:nil];
	NSString *html = [NSString stringWithContentsOfFile:readmePath encoding:NSUTF8StringEncoding error:NULL];
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	
	// Create attributed string from HTML
	CGSize maxImageSize = CGSizeMake(self.view.bounds.size.width - 20.0, self.view.bounds.size.height - 20.0);
	
	// example for setting a willFlushCallback, that gets called before elements are written to the generated attributed string
	void (^callBackBlock)(DTHTMLElement *element) = ^(DTHTMLElement *element) {
		
		// the block is being called for an entire paragraph, so we check the individual elements
		
		for (DTHTMLElement *oneChildElement in element.childNodes)
		{
			// if an element is larger than twice the font size put it in it's own block
			if (oneChildElement.displayStyle == DTHTMLElementDisplayStyleInline && oneChildElement.textAttachment.displaySize.height > 2.0 * oneChildElement.fontDescriptor.pointSize)
			{
				oneChildElement.displayStyle = DTHTMLElementDisplayStyleBlock;
				oneChildElement.paragraphStyle.minimumLineHeight = element.textAttachment.displaySize.height;
				oneChildElement.paragraphStyle.maximumLineHeight = element.textAttachment.displaySize.height;
			}
		}
	};
	
	NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0], NSTextSizeMultiplierDocumentOption, [NSValue valueWithCGSize:maxImageSize], DTMaxImageSize,
							 @"Times New Roman", DTDefaultFontFamily,  @"purple", DTDefaultLinkColor, @"red", DTDefaultLinkHighlightColor, callBackBlock, DTWillFlushBlockCallBack, nil];
	
	if (useiOS6Attributes)
	{
		[options setObject:[NSNumber numberWithBool:YES] forKey:DTUseiOS6Attributes];
	}
	
	[options setObject:[NSURL fileURLWithPath:readmePath] forKey:NSBaseURLDocumentOption];
	
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTMLData:data options:options documentAttributes:NULL];
	
	return string;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	CGRect bounds = self.view.bounds;
	_textView.frame = bounds;

	// Display string
	_textView.shouldDrawLinks = NO; // we draw them in DTLinkButton
	_textView.attributedString = [self _attributedStringForSnippetUsingiOS6Attributes:NO];
	
	[self _segmentedControlChanged:nil];
	
	[self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// now the bar is up so we can autoresize again
	_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)viewWillDisappear:(BOOL)animated;
{
	[self.navigationController setToolbarHidden:YES animated:YES];
	
	// stop all playing media
	for (MPMoviePlayerController *player in self.mediaPlayers)
	{
		[player stop];
	}
	
	_textView.textDelegate = nil;
	
	[super viewWillDisappear:animated];
}

- (BOOL)prefersStatusBarHidden
{
	// prevent hiding of status bar in landscape because this messes up the layout guide calc
	return NO;
}

// this is only called on >= iOS 5
- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	if (![self respondsToSelector:@selector(topLayoutGuide)] || !_needsAdjustInsetsOnLayout)
	{
		return;
	}
	
	// this also compiles with iOS 6 SDK, but will work with later SDKs too
	CGFloat topInset = [[self valueForKeyPath:@"topLayoutGuide.length"] floatValue];
	CGFloat bottomInset = [[self valueForKeyPath:@"bottomLayoutGuide.length"] floatValue];
	
	UIEdgeInsets outerInsets = UIEdgeInsetsMake(topInset, 0, bottomInset, 0);
	UIEdgeInsets innerInsets = outerInsets;
	innerInsets.left += 10;
	innerInsets.right += 10;
	innerInsets.top += 10;
	innerInsets.bottom += 10;
	
	CGPoint innerScrollOffset = CGPointMake(-innerInsets.left, -innerInsets.top);
	CGPoint outerScrollOffset = CGPointMake(-outerInsets.left, -outerInsets.top);
	
	_textView.contentInset = innerInsets;
	_textView.contentOffset = innerScrollOffset;
	_textView.scrollIndicatorInsets = outerInsets;
	
	_iOS6View.contentInset = outerInsets;
	_iOS6View.contentOffset = outerScrollOffset;
	_iOS6View.scrollIndicatorInsets = outerInsets;

	_charsView.contentInset = outerInsets;
	_charsView.contentOffset = outerScrollOffset;
	_charsView.scrollIndicatorInsets = outerInsets;
	
	_rangeView.contentInset = outerInsets;
	_rangeView.contentOffset = outerScrollOffset;
	_rangeView.scrollIndicatorInsets = outerInsets;
	
	_htmlView.contentInset = outerInsets;
	_htmlView.contentOffset = outerScrollOffset;
	_htmlView.scrollIndicatorInsets = outerInsets;
	
	_needsAdjustInsetsOnLayout = NO;
}

#pragma mark Private Methods

- (void)updateDetailViewForIndex:(NSUInteger)index
{
	switch (index) 
	{
		case 1:
		{
			NSMutableString *dumpOutput = [[NSMutableString alloc] init];
			NSDictionary *attributes = nil;
			NSRange effectiveRange = NSMakeRange(0, 0);
			
			if ([_textView.attributedString length])
			{
				
				while ((attributes = [_textView.attributedString attributesAtIndex:effectiveRange.location effectiveRange:&effectiveRange]))
				{
					[dumpOutput appendFormat:@"Range: (%lu, %lu), %@\n\n", (unsigned long)effectiveRange.location, (unsigned long)effectiveRange.length, attributes];
					effectiveRange.location += effectiveRange.length;
					
					if (effectiveRange.location >= [_textView.attributedString length])
					{
						break;
					}
				}
			}
			_rangeView.text = dumpOutput;
			break;
		}
		case 2:
		{
			// Create characters view
			NSMutableString *dumpOutput = [[NSMutableString alloc] init];
			NSData *dump = [[_textView.attributedString string] dataUsingEncoding:NSUTF8StringEncoding];
			for (NSInteger i = 0; i < [dump length]; i++)
			{
				char *bytes = (char *)[dump bytes];
				char b = bytes[i];
				
				[dumpOutput appendFormat:@"%li: %x %c\n", (long)i, b, b];
			}
			_charsView.text = dumpOutput;
			
			break;
		}
		case 3:
		{
			if (_htmlOutputTypeSegment.selectedSegmentIndex == 0)
			{
				_htmlView.text = [_textView.attributedString htmlString];
			}
			else
			{
				_htmlView.text = [_textView.attributedString htmlFragment];
			}
			
			break;
		}
		case 4:
		{
			if (![_iOS6View.attributedText length])
			{
				_iOS6View.attributedText = [self _attributedStringForSnippetUsingiOS6Attributes:YES];
			}
		}
	}
}

- (void)_segmentedControlChanged:(id)sender {
	UIScrollView *selectedView = _textView;
	
	switch (_segmentedControl.selectedSegmentIndex)
	{
		case 1:
		{
			selectedView = _rangeView;
			break;
		}
			
		case 2:
		{
			selectedView = _charsView;
			break;
		}
			
		case 3:
		{
			selectedView = _htmlView;
			
			break;
		}
			
		case 4:
		{
			selectedView = _iOS6View;
			break;
		}
	}

	// refresh only this tab
	[self updateDetailViewForIndex:_segmentedControl.selectedSegmentIndex];
	
	// Hide all views except for the selected view to not conflict with VoiceOver
	for (UIView *view in self.contentViews)
		view.hidden = YES;
	selectedView.hidden = NO;
	
	[self.view bringSubviewToFront:selectedView];
	[selectedView flashScrollIndicators];
	
	[self _updateToolbarForMode];
}

- (void)_htmlModeChanged:(id)sender
{
	// refresh only this tab
	[self updateDetailViewForIndex:_segmentedControl.selectedSegmentIndex];
}


#pragma mark Custom Views on Text

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame
{
	NSDictionary *attributes = [string attributesAtIndex:0 effectiveRange:NULL];
	
	NSURL *URL = [attributes objectForKey:DTLinkAttribute];
	NSString *identifier = [attributes objectForKey:DTGUIDAttribute];
	
	
	DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
	button.URL = URL;
	button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough
	button.GUID = identifier;
	
	// get image with normal link text
	UIImage *normalImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDefault];
	[button setImage:normalImage forState:UIControlStateNormal];
	
	// get image for highlighted link text
	UIImage *highlightImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDrawLinksHighlighted];
	[button setImage:highlightImage forState:UIControlStateHighlighted];
	
	// use normal push action for opening URL
	[button addTarget:self action:@selector(linkPushed:) forControlEvents:UIControlEventTouchUpInside];
	
	// demonstrate combination with long press
	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(linkLongPressed:)];
	[button addGestureRecognizer:longPress];
	
	return button;
}

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame
{
	if ([attachment isKindOfClass:[DTVideoTextAttachment class]])
	{
		NSURL *url = (id)attachment.contentURL;
		
		// we could customize the view that shows before playback starts
		UIView *grayView = [[UIView alloc] initWithFrame:frame];
		grayView.backgroundColor = [DTColor blackColor];
		
		// find a player for this URL if we already got one
		MPMoviePlayerController *player = nil;
		for (player in self.mediaPlayers)
		{
			if ([player.contentURL isEqual:url])
			{
				break;
			}
		}
		
		if (!player)
		{
			player = [[MPMoviePlayerController alloc] initWithContentURL:url];
			[self.mediaPlayers addObject:player];
		}
		
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
		
		player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		player.view.frame = grayView.bounds;
		[grayView addSubview:player.view];
		
		return grayView;
	}
	else if ([attachment isKindOfClass:[DTImageTextAttachment class]])
	{
		// if the attachment has a hyperlinkURL then this is currently ignored
		DTLazyImageView *imageView = [[DTLazyImageView alloc] initWithFrame:frame];
		imageView.delegate = self;
		
		// sets the image if there is one
		imageView.image = [(DTImageTextAttachment *)attachment image];
		
		// url for deferred loading
		imageView.url = attachment.contentURL;
		
		// if there is a hyperlink then add a link button on top of this image
		if (attachment.hyperLinkURL)
		{
			// NOTE: this is a hack, you probably want to use your own image view and touch handling
			// also, this treats an image with a hyperlink by itself because we don't have the GUID of the link parts
			imageView.userInteractionEnabled = YES;
			
			DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:imageView.bounds];
			button.URL = attachment.hyperLinkURL;
			button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough
			button.GUID = attachment.hyperLinkGUID;
			
			// use normal push action for opening URL
			[button addTarget:self action:@selector(linkPushed:) forControlEvents:UIControlEventTouchUpInside];
			
			// demonstrate combination with long press
			UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(linkLongPressed:)];
			[button addGestureRecognizer:longPress];
			
			[imageView addSubview:button];
		}
		
		return imageView;
	}
	else if ([attachment isKindOfClass:[DTIframeTextAttachment class]])
	{
		DemoWebVideoView *videoView = [[DemoWebVideoView alloc] initWithFrame:frame];
		videoView.attachment = attachment;
		
		return videoView;
	}
	else if ([attachment isKindOfClass:[DTObjectTextAttachment class]])
	{
		// somecolorparameter has a HTML color
		NSString *colorName = [attachment.attributes objectForKey:@"somecolorparameter"];
		UIColor *someColor = DTColorCreateWithHTMLName(colorName);
		
		UIView *someView = [[UIView alloc] initWithFrame:frame];
		someView.backgroundColor = someColor;
		someView.layer.borderWidth = 1;
		someView.layer.borderColor = [UIColor blackColor].CGColor;
		
		someView.accessibilityLabel = colorName;
		someView.isAccessibilityElement = YES;
		
		return someView;
	}
	
	return nil;
}

- (BOOL)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView shouldDrawBackgroundForTextBlock:(DTTextBlock *)textBlock frame:(CGRect)frame context:(CGContextRef)context forLayoutFrame:(DTCoreTextLayoutFrame *)layoutFrame
{
	UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(frame,1,1) cornerRadius:10];

	CGColorRef color = [textBlock.backgroundColor CGColor];
	if (color)
	{
		CGContextSetFillColorWithColor(context, color);
		CGContextAddPath(context, [roundedRect CGPath]);
		CGContextFillPath(context);
		
		CGContextAddPath(context, [roundedRect CGPath]);
		CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
		CGContextStrokePath(context);
		return NO;
	}
	
	return YES; // draw standard background
}


#pragma mark Actions

- (void)linkPushed:(DTLinkButton *)button
{
	NSURL *URL = button.URL;
	
	if ([[UIApplication sharedApplication] canOpenURL:[URL absoluteURL]])
	{
		if (@available(iOS 10.0, *)) {
			[[UIApplication sharedApplication] openURL:[URL absoluteURL] options:@{} completionHandler:nil];
		} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			[[UIApplication sharedApplication] openURL:[URL absoluteURL]];
#pragma clang diagnostic pop
		}
	}
	else 
	{
		if (![URL host] && ![URL path])
		{
		
			// possibly a local anchor link
			NSString *fragment = [URL fragment];
			
			if (fragment)
			{
				[_textView scrollToAnchorNamed:fragment animated:NO];
			}
		}
	}
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
#pragma clang diagnostic pop
{
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
		if (@available(iOS 10.0, *)) {
			[[UIApplication sharedApplication] openURL:[self.lastActionLink absoluteURL] options:@{} completionHandler:nil];
		} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			[[UIApplication sharedApplication] openURL:[self.lastActionLink absoluteURL]];
#pragma clang diagnostic pop
		}
	}
}

- (void)linkLongPressed:(UILongPressGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		DTLinkButton *button = (id)[gesture view];
		button.highlighted = NO;
		self.lastActionLink = button.URL;
		
		if ([[UIApplication sharedApplication] canOpenURL:[button.URL absoluteURL]])
		{
			if (@available(iOS 8.0, *)) {
				UIAlertController *ac = [UIAlertController alertControllerWithTitle:[[button.URL absoluteURL] description]
																			message:nil
																	 preferredStyle:UIAlertControllerStyleActionSheet];
				[ac addAction:[UIAlertAction actionWithTitle:@"Open in Safari"
													   style:UIAlertActionStyleDefault
													 handler:^(UIAlertAction * _Nonnull action) {
					[[UIApplication sharedApplication] openURL:[self.lastActionLink absoluteURL] options:@{} completionHandler:nil];
				}]];
				
				[ac addAction:[UIAlertAction actionWithTitle:@"Cancel"
													   style:UIAlertActionStyleCancel
													 handler:nil]];
				
				[self presentViewController:ac animated:YES completion:nil];
			} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
				UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:[[button.URL absoluteURL] description] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open in Safari", nil];
				[action showFromRect:button.frame inView:button.superview animated:YES];
#pragma clang diagnostic pop
			}
		}
	}
}

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateRecognized)
	{
		CGPoint location = [gesture locationInView:_textView];
		NSUInteger tappedIndex = [_textView closestCursorIndexToPoint:location];
		
		NSString *plainText = [_textView.attributedString string];
		NSString *tappedChar = [plainText substringWithRange:NSMakeRange(tappedIndex, 1)];
		
		__block NSRange wordRange = NSMakeRange(0, 0);
		
		[plainText enumerateSubstringsInRange:NSMakeRange(0, [plainText length]) options:NSStringEnumerationByWords usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			if (NSLocationInRange(tappedIndex, enclosingRange))
			{
				*stop = YES;
				wordRange = substringRange;
			}
		}];
		
		NSString *word = [plainText substringWithRange:wordRange];
		NSLog(@"%lu: '%@' word: '%@'", (unsigned long)tappedIndex, tappedChar, word);
	}
}

- (void)debugButton:(UIBarButtonItem *)sender
{
	[DTCoreTextLayoutFrame setShouldDrawDebugFrames:![DTCoreTextLayoutFrame shouldDrawDebugFrames]];
	[_textView.attributedTextContentView setNeedsDisplay];
}

- (void)screenshot:(UIBarButtonItem *)sender
{
	UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
	
	CGRect rect = [keyWindow bounds];
	UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[keyWindow.layer renderInContext:context];
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	[[UIPasteboard generalPasteboard] setImage:image];
}

#pragma mark - DTLazyImageViewDelegate

- (void)lazyImageView:(DTLazyImageView *)lazyImageView didChangeImageSize:(CGSize)size {
	NSURL *url = lazyImageView.url;
	CGSize imageSize = size;
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"contentURL == %@", url];
	
	BOOL didUpdate = NO;
	
	// update all attachments that match this URL (possibly multiple images with same size)
	for (DTTextAttachment *oneAttachment in [_textView.attributedTextContentView.layoutFrame textAttachmentsWithPredicate:pred])
	{
		// update attachments that have no original size, that also sets the display size
		if (CGSizeEqualToSize(oneAttachment.originalSize, CGSizeZero))
		{
			oneAttachment.originalSize = imageSize;
			
			didUpdate = YES;
		}
	}
	
	if (didUpdate)
	{
		// layout might have changed due to image sizes
		// do it on next run loop because a layout pass might be going on
		dispatch_async(dispatch_get_main_queue(), ^{
			[self->_textView relayoutText];
		});
	}
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
