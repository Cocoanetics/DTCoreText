//
//  DTTextAttachment.h
//  CoreTextExtensions
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

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
{
	CGSize _originalSize;
	CGSize _displaySize;
	id contents;
    NSDictionary *_attributes;
    
    DTTextAttachmentType contentType;
	
	NSURL *_contentURL;
	NSURL *_hyperLinkURL;
}

@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, assign) CGSize displaySize;
@property (nonatomic, retain) id contents;
@property (nonatomic, assign) DTTextAttachmentType contentType;
@property (nonatomic, retain) NSURL *contentURL;
@property (nonatomic, retain) NSURL *hyperLinkURL;
@property (nonatomic, retain) NSDictionary *attributes;


+ (DTTextAttachment *)textAttachmentWithElement:(DTHTMLElement *)element options:(NSDictionary *)options;

- (NSString *)dataURLRepresentation;

@end
