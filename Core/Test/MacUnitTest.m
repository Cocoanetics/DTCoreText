//
//  MacUnitTest.m
//  MacUnitTest
//
//  Created by Oliver Drobnik on 22.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import "MacUnitTest.h"
#import "DTHTMLAttributedStringBuilder.h"

#import </usr/include/objc/objc-class.h>


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
		while ((testFile = [enumerator nextObject]) != nil) {
			if (![testFile hasSuffix:@"CurrentTest.html"])
			{
				// ignore other files, e.g. custom parameters in plist
				continue;
			}
			NSString *path = [testcasePath stringByAppendingPathComponent:testFile];
			NSURL *URL = [NSURL fileURLWithPath:path];
			
			NSString *caseName = testCaseNameFromURL(URL, NO);
			NSString *selectorName = [NSString stringWithFormat:@"test_%@", caseName];
			
			void(^impBlock)(MacUnitTest *) = ^(MacUnitTest *test) {
				[test internalTestCaseWithURL:URL withTempPath:tempPath];
			};
			
			IMP myIMP = imp_implementationWithBlock((__bridge void *)impBlock);
			
			SEL selector = NSSelectorFromString(selectorName);
			
			class_addMethod([self class], selector, myIMP, "v@:");
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
	NSData *testData = [NSData dataWithContentsOfURL:URL];
	
	// built in HTML parsing
	NSAttributedString *macAttributedString = [[NSAttributedString alloc] initWithHTML:testData 
																										options:nil documentAttributes:nil];

	NSString *macString = [macAttributedString string];

//	// our own builder
//	DTHTMLAttributedStringBuilder *doc = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:testData options:nil documentAttributes:NULL];
//
//	[doc buildString];
//	
//	NSString *iosString = [doc generatedAttributedString];
	
	// Create characters view
	NSMutableString *dumpOutput = [[NSMutableString alloc] init];
	NSData *dump = [macString dataUsingEncoding:NSUTF8StringEncoding];
	for (NSInteger i = 0; i < [dump length]; i++)
	{
		char *bytes = (char *)[dump bytes];
		char b = bytes[i];
		
		[dumpOutput appendFormat:@"%x %c\n", b, b];
	}

	
	NSLog(@"%@", dumpOutput);
//	NSLog(@"%@", iosString);
}

@end
