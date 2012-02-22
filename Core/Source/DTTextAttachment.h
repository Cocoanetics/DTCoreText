//
//  DTTextAttachment.h
//  CoreTextExtensions
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#endif

@class DTHTMLElement;

typedef enum
{
    DTTextAttachmentTypeImage,
    DTTextAttachmentTypeVideoURL,
	DTTextAttachmentTypeIframe,
	DTTextAttachmentTypeObject,
	DTTextAttachmentTypeGeneric
}  DTTextAttachmentType;

typedef enum
{
	DTTextAttachmentVerticalAlignmentBaseline = 0,
	DTTextAttachmentVerticalAlignmentTop,
	DTTextAttachmentVerticalAlignmentCenter,
	DTTextAttachmentVerticalAlignmentBottom
} DTTextAttachmentVerticalAlignment;


@interface DTTextAttachment : NSObject 

@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, assign) CGSize displaySize;
@property (nonatomic, strong) id contents;
@property (nonatomic, assign) DTTextAttachmentType contentType;
@property (nonatomic, strong) NSURL *contentURL;
@property (nonatomic, strong) NSURL *hyperLinkURL;
@property (nonatomic, strong) NSDictionary *attributes;
@property (nonatomic, assign) DTTextAttachmentVerticalAlignment verticalAlignment;


+ (DTTextAttachment *)textAttachmentWithElement:(DTHTMLElement *)element options:(NSDictionary *)options;

- (NSString *)dataURLRepresentation;

- (void)adjustVerticalAlignmentForFont:(CTFontRef)font;

// customized ascend and descent for the run delegates
- (CGFloat)ascentForLayout;
- (CGFloat)descentForLayout;

@end
