//
//  DTCoreTextMacDemoView.m
//  DTCoreText
//
//  Created by Michael Markowski on 11/27/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreTextMacDemoView.h"
#import "DTCoreText.h"

@implementation DTCoreTextMacDemoView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        DTMacAttributedTextView *textView = [[DTMacAttributedTextView alloc] initWithFrame:CGRectMake(60, 100, 640, 650)];
		[textView setWantsLayer:YES];
        
		[textView setAutohidesScrollers:NO];
		[textView setHasVerticalScroller:YES];

        NSString *path2html = [[NSBundle mainBundle] pathForResource:@"text.html" ofType:nil];
        NSString *path2css = [[NSBundle mainBundle] pathForResource:@"text.css" ofType:nil];
        NSString *html = [[NSString alloc] initWithContentsOfFile:path2html encoding:NSUTF8StringEncoding error:nil];
        NSString *css = [[NSString alloc] initWithContentsOfFile:path2css encoding:NSUTF8StringEncoding error:nil];
        
        NSAttributedString *attString = [DTCoreTextMacDemoView attributedStringWithText:html style:css];
        NSLog(@"attString: %@\nstyle: %@", attString, css);
        
		[textView setBackgroundColor:[NSColor yellowColor]];
        [textView setAttributedString:attString];
        
        [self addSubview:textView];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

+ (NSAttributedString *)attributedStringWithText:(NSString *)theText style:(NSString *)theStyle
{
    
    NSMutableString *htmlText = [NSMutableString string];
    NSString *style = theStyle ? theStyle : @"";
    
    [htmlText appendFormat:@"<html><head><style>%@</style></head><body>", style];
    
    if (theText) {
        [htmlText appendString:theText];
    }
    
    [htmlText appendString:@"</body>\n</html>\n"];
    
    
	DTHTMLAttributedStringBuilder *stringBuilder = nil;
    NSData *htmlData = [htmlText dataUsingEncoding:NSUTF8StringEncoding];
    
    if (stringBuilder == nil) {
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        
        DTCSSStylesheet *css = [[DTCSSStylesheet alloc] initWithStyleBlock:@"\
                                p {\
                                display:block;\
                                -webkit-margin-before:0;\
                                -webkit-margin-after:0;\
                                -webkit-margin-start:0;\
                                -webkit-margin-end:0;\
                                }"];
        [options setValue:css forKey:DTDefaultStyleSheet];
        
        stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:htmlData options:options documentAttributes:NULL];
        void (^callBackBlock)(DTHTMLElement *element) = [options objectForKey:DTWillFlushBlockCallBack];
        
        if (callBackBlock)
        {
            [stringBuilder setWillFlushCallback:callBackBlock];
        }
        
    } else {
        [stringBuilder prepareForReuse];
        stringBuilder.data = htmlData;
    }
    
	
	// This needs to be on a seprate line so that ARC can handle releasing the object properly
	// return [stringBuilder generatedAttributedString]; shows leak in instruments
	id string = [stringBuilder generatedAttributedString];
    
    NSAttributedString *attrString = string;
    //    NSAttributedString *attrString = [[NSAttributedString alloc] initWithHTMLData:[htmlText dataUsingEncoding:NSUTF16StringEncoding] options:options documentAttributes:NULL];
    return attrString;
}

@end
