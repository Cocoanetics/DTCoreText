//
//  NSTextAttachment.h
//  CoreTextExtensions
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DTTextAttachment : NSObject {
	CGSize size;
	id contents;
}

@property (nonatomic, assign) CGSize size;
@property (nonatomic, retain) id contents;

@end
