//
//  DTHTMLParserNode.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 26.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTWeakSupport.h"

@class DTHTMLParserTextNode;

/**
 This class represents one node in an HTML DOM tree.
 */
@interface DTHTMLParserNode : NSObject
{
	NSDictionary *_attributes;
}

/**
 Designated initializer
 @param name The element name
 @param attributes The attributes dictionary
 @returns An initialized parser node.
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
@property (nonatomic, DT_WEAK_PROPERTY) DTHTMLParserNode *parentNode;

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
 Removes a child node from the receiver
 @param childNode The child node to remove
 */
- (void)removeChildNode:(DTHTMLParserNode *)childNode;

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
