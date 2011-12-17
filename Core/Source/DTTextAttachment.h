//
//  DTTextAttachment.h
//  CoreTextExtensions
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



@class DTHTMLElement;

typedef enum
{
    DTTextAttachmentTypeImage,
    DTTextAttachmentTypeVideoURL,
	DTTextAttachmentTypeIframe,
	DTTextAttachmentTypeObject,
	DTTextAttachmentTypeGeneric
}  DTTextAttachmentType;


@interface DTTextAttachment : NSObject 

@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, assign) CGSize displaySize;
@property (nonatomic, strong) id contents;
@property (nonatomic, assign) DTTextAttachmentType contentType;
@property (nonatomic, strong) NSURL *contentURL;
@property (nonatomic, strong) NSURL *hyperLinkURL;
@property (nonatomic, strong) NSDictionary *attributes;


+ (DTTextAttachment *)textAttachmentWithElement:(DTHTMLElement *)element options:(NSDictionary *)options;

- (NSString *)dataURLRepresentation;

@end
