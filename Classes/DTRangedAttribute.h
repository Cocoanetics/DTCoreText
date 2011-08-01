//
//  DTRangedAttributes.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 7/31/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTRangedAttribute : NSObject
{
	NSRange _range;
	id _key;
	id _value;
}

+ (DTRangedAttribute *)rangedAttribute:(id)key value:(id)value forRange:(NSRange)range;
- (id)initWithAttribute:(id)key value:(id)value forRange:(NSRange)range;

@property (nonatomic, assign) NSRange range;
@property (nonatomic, copy) id key;
@property (nonatomic, retain) id value;

@end
