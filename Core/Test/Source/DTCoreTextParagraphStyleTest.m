//
//  DTCoreTextParagraphStyleTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 2/25/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreTextParagraphStyleTest.h"
#import "DTCoreTextParagraphStyle.h"

#import "DTCompatibility.h"
#import "DTVersion.h"

@interface DTCoreTextParagraphStyle ()

- (NSParagraphStyle *)NSParagraphStyle;
+ (DTCoreTextParagraphStyle *)paragraphStyleWithNSParagraphStyle:(NSParagraphStyle *)paragraphStyle;

@end

@implementation DTCoreTextParagraphStyleTest

// issue 498: loss of tab stops
- (void)testLossOfTabStops
{
	DTCoreTextParagraphStyle *paragraphStyle = [[DTCoreTextParagraphStyle alloc] init];
	[paragraphStyle addTabStopAtPosition:10 alignment:kCTTextAlignmentLeft];
	
	// create a CTParagraphStyle from it
	CTParagraphStyleRef ctParagraphStyle = [paragraphStyle createCTParagraphStyle];
	
	// create a new DT style from it
	DTCoreTextParagraphStyle *newParagraphStyle = [[DTCoreTextParagraphStyle alloc] initWithCTParagraphStyle:ctParagraphStyle];
	
	STAssertNotNil(newParagraphStyle.tabStops, @"There are no tab stops in newly created paragraph style");
}



#if DTCORETEXT_SUPPORT_NSPARAGRAPHSTYLE_TABS

- (void)_expectTextTab:(CTTextTabRef)textTab toBeAligned:(CTTextAlignment)aligment atLocation:(CGFloat)location
{
	CTTextAlignment tabAlignment = CTTextTabGetAlignment(textTab);
	CGFloat tabLocation = CTTextTabGetLocation(textTab);
	
	STAssertTrue(tabAlignment == aligment, @"tab alignment should be %d but is %d", aligment, tabAlignment);
	STAssertTrue(tabLocation == location, @"tab position should be %d but is %d", location, tabLocation);
}

- (void)testTabsOnNSParagraphStyle
{
	// this test doesn't work running before iOS 7
	#if TARGET_OS_IPHONE
	if ([DTVersion osVersionIsLessThen:@"7.0"])
	{
		return;
	}
	#endif
	
	DTCoreTextParagraphStyle *paragraphStyle = [[DTCoreTextParagraphStyle alloc] init];
	[paragraphStyle addTabStopAtPosition:10 alignment:kCTTextAlignmentLeft];
	[paragraphStyle addTabStopAtPosition:15 alignment:kCTTextAlignmentRight];
	[paragraphStyle addTabStopAtPosition:20 alignment:kCTTextAlignmentCenter];
	[paragraphStyle addTabStopAtPosition:25 alignment:kCTTextAlignmentJustified];
	[paragraphStyle addTabStopAtPosition:30 alignment:kCTTextAlignmentNatural];
	
	NSParagraphStyle *nsParagraphStyle = [paragraphStyle NSParagraphStyle];
	
	NSArray *tabStops = [nsParagraphStyle valueForKey:@"tabStops"];
	
	STAssertTrue([tabStops count]==5, @"There should be 2 tab stops");
	
	// test round drip
	
	DTCoreTextParagraphStyle *newParagraphStyle = [DTCoreTextParagraphStyle paragraphStyleWithNSParagraphStyle:nsParagraphStyle];
	
	NSUInteger tabCount = [newParagraphStyle.tabStops count];
	
	STAssertTrue(tabCount==5, @"There should be 2 tab stops");
	
	if (tabCount==5)
	{
		CTTextTabRef tab1 = (__bridge CTTextTabRef)([newParagraphStyle.tabStops objectAtIndex:0]);
		[self _expectTextTab:tab1 toBeAligned:kCTTextAlignmentLeft atLocation:10];

		CTTextTabRef tab2 = (__bridge CTTextTabRef)([newParagraphStyle.tabStops objectAtIndex:1]);
		[self _expectTextTab:tab2 toBeAligned:kCTTextAlignmentRight atLocation:15];

		CTTextTabRef tab3 = (__bridge CTTextTabRef)([newParagraphStyle.tabStops objectAtIndex:2]);
		[self _expectTextTab:tab3 toBeAligned:kCTTextAlignmentCenter atLocation:20];

		CTTextTabRef tab4 = (__bridge CTTextTabRef)([newParagraphStyle.tabStops objectAtIndex:3]);
		[self _expectTextTab:tab4 toBeAligned:kCTTextAlignmentJustified atLocation:25];

		CTTextTabRef tab5 = (__bridge CTTextTabRef)([newParagraphStyle.tabStops objectAtIndex:4]);
		[self _expectTextTab:tab5 toBeAligned:kCTTextAlignmentNatural atLocation:30];
	}
}
#endif

@end
