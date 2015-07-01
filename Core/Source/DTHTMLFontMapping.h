//
//  DTHTMLWriterFontMapping.h
//  DTCoreText
//
//  Created by Mark Zeller on 23/06/15.
//  Copyright (c) 2015 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTHTMLFontMapping : NSObject

@property (nonatomic, copy) NSString *sourceFontName;
@property (nonatomic, copy) NSString *targetFontName;
@property (nonatomic, copy) NSString *targetFontFamily;

@end
