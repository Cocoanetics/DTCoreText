//
//  NSAttributedStringHTMLTest.m
//  CoreTextExtensions
//
//  Created by Claus Broch on 11/01/11.
//  Copyright 2011 Infinite Loop. All rights reserved.
//

#import "NSAttributedStringHTMLTest.h"
#import "NSAttributedString+HTML.h"

@implementation NSAttributedStringHTMLTest


- (void)testParagraphs
{
	NSString *html = @"Prefix<p>One\ntwo\n<br>three</p><p>New Paragraph</p>Suffix";
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:NULL];
	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [dump description];
	
	NSString *resultOnMac = @"<50726566 69780a4f 6e652074 776f20e2 80a87468 7265650a 4e657720 50617261 67726170 680a5375 66666978>";
	
	STAssertEqualObjects(resultOnIOS, resultOnMac, @"Output on Paragraph Test differs");
}


- (void)testHeaderParagraphs
{
	NSString *html = @"Prefix<h1>One</h1><h2>One</h2><h3>One</h3><h4>One</h4><h5>One</h5><p>New Paragraph</p>Suffix";
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:NULL];
	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [dump description];
	
	NSString *resultOnMac = @"<50726566 69780a4f 6e650a4f 6e650a4f 6e650a4f 6e650a4f 6e650a4e 65772050 61726167 72617068 0a537566 666978>";
	
	STAssertEqualObjects(resultOnIOS, resultOnMac, @"Output on Paragraph Test differs");
}


- (void)testListParagraphs
{
	NSString *html = @"<p>Before</p><ul><li>One</li><li>Two</li></ul><p>After</p>";	
	
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:NULL];
	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [dump description];
	
	NSString *resultOnMac = @"<4265666f 72650a09 e280a209 4f6e650a 09e280a2 0954776f 0a416674 65720a>";
	
	STAssertEqualObjects(resultOnIOS, resultOnMac, @"Output on List Test differs");
}


@end
