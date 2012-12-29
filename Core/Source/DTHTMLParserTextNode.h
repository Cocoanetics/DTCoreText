//
//  DTHTMLParserTextNode.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 26.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLParserNode.h"

@interface DTHTMLParserTextNode : DTHTMLParserNode

- (id)initWithCharacters:(NSString *)characters;

/**
 Returns the receivers character contents
 */
@property (nonatomic, readonly) NSString *characters;

@end
