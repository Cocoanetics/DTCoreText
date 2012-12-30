//
//  DTHTMLParserNode.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 26.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTHTMLParserTextNode;

@interface DTHTMLParserNode : NSObject
{
	NSDictionary *_attributes;
}

/**
 Designated initializer
 */
- (id)initWithName:(NSString *)name attributes:(NSDictionary *)attributes;

/**
 The name of the receiver
 */
@property (nonatomic, copy) NSString *name;

/**
 The attributes of the receiver.
 */
@property (nonatomic, copy) NSDictionary *attributes;

/**
 A weak link to the parent node of the receiver
 */
@property (nonatomic, assign) DTHTMLParserNode *parentNode;

/**
 The child nodes of the receiver
 */
@property (nonatomic, readonly) NSArray *childNodes;

/**
 Adds a child node to the receiver. 
 @param childNode The child node to be appended to the list of children
 */
- (void)addChildNode:(DTHTMLParserNode *)childNode;

/**
 Removes all child nodes from the receiver
*/
- (void)removeAllChildNodes;

/**
 Hierarchy representation of the receiver including all attributes and children
 */
- (NSString *)debugDescription;

/**
 Concatenated contents of all text nodes
 */
- (NSString *)text;

@end
