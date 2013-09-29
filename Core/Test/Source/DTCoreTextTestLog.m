//
//  DTCoreTextTestLog.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 9/29/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreTextTestLog.h"

// GCOV Flush function
extern void __gcov_flush(void);

static id mainSuite = nil;

@implementation DTCoreTextTestLog

+ (void)initialize
{
	[[NSUserDefaults standardUserDefaults] setValue:@"DTCoreTextTestLog" forKey:SenTestObserverClassKey];
	
	[super initialize];
}

+ (void)testSuiteDidStart:(NSNotification *)notification
{
	[super testSuiteDidStart:notification];
	
	SenTestSuiteRun *suite = notification.object;
	
	if (mainSuite == nil)
	{
		mainSuite = suite;
	}
}

+ (void)testSuiteDidStop:(NSNotification *)notification
{
	[super testSuiteDidStop:notification];
	
	SenTestSuiteRun* suite = notification.object;
	
	if (mainSuite == suite)
	{
		// workaround for missing flush with iOS 7 Simulator
		__gcov_flush();
	}
}

@end
