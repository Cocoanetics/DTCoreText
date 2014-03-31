//
//  DTTextAttachmentImage.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 22.04.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTTextAttachment.h"

@class DTImage;

/**
 A specialized subclass in the DTTextAttachment class cluster to represent an embedded image
 */

@interface DTImageTextAttachment : DTTextAttachment <DTTextAttachmentDrawing, DTTextAttachmentHTMLPersistence>

/**
 The designated initializer which will be called by [DTTextAttachment textAttachmentWithElement:options:] for image attachments.
 @param element A DTHTMLElement that must have a valid tag name and should have a size. Any element attributes are copied to the text attachment's elements.
 @param options An NSDictionary of options. Used to specify the max image size with the key DTMaxImageSize.
 */
- (id)initWithElement:(DTHTMLElement *)element options:(NSDictionary *)options;

/**
 @name Alternate Representations
 */

/**
 Retrieves a string which is in the format "data:image/png;base64,%@" with this DTTextAttachment's content's data representation encoded in Base64 string encoding. For image contents only.
 @returns A Base64 encoded string of the png data representation of this text attachment's image contents.
 */
- (NSString *)dataURLRepresentation;

/**
 The image represented by the receiver
 */
@property (nonatomic, strong) DTImage *image;

@end
