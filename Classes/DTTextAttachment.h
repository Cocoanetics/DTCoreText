//
//  DTTextAttachment.h
//  CoreTextExtensions
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum
{
    DTTextAttachmentTypeImage,
    DTTextAttachmentTypeVideoURL
}  DTTextAttachmentType;


@interface DTTextAttachment : NSObject {
	CGSize size;
	id contents;
    
    DTTextAttachmentType contentType;
}

@property (nonatomic, assign) CGSize size;
@property (nonatomic, retain) id contents;
@property (nonatomic, assign) DTTextAttachmentType contentType;

@end
