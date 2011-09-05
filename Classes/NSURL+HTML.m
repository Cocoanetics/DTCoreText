//
//  NSURL+HTML.m
//  PagingTextScroller
//
//  Created by Oliver Drobnik on 24.03.11.
//  Copyright 2011 Cocoanetics. All rights reserved.
//

#import "NSURL+HTML.h"


@implementation NSURL (HTML)

- (NSURL *)derivedBaseURL
{
    NSURL *baseURL = [self baseURL];
    
    if (baseURL) 
    {
        // we have a native baseURL
        return baseURL;
    }

    // need to derive it
    
    baseURL = [self URLByDeletingLastPathComponent];
    
    return baseURL;
}

@end
