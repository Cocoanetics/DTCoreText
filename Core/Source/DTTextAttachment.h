//
//  DTTextAttachment.h
//  DTCoreText
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCompatibility.h"

#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

#import <CoreText/CoreText.h>

@class DTHTMLElement;

/**
 Text Attachment vertical alignment
 */
typedef NS_ENUM(NSUInteger, DTTextAttachmentVerticalAlignment)
{
	/**
	 Baseline alignment (default)
	 */
	DTTextAttachmentVerticalAlignmentBaseline = 0,
	
	/**
	 Align with top edge
	 */
	DTTextAttachmentVerticalAlignmentTop,
	
	/**
	 Align with center
	 */
	DTTextAttachmentVerticalAlignmentCenter,
	
	/**
	 Align with bottom edge
	 */
	DTTextAttachmentVerticalAlignmentBottom
};

/**
 Methods to implement for attachments to support inline drawing.
 */
@protocol DTTextAttachmentDrawing <NSObject>

/**
 Draws the contents of the receiver into a graphics context
 @param rect The rectangle to draw the receiver into
 @param context The graphics context
 */
- (void)drawInRect:(CGRect)rect context:(CGContextRef)context;

@end


/**
 Methods to implement for attachments to support output to HTML.
 */
@protocol DTTextAttachmentHTMLPersistence <NSObject>

/**
 Creates a HTML representation of the receiver
 @returns A HTML string with the receiver encoded as HTML
 */
- (NSString *)stringByEncodingAsHTML;

@end


/**
 An object to represent an attachment in an HTML/rich text view.  
 */
@interface DTTextAttachment : NSObject <NSCoding>
{
	CGSize _displaySize;  // the display dimensions of the attachment
	CGSize _originalSize; // the original dimensions of the attachment
	CGSize _maxImageSize; // the maximum dimensions to size to
	NSURL *_contentURL;
	NSDictionary *_attributes; // attributes transferred from HTML element
	DTTextAttachmentVerticalAlignment _verticalAlignment; // alignment in relation to the baseline
}

/**
 @name Creating Text Attachments
 */

/**
 Initialize and return a DTTextAttachment with the specified DTHTMLElement and options. Convenience initializer. 
	The element must have a valid tagName. The size of the returned text attachment is determined by the element, constrained by the option's key for DTMaxImageSize. Any valid image resource included in the element (denoted by the method attributeForKey: "src") is loaded and determines the text attachment size if it was not known before. If a size is too large the image is downsampled with sizeThatFitsKeepingAspectRatio() which preserves the aspect ratio. 
 @param element A DTHTMLElement that must have a valid tag name and should have a size. Any element attributes are copied to the text attachment's elements. 
 @param options An NSDictionary of options. Used to specify the max image size with the key DTMaxImageSize. 
 @returns Returns the appropriate subclass of the class cluster
 */
+ (DTTextAttachment *)textAttachmentWithElement:(DTHTMLElement *)element options:(NSDictionary *)options;

/**
 The designated initializer for members of the DTTextAttachment class cluster. If you need additional setup for custom subclasses then you should override this initializer.
 @param element A DTHTMLElement that must have a valid tag name and should have a size. Any element attributes are copied to the text attachment's elements.
 @param options An NSDictionary of options. Used to specify the max image size with the key DTMaxImageSize.
 @returns Returns an initialized DTTextAttachment built using the element and options parameters.  */
- (id)initWithElement:(DTHTMLElement *)element options:(NSDictionary *)options;

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
 The size of the receiver according to width/height HTML attribute or CSS style attribute
 */
@property (nonatomic, assign) CGSize originalSize;

/**
 The size to use for displaying/laying out the receiver
 */
@property (nonatomic, assign) CGSize displaySize;

/**
 Updates the display size optionally passing a maximum size that it should not exceed.
 
 This method in contrast to using the displaySize property will use the originalSize and max display size to calculate missing dimensions.
 @param displaySize The new size to display the content with
 @param maxDisplaySize the maximum size that the content should be scaled to fit
 */
- (void)setDisplaySize:(CGSize)displaySize withMaxDisplaySize:(CGSize)maxDisplaySize;

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
 The attributes dictionary of the attachment.
 
 If initialized from HTML, the values of this dictionary are transferred from the give HTML element.  If you wish to add custom attribute values to be written to and read from HTML, be aware that the attribute name will be lowercased in compliance with W3C recommendations.  Therefore, you may set a camel-case name and persist to HTML, but you will receive a lowercase name when the HTML is transformed into an attributed string.
 */
@property (nonatomic, strong) NSDictionary *attributes;

/**
 @name Customizing Attachments
 */

/**
 Registers your own class for use when encountering a specific tag Name. If you register a class for a previously registered class (or one of the predefined ones (img, iframe, object, video) then this replaces this with the newer registration.
 
 These registrations are permanent during the run time of your app. Custom attachment classes must implement the initWithElement:options: initializer and can implement the DTTextAttachmentDrawing and/or DTTextAttachmentHTMLPersistence protocols.
 @param theClass The class to instantiate in textAttachmentWithElement:options: when encountering a tag with this name
 @param tagName The tag name to use this class for
 */
+ (void)registerClass:(Class)theClass forTagName:(NSString *)tagName;

/**
 The class to use for a tag name
 @param tagName The tag name
 @returns The class to use for attachments with with tag name, or `nil` if this should not be an attachment
 */
+ (Class)registeredClassForTagName:(NSString *)tagName;

@end
