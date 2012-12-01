//
//  DTTextAttachment.h
//  CoreTextExtensions
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
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

/** 
 An object to represent an attachment in an HTML/rich text view.  
 */
@interface DTTextAttachment : NSObject 

@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, assign) CGSize displaySize;
@property (nonatomic, strong) id contents;
@property (nonatomic, assign) DTTextAttachmentType contentType;
@property (nonatomic, strong) NSURL *contentURL;
@property (nonatomic, strong) NSURL *hyperLinkURL;
@property (nonatomic, strong) NSString *hyperLinkGUID; // identifies the hyperlink this is part of
@property (nonatomic, strong) NSDictionary *attributes;
@property (nonatomic, assign) DTTextAttachmentVerticalAlignment verticalAlignment;

/** 
 Initialize and return a DTTextAttachment with the specified DTHTMLElement and options. Convenience initializer. 
	The element must have a valid tagName. The size of the returned text attachment is determined by the element, constrained by the option's key for DTMaxImageSize. Any valid image resource included in the element (denoted by the method attributeForKey: "src") is loaded and determines the text attachment size if it was not known before. If a size is too large the image is downsampled with sizeThatFitsKeepingAspectRatio() which preserves the aspect ratio. 
 @param element A DTHTMLElement that must have a valid tag name and should have a size. Any element attributes are copied to the text attachment's elements. 
 @param options An NSDictionary of options. Used to specify the max image size with the key DTMaxImageSize. 
 @returns Returns an initialized DTTextAttachment built using the element and options parameters. 
 */
+ (DTTextAttachment *)textAttachmentWithElement:(DTHTMLElement *)element options:(NSDictionary *)options;


/** 
 Retrieves a string which is in the format "data:image/png;base64,%@" with this DTTextAttachment's content's data representation encoded in Base64 string encoding. For image contents only.  
 @returns A Base64 encoded string of the png data representation of this text attachment's image contents. 
 */
- (NSString *)dataURLRepresentation;


- (void)adjustVerticalAlignmentForFont:(CTFontRef)font;


// Customized ascend and descent for the run delegates
- (CGFloat)ascentForLayout;
- (CGFloat)descentForLayout;

@end
