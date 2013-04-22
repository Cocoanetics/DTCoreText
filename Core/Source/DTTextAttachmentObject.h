//
//  DTTextAttachmentObject.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 22.04.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTTextAttachment.h"

/**
 A specialized subclass in the DTTextAttachment class cluster to represent an generic object
 */

@interface DTTextAttachmentObject : DTTextAttachment <DTTextAttachmentHTMLPersistence>

/**
 The DTHTMLElement child nodes of the receiver. This array is only used for object tags at the moment.
 */
@property (nonatomic, strong) NSArray *childNodes;

@end
