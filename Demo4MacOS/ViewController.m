//
//  ViewController.m
//  DTCoreTextDemo4MacOS
//
//  Created by cntrump on 2017/8/19.
//  Copyright © 2017年 Drobnik.com. All rights reserved.
//

#import "ViewController.h"
#import "./UI/LinkButton.h"
#import "./UI/AttributedTextContentView.h"
#import <DTCoreText/NSAttributedStringRunDelegates.h>
#import <DTCoreText/DTImageTextAttachment.h>


@interface NSAttributedString (Emotion)

+ (NSAttributedString * _Nullable)dt_stringWithImageAttachment:(DTImage * _Nullable)image
												   displaySize:(CGSize)size
													 alignment:(DTTextAttachmentVerticalAlignment)alignment
														   url:(NSURL * _Nullable)url
													attributes:(NSDictionary * _Nonnull)attributes;

@end

@implementation NSAttributedString (Emotion)

+ (NSAttributedString * _Nullable)dt_stringWithImageAttachment:(DTImage * _Nullable)image
												   displaySize:(CGSize)size
													 alignment:(DTTextAttachmentVerticalAlignment)alignment
														   url:(NSURL * _Nullable)url
													attributes:(NSDictionary * _Nonnull)attributes {

	DTImageTextAttachment *imageAttachment = [[DTImageTextAttachment alloc] init];
	imageAttachment.contentURL = url;
	imageAttachment.displaySize = size;
	imageAttachment.verticalAlignment = alignment;
	imageAttachment.image = image;

	CTRunDelegateRef embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(imageAttachment);

	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];

	if (attributes != nil) {
		NSFont *font = attributes[NSFontAttributeName];

		NSParameterAssert(font != nil);

		if (font != nil) {
			CTFontRef ctfont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
			[imageAttachment adjustVerticalAlignmentForFont:ctfont];
			CFRelease(ctfont);
		}

		[tmpDict setDictionary:attributes];
	}

	tmpDict[(id)kCTRunDelegateAttributeName] = CFBridgingRelease(embeddedObjectRunDelegate);
	tmpDict[NSAttachmentAttributeName] = imageAttachment;

	return [[NSAttributedString alloc] initWithString:UNICODE_OBJECT_PLACEHOLDER attributes:tmpDict];
}

@end

@interface ViewController ()<AttributedTextContentViewDelegate> {
	AttributedTextContentView *_textContentView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.

	NSColor *linkColor = [NSColor colorWithRed:0x56/255.0 green:0x78/255.0 blue:0x95/255.0 alpha:1];
	NSURL *linkURL = [NSURL URLWithString:@"https://github.com"];
	NSString *linkUDID = @"1234567890";

	NSAttributedString *linkString = [[NSAttributedString alloc] initWithString:@"github" attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:15.0], NSForegroundColorAttributeName:linkColor, DTLinkAttribute:linkURL, DTGUIDAttribute:linkUDID}];

	NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Learn Git and GitHub without any code!\n" attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:15.0], NSForegroundColorAttributeName:[NSColor blackColor]}];
	[string appendAttributedString:linkString];

	NSAttributedString *emotionString = [NSAttributedString dt_stringWithImageAttachment:[NSImage imageNamed:@"moren_hashiqi_org"] displaySize:CGSizeMake(22.0, 22.0) alignment:DTTextAttachmentVerticalAlignmentBaseline url:nil attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:15.0]}];
	[string appendAttributedString:emotionString];

	_textContentView = [[AttributedTextContentView alloc] initWithFrame:self.view.bounds];
	_textContentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	_textContentView.delegate = self;
	_textContentView.shouldDrawLinks = NO;
	[self.view addSubview:_textContentView];

	_textContentView.attributedString = string;
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (NSView *)attributedTextContentView:(AttributedTextContentView *)attributedTextContentView viewForLink:(NSURL *)url identifier:(NSString *)identifier frame:(CGRect)frame {
	LinkButton *linkButton = [[LinkButton alloc] initWithFrame:frame];

	linkButton.image = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDefault];

	return linkButton;
}

@end
