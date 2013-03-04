//
//  DTTextAttachment.h
//  DTCoreText
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

/**
 @name Creating Text Attachments
 */

/**
 Initialize and return a DTTextAttachment with the specified DTHTMLElement and options. Convenience initializer. 
	The element must have a valid tagName. The size of the returned text attachment is determined by the element, constrained by the option's key for DTMaxImageSize. Any valid image resource included in the element (denoted by the method attributeForKey: "src") is loaded and determines the text attachment size if it was not known before. If a size is too large the image is downsampled with sizeThatFitsKeepingAspectRatio() which preserves the aspect ratio. 
 @param element A DTHTMLElement that must have a valid tag name and should have a size. Any element attributes are copied to the text attachment's elements. 
 @param options An NSDictionary of options. Used to specify the max image size with the key DTMaxImageSize. 
 @returns Returns an initialized DTTextAttachment built using the element and options parameters. 
 */
+ (DTTextAttachment *)textAttachmentWithElement:(DTHTMLElement *)element options:(NSDictionary *)options;


/**
 @name Alternate Representations
 */

/** 
 Retrieves a string which is in the format "data:image/png;base64,%@" with this DTTextAttachment's content's data representation encoded in Base64 string encoding. For image contents only.  
 @returns A Base64 encoded string of the png data representation of this text attachment's image contents. 
 */
- (NSString *)dataURLRepresentation;


/**
 @name Vertical Alignment
 */

/**
 Inspects the given font and records the font's ascent, descent and leading. These values are then used during layout to properly respond with ascentForLayout, descentForLayout for the receiver's verticalAlignment.
 @param font The font to inspect
 */
- (void)adjustVerticalAlignmentForFont:(CTFontRef)font;

/**
 The ascent to use during layout so that the receiver can be display at its verticalAlignment.
 */
- (CGFloat)ascentForLayout;

/**
 The descent to use during layout so that the receiver can be display at its verticalAlignment.
 */
- (CGFloat)descentForLayout;

/**
 The vertical alignment of the receiver
 */
@property (nonatomic, assign) DTTextAttachmentVerticalAlignment verticalAlignment;


/**
 @name Retrieving Information about Attachments
 */

/**
 The original size of the attachment
 */
@property (nonatomic, assign) CGSize originalSize;

/**
 The size to use for displaying/layouting the receiver
 */
@property (nonatomic, assign) CGSize displaySize;

/**
 The contents of the receiver
 */
@property (nonatomic, strong) id contents;

/**
 The content type of the attachment
 */
@property (nonatomic, assign) DTTextAttachmentType contentType;

/**
 The URL representing the content
 */
@property (nonatomic, strong) NSURL *contentURL;

/**
 The hyperlink URL of the receiver.
 */
@property (nonatomic, strong) NSURL *hyperLinkURL;

/**
 The GUID of the hyperlink that this is a part of. All parts of a hyperlink have the same GUID so that they can highlight together.
 */
@property (nonatomic, strong) NSString *hyperLinkGUID;

/**
 The attributes dictionary of the attachment
 */
@property (nonatomic, strong) NSDictionary *attributes;

/**
 The DTHTMLElement child nodes of the receiver. This array is only used for object tags at the moment.
 */
@property (nonatomic, strong) NSArray *childNodes;

@end
