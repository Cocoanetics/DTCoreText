//
//  DTLazyImageView.h
//  PagingTextScroller
//
//  Created by Oliver Drobnik on 5/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DTLazyImageView : UIImageView 
{
	NSURL *_url;
	
	BOOL _loading;
}

@property (nonatomic, retain) NSURL *url;

@end
