//
//  DTRangedAttributesOptimizer.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 7/31/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DTRangedAttribute.h"

@interface DTRangedAttributesOptimizer : NSObject
{
	NSMutableDictionary *_attributeIndex;
	NSMutableArray *_attributes;

	BOOL _didMerge;
}

@property (nonatomic, readonly) BOOL didMerge;

- (void)addAttribute:(DTRangedAttribute *)attribute;
- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range;


- (NSArray *)allKeys;
- (NSArray *)rangedAttributesForKey:(id)key;

@end
