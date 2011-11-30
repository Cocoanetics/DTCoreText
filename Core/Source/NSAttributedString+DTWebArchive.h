//
//  NSAttributedString+DTWebArchive.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 9/6/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTWebArchive;

@interface NSAttributedString (DTWebArchive)

- (id)initWithWebArchive:(DTWebArchive *)webArchive options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict;
- (DTWebArchive *)webArchive;

@end
