//
//  MacUnitTest.m
//  MacUnitTest
//
//  Created by Oliver Drobnik on 22.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import "MacUnitTest.h"

#if !TARGET_OS_IOS

@import DTCoreText;
@import AppKit;

#define TESTCASE_FILE_EXTENSION @"html"
//#define ONLY_TEST_CURRENT 1


@implementation MacUnitTest


NSString *testCaseNameFromURL(NSURL *URL, BOOL withSpaces);

NSString *testCaseNameFromURL(NSURL *URL, BOOL withSpaces)
{
	NSString *fileName = [[URL path] lastPathComponent];
	NSString *name = [fileName stringByDeletingPathExtension];
	if (withSpaces)
	{
		name = [name stringByReplacingOccurrencesOfString:@"_" withString:@" "];
	}
	
	return name;
}

+ (void)initialize
{
	if (self == [MacUnitTest class])
	{
		// get list of test case files
		NSBundle *unitTestBundle = [NSBundle bundleForClass:self];
		NSString *testcasePath = [unitTestBundle resourcePath];
		
		// make one temp folder for all cases
		NSString *timeStamp = [NSString stringWithFormat:@"%.0f", [NSDate timeIntervalSinceReferenceDate] * 1000.0];
		NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:timeStamp];
		
		NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:testcasePath];
		
		NSString *testFile = nil;
		while ((testFile = [enumerator nextObject]) != nil) 
		{
#if ONLY_TEST_CURRENT
		if (![[testFile lastPathComponent] isEqualToString:@"CurrentTest.html"])
		{
			continue;
		}
#else
			if ([[testFile lastPathComponent] isEqualToString:@"CurrentTest.html"])
			{
				continue;
			}
#endif
			
			if (![[testFile pathExtension] isEqualToString:TESTCASE_FILE_EXTENSION])
			{
				// ignore other files, e.g. custom parameters in plist
				continue;
			}
			
			NSString *path = [testcasePath stringByAppendingPathComponent:testFile];
			NSURL *URL = [NSURL fileURLWithPath:path];
			
			NSString *caseName = testCaseNameFromURL(URL, NO);
			NSString *selectorName = [NSString stringWithFormat:@"test_%@", caseName];
			
			[MacUnitTest addInstanceMethodWithSelectorName:selectorName block:^(MacUnitTest *test) {
				[test internalTestCaseWithURL:URL withTempPath:tempPath];
			}];
		}
	}
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)internalTestCaseWithURL:(NSURL *)URL withTempPath:(NSString *)tempPath
{
	// get optional test case parameters
	NSString *parameterFile = [[[URL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"];
	NSDictionary *testParameters = [NSDictionary dictionaryWithContentsOfFile:parameterFile];
	
	if ([[testParameters objectForKey:@"SkipUnitTest"] boolValue])
	{
		return;
	}
	
	// use utf16 internally, otherwise the MAC version chokes on the ArabicTest
	NSStringEncoding encoding = 0;
	NSString *testString = [NSString stringWithContentsOfURL:URL usedEncoding:&encoding error:NULL];
	NSData *testData = [testString dataUsingEncoding:NSUTF16StringEncoding];
	
	// built in HTML parsing
	NSError *error = nil;
	NSDictionary *docAttributes;
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:NSHTMLTextDocumentType, NSDocumentTypeDocumentOption, @"utf16", NSTextEncodingNameDocumentOption, nil];
	NSAttributedString *macAttributedString = [[NSAttributedString alloc] initWithData:testData options:options documentAttributes:&docAttributes error:&error];

	NSString *macString = [macAttributedString string];

	// our own builder
	DTHTMLAttributedStringBuilder *doc = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:testData options:nil documentAttributes:NULL];
	doc.shouldKeepDocumentNodeTree = YES;

	NSAttributedString *iosAttributedString = [doc generatedAttributedString];
	NSString *iosString = [iosAttributedString string];
	
/*
	NSMutableString *dumpOutput = [[NSMutableString alloc] init];
	NSData *dump = [macString dataUsingEncoding:NSUTF8StringEncoding];
	for (NSInteger i = 0; i < [dump length]; i++)
	{
		char *bytes = (char *)[dump bytes];
		char b = bytes[i];
		
		[dumpOutput appendFormat:@"%d: %x %c\n", i, b, b];
	}
	
	dump = [iosString dataUsingEncoding:NSUTF8StringEncoding];
	for (NSInteger i = 0; i < [dump length]; i++)
	{
		char *bytes = (char *)[dump bytes];
		char b = bytes[i];
		
		[dumpOutput appendFormat:@"%d: %x %c\n", i, b, b];
	}
	
	NSLog(@"%@\n\n", dumpOutput);

	
	NSDictionary *attributes = nil;
	NSRange effectiveRange = NSMakeRange(0, 0);
	
		while ((attributes = [macAttributedString attributesAtIndex:effectiveRange.location effectiveRange:&effectiveRange]))
		{
			[dumpOutput appendFormat:@"Range: (%d, %d), %@\n\n", effectiveRange.location, effectiveRange.length, attributes];
			effectiveRange.location += effectiveRange.length;
			
			if (effectiveRange.location >= [macString length])
			{
				break;
			}
		}
	
	
	NSLog(@"%@", dumpOutput);
	
	NSParagraphStyle *para = [macAttributedString attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
	NSTextList *list = [para.textLists lastObject];
	
	*/

	XCTAssertEqual([macString length], [iosString length], @"String output has different length");
	
	BOOL ignoreCase = [[testParameters objectForKey:@"IgnoreCase"] boolValue];
	BOOL ignoreNonAlphanumericCharacters = [[testParameters objectForKey:@"IgnoreNonAlphanumericCharacters"] boolValue];
	
	
	if (![macString isEqualToString:iosString])
	{
		NSInteger shorterLength =  MIN([macString length], [iosString length]);
		
		for (NSInteger i=0; i<shorterLength; i++)
		{
			NSRange range = NSMakeRange(i, 1);

			NSString *ios = [iosString substringWithRange:range];			
			NSString *mac = [macString substringWithRange:range];			

			BOOL isSame = NO;
			
			if (ignoreCase)
			{
				isSame = ([ios caseInsensitiveCompare:mac] == NSOrderedSame);
			}
			else
			{
				isSame = ([ios isEqualToString:mac]);
			}
			
			if (!isSame)
			{
				if (ignoreNonAlphanumericCharacters)
				{
					NSCharacterSet *charSet = [NSCharacterSet alphanumericCharacterSet];
					
					if (![charSet characterIsMember:[ios characterAtIndex:0]] && ![charSet characterIsMember:[mac characterAtIndex:0]])
					{
						isSame = YES;
					}
				}
				
				if (!isSame)
				{
					XCTFail(@"First differing character at index %ld: iOS '%@' versus Mac '%@'", (long)i, [ios stringByAddingHTMLEntities] , [mac stringByAddingHTMLEntities]);
				}
				break;
			}
		}
	}
}

/**
 Tests that an 8pt font-size and a 8px font-size turn out the same font sizes
 */
- (void)testPixelsVersusPoints
{
	NSString *HTML = @"<span style=\"font-size:8pt;\">8 pt</span><span style=\"font-size:8px;\">8 px</span>";
	NSData *data = [HTML dataUsingEncoding:NSUTF8StringEncoding];
	
	// create Mac version
	NSAttributedString *macString = [[NSAttributedString alloc] initWithHTML:data baseURL:nil documentAttributes:NULL];

	NSRange firstFontRangeMac;
	NSFont *firstFontMac = [macString attribute:(id)kCTFontAttributeName atIndex:0 effectiveRange:&firstFontRangeMac];
	CGFloat firstFontMacPoints = [firstFontMac pointSize];

	NSRange secondFontRangeMac;
	id secondFontMac = [macString attribute:(id)kCTFontAttributeName atIndex:NSMaxRange(firstFontRangeMac) effectiveRange:&secondFontRangeMac];
	CGFloat secondFontMacPoints = [secondFontMac pointSize];
	
	// create DTCoreText/iOS version
	
	DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:nil documentAttributes:NULL];
	
	NSAttributedString *iosString = [builder generatedAttributedString];

	NSRange firstFontRangeiOS;
	CTFontRef firstFontiOS = (__bridge CTFontRef)[iosString attribute:(id)kCTFontAttributeName atIndex:0 effectiveRange:&firstFontRangeiOS];
	CGFloat firstFontiOSPoints = CTFontGetSize(firstFontiOS);
	
	NSRange secondFontRangeiOS;
	CTFontRef secondFontiOS = (__bridge CTFontRef)[iosString attribute:(id)kCTFontAttributeName atIndex:NSMaxRange(firstFontRangeiOS) effectiveRange:&secondFontRangeiOS];
	CGFloat secondFontiOSPoints = CTFontGetSize(secondFontiOS);

	XCTAssertEqual(firstFontMacPoints, firstFontiOSPoints, @"First Font should be same size");
	XCTAssertEqual(secondFontMacPoints, secondFontiOSPoints, @"Second Font should be same size");
}

/**
 // this is included in the above, but I left it to get things
- (void)testAppleConverted
{
	NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"AppleConverted" ofType:@"html"];
	NSData *data = [NSData dataWithContentsOfFile:path];
	
	NSAttributedString *macString = [[NSAttributedString alloc] initWithHTML:data baseURL:nil documentAttributes:NULL];
	
	NSMutableString *dumpOutput = [[NSMutableString alloc] init];
	NSData *dump = [[macString string] dataUsingEncoding:NSUTF8StringEncoding];
	for (NSInteger i = 0; i < [dump length]; i++)
	{
		char *bytes = (char *)[dump bytes];
		char b = bytes[i];
		
		[dumpOutput appendFormat:@"%d: %x %c\n", i, b, b];
	}
	
	NSLog(@"%@\n\n", dumpOutput);
}
 */

@end

#endif
