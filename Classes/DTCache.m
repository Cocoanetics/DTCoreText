//
//  DTCache.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 7/30/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCache.h"

// if we support 3.2 we need this implementation otherwise we use NSCache directly
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_4_0

@implementation DTCache

- (id)init
{
    self = [super init];
    if (self) 
	{
		if (NSStringFromClass([NSCache class]) != nil)
		{
			_cacheMode = DTCacheModeModern;
			
			_cache = [[NSCache alloc] init];
		}
		else
		{
			_cacheMode = DTCacheModeLegacy;
			
			_cache = [[NSMutableDictionary alloc] init];
			
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
		}
    }
    
    return self;
}

- (void)dealloc
{
	if (_cacheMode == DTCacheModeLegacy)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}
	
	[_cache release];
	
	[super dealloc];
}

#pragma mark Passthrough Methods

// methods common on NSCache/NSMutableDictionary

- (id)objectForKey:(id)key
{
	return [_cache objectForKey:key];
}

- (void)setObject:(id)obj forKey:(id)key
{
	[_cache setObject:obj forKey:key];
}

- (void)removeAllObjects
{
	[_cache removeAllObjects];
}

#pragma mark Memory

- (void)didReceiveMemoryWarning
{
	// empty cache
	[self removeAllObjects];
}

@end

#endif
