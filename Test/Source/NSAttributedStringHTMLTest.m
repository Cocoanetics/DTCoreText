//
//  NSAttributedStringHTMLTest.m
//  DTCoreText
//
//  Created by Claus Broch on 11/01/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSAttributedStringHTMLTest.h"
#import <DTCoreText/DTCoreText.h>
#import <XCTest/XCTest.h>


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
	NSString *resultOnIOS = [self hexStringForData:dump];
	
	NSString *resultOnMac = @"5072656669780a4f6e652074776f20e280a874687265650a4e6577205061726167726170680a537566666978";
	
	//[self dumpOneResult:resultOnIOS versusOtherResult:resultOnMac];
	
	XCTAssertTrue([resultOnIOS isEqualToString:resultOnMac], @"Output on Paragraph Test differs");
}


- (void)testHeaderParagraphs
{
	NSString *html = @"Prefix<h1>One</h1><h2>One</h2><h3>One</h3><h4>One</h4><h5>One</h5><p>New Paragraph</p>Suffix";
	NSAttributedString *string = [self attributedStringFromHTML:html];
	
	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [self hexStringForData:dump];
	
	NSString *resultOnMac = @"5072656669780a4f6e650a4f6e650a4f6e650a4f6e650a4f6e650a4e6577205061726167726170680a537566666978";
	
	XCTAssertTrue([resultOnIOS isEqualToString:resultOnMac], @"Output on Paragraph Test differs");
}


- (void)testListParagraphs
{
	NSString *html = @"<p>Before</p><ul><li>One</li><li>Two</li></ul><p>After</p>";	
	NSAttributedString *string = [self attributedStringFromHTML:html];
	
	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [self hexStringForData:dump];
	
	NSString *resultOnMac = @"4265666f72650a09e280a2094f6e650a09e280a20954776f0a41667465720a";
	
	XCTAssertTrue([resultOnIOS isEqualToString:resultOnMac], @"Output on List Test differs");
}

- (void)testImageParagraphs
{
	// needs the size
	NSString *html = @"<p>Before</p><img src=\"Oliver.jpg\"><h1>Header</h2><p>after</p><p>Some inline <img width=\"20px\" height=\"20px\" src=\"Oliver.jpg\"> text.</p>";
	NSAttributedString *string = [self attributedStringFromHTML:html];

	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [self hexStringForData:dump];
	
	NSString *resultOnMac = @"4265666f72650aefbfbc0a4865616465720a61667465720a536f6d6520696e6c696e6520efbfbc20746578742e0a";
	
	XCTAssertTrue([resultOnIOS isEqualToString:resultOnMac], @"Output on List Test differs");
}

- (void)testSpaceNormalization
{
	NSString *html = @"<p>Now there is some <b>bold</b>\ntext and  spaces\n    should be normalized.</p>";	
	NSAttributedString *string = [self attributedStringFromHTML:html];

	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [self hexStringForData:dump];
	
	NSString *resultOnMac = @"4e6f7720746865726520697320736f6d6520626f6c64207465787420616e64207370616365732073686f756c64206265206e6f726d616c697a65642e0a";
	
	XCTAssertTrue([resultOnIOS isEqualToString:resultOnMac], @"Output on List Test differs");
}

- (void)testSpaceAndNewlines
{
	NSString *html = @"<a>bla</a>\nfollows\n<font color=\"blue\">NSString</font> <font color=\"purple\">*</font>str <font color=\"#000000\">=</font> @<font color=\"#E40000\">\"The Quick Brown Fox Brown\"</font>;";
	NSAttributedString *string = [self attributedStringFromHTML:html];

	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [self hexStringForData:dump];
	
	NSString *resultOnMac = @"626c6120666f6c6c6f7773204e53537472696e67202a737472203d20402254686520517569636b2042726f776e20466f782042726f776e223b";
	
	XCTAssertTrue([resultOnIOS isEqualToString:resultOnMac], @"Output on List Test differs");
}

- (void)testMissingClosingTagAndSpacing
{
	NSString *html = @"<span>image \n <a href=\"http://sv.wikipedia.org/wiki/Fil:V%C3%A4dersoltavlan_cropped.JPG\"\n late</a> last</span>";
	NSAttributedString *string = [self attributedStringFromHTML:html];

	NSData *dump = [[string string] dataUsingEncoding:NSUTF8StringEncoding];
	NSString *resultOnIOS = [self hexStringForData:dump];
	
	NSString *resultOnMac = @"696d616765206c617374";
	
	XCTAssertTrue([resultOnIOS isEqualToString:resultOnMac], @"Output on Invalid Tag Test differs");
}

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

// issue #1199
- (void)testDefaultFont
{
	// This string is the simplest case that caused the crash.
	NSString *html = @"<p>Hello World!</p>";
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *options = @{};
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTMLData:data
																	  options:options
														   documentAttributes:NULL];
	
	UIFont *font = [string attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
	
	UIFontDescriptor *descriptor = [font fontDescriptor];
	BOOL isBold = (descriptor.symbolicTraits & UIFontDescriptorTraitBold) != 0;
	XCTAssertFalse(isBold);
	
	BOOL isItalic = (descriptor.symbolicTraits & UIFontDescriptorTraitItalic) != 0;
	XCTAssertFalse(isItalic);
	
	XCTAssertTrue([font.familyName isEqualToString:@"Times New Roman"]);
}

// issue #1208
- (void)testDefaultFontBold
{
	// This string is the simplest case that caused the crash.
	NSString *html = @"<b>Hello World!</b>";
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *options = @{};
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTMLData:data
																	  options:options
														   documentAttributes:NULL];
	
	UIFont *font = [string attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
	
	UIFontDescriptor *descriptor = [font fontDescriptor];
	BOOL isBold = (descriptor.symbolicTraits & UIFontDescriptorTraitBold) != 0;
	XCTAssertTrue(isBold);
	
	BOOL isItalic = (descriptor.symbolicTraits & UIFontDescriptorTraitItalic) != 0;
	XCTAssertFalse(isItalic);
	
	XCTAssertTrue([font.familyName isEqualToString:@"Times New Roman"]);
}

- (void)testDefaultFontItalic
{
	// This string is the simplest case that caused the crash.
	NSString *html = @"<em>Hello World!</em>";
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *options = @{};
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTMLData:data
																	  options:options
														   documentAttributes:NULL];
	
	UIFont *font = [string attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
	
	UIFontDescriptor *descriptor = [font fontDescriptor];
	BOOL isBold = (descriptor.symbolicTraits & UIFontDescriptorTraitBold) != 0;
	XCTAssertFalse(isBold);
	
	BOOL isItalic = (descriptor.symbolicTraits & UIFontDescriptorTraitItalic) != 0;
	XCTAssertTrue(isItalic);
	
	XCTAssertTrue([font.familyName isEqualToString:@"Times New Roman"]);
}
- (NSString *)hexStringForData:(NSData *)data
{
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    NSMutableString *hex = [NSMutableString new];
	
    for (NSInteger i = 0; i < data.length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
	
    return [hex copy];
}

@end
