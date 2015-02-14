//
//  NSAttributedStringHTMLTest.m
//  DTCoreText
//
//  Created by Claus Broch on 11/01/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSAttributedStringHTMLTest.h"
#import "NSAttributedString+HTML.h"

#import "NSAttributedString+DTCoreText.h"

#import "DTHTMLAttributedStringBuilder.h"

@implementation NSAttributedStringHTMLTest

- (void)dumpOneResult:(NSString *)oneResult versusOtherResult:(NSString *)otherResult
{
	NSMutableString *dumpOutput = [[NSMutableString alloc] init];
	NSData *dump1 = [oneResult dataUsingEncoding:NSUTF8StringEncoding];
	NSData *dump2 = [otherResult dataUsingEncoding:NSUTF8StringEncoding];
	
	char *bytes1 = (char *)[dump1 bytes];
	char *bytes2 = (char *)[dump2 bytes];

	NSUInteger longerLength = MAX([dump1 length], [dump2 length]);
	
	for (NSInteger i = 0; i < longerLength; i++)
	{
		NSString *out1 = @"- -";
		NSString *out2 = @"- -";
		
		if (i<[dump1 length])
		{
			char b = bytes1[i];
			out1 = [NSString stringWithFormat:@"%x", b];
		}
		
		if (i<[dump2 length])
		{
			char b = bytes2[i];
			out2 = [NSString stringWithFormat:@"%x", b];
		}

		
		[dumpOutput appendFormat:@"%li: %@ %@\n", (long)i, out1, out2];
	}

	NSLog(@"Dump\%@", dumpOutput);
}

- (NSAttributedString *)attributedStringFromHTML:(NSString *)html
{
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	DTHTMLAttributedStringBuilder*stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:nil documentAttributes:NULL];

	return [stringBuilder generatedAttributedString];
}

- (void)testParagraphs
{
	NSString *html = @"Prefix<p>One\ntwo\n<br>three</p><p>New Paragraph</p>Suffix";
	NSAttributedString *string = [self attributedStringFromHTML:html];
	
	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [dump description];
	
	NSString *resultOnMac = @"<50726566 69780a4f 6e652074 776f20e2 80a87468 7265650a 4e657720 50617261 67726170 680a5375 66666978>";
	
	//[self dumpOneResult:resultOnIOS versusOtherResult:resultOnMac];
	
	XCTAssertEqualObjects(resultOnIOS, resultOnMac, @"Output on Paragraph Test differs");
}


- (void)testHeaderParagraphs
{
	NSString *html = @"Prefix<h1>One</h1><h2>One</h2><h3>One</h3><h4>One</h4><h5>One</h5><p>New Paragraph</p>Suffix";
	NSAttributedString *string = [self attributedStringFromHTML:html];
	
	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [dump description];
	
	NSString *resultOnMac = @"<50726566 69780a4f 6e650a4f 6e650a4f 6e650a4f 6e650a4f 6e650a4e 65772050 61726167 72617068 0a537566 666978>";
	
	XCTAssertEqualObjects(resultOnIOS, resultOnMac, @"Output on Paragraph Test differs");
}


- (void)testListParagraphs
{
	NSString *html = @"<p>Before</p><ul><li>One</li><li>Two</li></ul><p>After</p>";	
	NSAttributedString *string = [self attributedStringFromHTML:html];
	
	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [dump description];
	
	NSString *resultOnMac = @"<4265666f 72650a09 e280a209 4f6e650a 09e280a2 0954776f 0a416674 65720a>";
	
	XCTAssertEqualObjects(resultOnIOS, resultOnMac, @"Output on List Test differs");
}

- (void)testImageParagraphs
{
	// needs the size
	NSString *html = @"<p>Before</p><img src=\"Oliver.jpg\"><h1>Header</h2><p>after</p><p>Some inline <img width=\"20px\" height=\"20px\" src=\"Oliver.jpg\"> text.</p>";
	NSAttributedString *string = [self attributedStringFromHTML:html];

	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [dump description];
	
	NSString *resultOnMac = @"<4265666f 72650aef bfbc0a48 65616465 720a6166 7465720a 536f6d65 20696e6c 696e6520 efbfbc20 74657874 2e0a>";
	
	XCTAssertEqualObjects(resultOnIOS, resultOnMac, @"Output on List Test differs");
}

- (void)testSpaceNormalization
{
	NSString *html = @"<p>Now there is some <b>bold</b>\ntext and  spaces\n    should be normalized.</p>";	
	NSAttributedString *string = [self attributedStringFromHTML:html];

	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [dump description];
	
	NSString *resultOnMac = @"<4e6f7720 74686572 65206973 20736f6d 6520626f 6c642074 65787420 616e6420 73706163 65732073 686f756c 64206265 206e6f72 6d616c69 7a65642e 0a>";
	
	XCTAssertEqualObjects(resultOnIOS, resultOnMac, @"Output on List Test differs");
}

- (void)testSpaceAndNewlines
{
	NSString *html = @"<a>bla</a>\nfollows\n<font color=\"blue\">NSString</font> <font color=\"purple\">*</font>str <font color=\"#000000\">=</font> @<font color=\"#E40000\">\"The Quick Brown Fox Brown\"</font>;";
	NSAttributedString *string = [self attributedStringFromHTML:html];

	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [dump description];
	
	NSString *resultOnMac = @"<626c6120 666f6c6c 6f777320 4e535374 72696e67 202a7374 72203d20 40225468 65205175 69636b20 42726f77 6e20466f 78204272 6f776e22 3b>";
	
	XCTAssertEqualObjects(resultOnIOS, resultOnMac, @"Output on List Test differs");
}

- (void)testMissingClosingTagAndSpacing
{
	NSString *html = @"<span>image \n <a href=\"http://sv.wikipedia.org/wiki/Fil:V%C3%A4dersoltavlan_cropped.JPG\"\n late</a> last</span>";
	NSAttributedString *string = [self attributedStringFromHTML:html];

	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [dump description];
	
	NSString *resultOnMac = @"<696d6167 65206c61 7374>";
	
	XCTAssertEqualObjects(resultOnIOS, resultOnMac, @"Output on Invalid Tag Test differs");
	
}

/*
- (void)testAttributedStringColorToHTML
{
	NSMutableAttributedString *string = [[NSMutableAttributedString alloc]initWithString: @"test"];
	
	UIColor *color = [ UIColor colorWithRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0 ];

	[ string setAttributes: [ NSDictionary dictionaryWithObject: (id)color.CGColor forKey: (id)kCTForegroundColorAttributeName ] range: NSMakeRange(0, 2) ];	
	
	NSString *expected = @"<span><span style=\"color:#ff0000;\">te</span>st</span>\n";

	STAssertEqualObjects([ string htmlString ], expected, @"Output on HTML string color test differs");
}
 */

- (void)testCrashAtEmptyNodeBeforeDivWithiOS6Attributes
{
	// This string is the simplest case that caused the crash.
	NSString *html = @"<div><i></i><div></div></div>;";
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *options = @{DTUseiOS6Attributes: @(YES)};
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTMLData:data
																	  options:options
														   documentAttributes:NULL];
	XCTAssert(string != nil);
}

@end
