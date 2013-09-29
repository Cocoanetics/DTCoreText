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

@implementation DTCoreTextTestLog

+ (void)initialize
{
	[[NSUserDefaults standardUserDefaults] setValue:@"DTCoreTextTestLog"
														  forKey:SenTestObserverClassKey];
	
	[super initialize];
}

+ (void)testSuiteDidStop:(NSNotification *)notification
{
	[super testSuiteDidStop:notification];
	
	// workaround for missing flush with iOS 7 Simulator
	__gcov_flush();
}

@end
