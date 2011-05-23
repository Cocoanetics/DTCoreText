//
//  DTLazyImageView.h
//  PagingTextScroller
//
//  Created by Oliver Drobnik on 5/20/11.
//  Copyright 2011 . All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DTLazyImageView : UIImageView 
{
	NSURL *_url;
	
	NSURLConnection *_connection;
	NSMutableData *_receivedData;
}

@property (nonatomic, retain) NSURL *url;

- (void)cancelLoading;

@end
