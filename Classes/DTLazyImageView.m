//
//  DTLazyImageView.m
//  PagingTextScroller
//
//  Created by Oliver Drobnik on 5/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DTLazyImageView.h"


@implementation DTLazyImageView

- (void)dealloc
{
	self.image = nil;
	[_url release];
	
	[super dealloc];
}

- (void)loadImageAtURL:(NSURL *)url
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSData *data = [[NSData alloc] initWithContentsOfURL:url];
	
	if (data)
	{
		UIImage *image = [[UIImage alloc] initWithData:data];
		
		[self performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
		
		[image release];
	}
	
	[data release];
	
	_loading = NO;
	
	[pool release];
}

- (void)didMoveToSuperview
{
	if (!self.image && _url && !_loading)
	{
		_loading = YES;
		[self performSelectorInBackground:@selector(loadImageAtURL:) withObject:_url];
	}	
}


#pragma mark Properties

@synthesize url = _url;

@end
