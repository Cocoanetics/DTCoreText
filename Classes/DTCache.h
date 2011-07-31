//
//  DTCache.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 7/30/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>



// if we don't support 3.2 then we use NSCache directly
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_3_2
#define DTCache NSCache

#else

typedef enum
{
	DTCacheModeLegacy = 0,
	DTCacheModeModern
} DTCacheMode;

@interface DTCache : NSObject
{
	id _cache;  // NSCache or NSMutableDictionary
	
	DTCacheMode _cacheMode;
}

- (id)objectForKey:(id)key;
- (void)setObject:(id)obj forKey:(id)key;
- (void)removeAllObjects;

@end

#endif
