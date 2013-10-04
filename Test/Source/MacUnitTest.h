//
//  MacUnitTest.h
//  MacUnitTest
//
//  Created by Oliver Drobnik on 22.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface MacUnitTest : SenTestCase

- (void)internalTestCaseWithURL:(NSURL *)URL withTempPath:(NSString *)tempPath;

@end
