//
//  DTMacAttributedTextContentView.h
//  DTCoreText
//
//  Created by Michael Markowski on 11/27/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

// not yet ported iOS code
#define DT_MACPORT_FEATURE_ATTACHMENT_IMPLEMENTED 0
#define DT_MACPORT_FEATURE_TILEDLAYER_IMPLEMENTED 0
#define DT_MACPORT_FEATURE_LAYERCLASS_IMPLEMENTED 0
#define DT_MACPORT_FEATURE_SUPPORT_FOR_CUSTOM_LINKVIEWS_IMPLEMENTED 1
#define DT_MACPORT_FEATURE_SUPPORT_FOR_CUSTOM_SUBVIEWS_IMPLEMENTED 0
#define DT_MACPORT_FEATURE_SUPPORT_FOR_LAYOUT_SUBVIEWS_IMPLEMENTED 1 // maybe not needed at all -> todo: check if needed

#import <Cocoa/Cocoa.h>

#import "DTCoreTextLayoutFrame.h"
#import "DTWeakSupport.h"
#import "DTCompatibility.h"

@class DTMacAttributedTextContentView;
@class DTCoreTextLayoutFrame;
@class DTTextBlock;
@class DTCoreTextLayouter;
@class DTTextAttachment;

/**
 notification that gets sent as soon as the receiver has done a layout pass
 */
extern NSString * const DTMacAttributedTextContentViewDidFinishLayoutNotification;

/**
 Protocol to provide custom views for elements in an DTMacAttributedTextContentView. Also the delegate gets notified once the text view has been drawn.
 */
@protocol DTMacAttributedTextContentViewDelegate <NSObject>

@optional

/**
 @name Notifications
 */

/**
 Called before a layout frame or a part of it is drawn. The text delegate can draw contents that goes under the text in this method.
 
 @param attributedTextContentView The content view that will be drawing a layout frame
 @param layoutFrame The layout frame that will be drawn for
 @param context The graphics context that will drawn into
 */
- (void)attributedTextContentView:(DTMacAttributedTextContentView *)attributedTextContentView willDrawLayoutFrame:(DTCoreTextLayoutFrame *)layoutFrame inContext:(CGContextRef)context;


/**
 Called after a layout frame or a part of it is drawn. The text delegate can draw contents that goes over the text in this method.
 
 @param attributedTextContentView The content view that drew a layout frame
 @param layoutFrame The layout frame that was drawn for
 @param context The graphics context that was drawn into
 */
- (void)attributedTextContentView:(DTMacAttributedTextContentView *)attributedTextContentView didDrawLayoutFrame:(DTCoreTextLayoutFrame *)layoutFrame inContext:(CGContextRef)context;


/**
 Called before the text belonging to a text block is drawn.
 
 This gives the developer an opportunity to draw a custom background below a text block.
 
 @param attributedTextContentView The content view that drew a layout frame
 @param textBlock The text block
 @param frame The frame within the content view's coordinate system that will be drawn into
 @param context The graphics context that will be drawn into
 @param layoutFrame The layout frame that will be drawn for
 @returns `YES` is the standard fill of the text block should be drawn, `NO` if it should not
 */
- (BOOL)attributedTextContentView:(DTMacAttributedTextContentView *)attributedTextContentView shouldDrawBackgroundForTextBlock:(DTTextBlock *)textBlock frame:(CGRect)frame context:(CGContextRef)context forLayoutFrame:(DTCoreTextLayoutFrame *)layoutFrame;

/**
 @name Providing Custom Views for Content
 */


/**
 Provide custom view for an attachment, e.g. an imageView for images
 
 @param attributedTextContentView The content view asking for a custom view
 @param attachment The <DTTextAttachment> that this view should represent
 @param frame The frame that the view should use to fit on top of the space reserved for the attachment
 @returns The view that should represent the given attachment
 */
- (NSView *)attributedTextContentView:(DTMacAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame;


/**
 Provide button to be placed over links, the identifier is used to link multiple parts of the same A tag
 
 @param attributedTextContentView The content view asking for a custom view
 @param url The `NSURL` of the hyperlink
 @param identifier An identifier that uniquely identifies the hyperlink within the document
 @param frame The frame that the view should use to fit on top of the space reserved for the attachment
 @returns The view that should represent the given hyperlink
 */
- (NSView *)attributedTextContentView:(DTMacAttributedTextContentView *)attributedTextContentView viewForLink:(NSURL *)url identifier:(NSString *)identifier frame:(CGRect)frame;

/**
 @returns The view that should represent the given anchor
 */

- (NSView *)attributedTextContentView:(DTMacAttributedTextContentView *)attributedTextContentView viewForAnchor:(NSString *)anchor frame:(CGRect)frame;

/**
 Provide generic views for all attachments.
 
 This is only called if the more specific delegate methods are not implemented.
 
 @param attributedTextContentView The content view asking for a custom view
 @param string The attributed sub-string containing this element
 @param frame The frame that the view should use to fit on top of the space reserved for the attachment
 @returns The view that should represent the given hyperlink or text attachment
 @see attributedTextContentView:viewForAttachment:frame: and attributedTextContentView:viewForAttachment:frame:
 */
- (NSView *)attributedTextContentView:(DTMacAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame;

@end


enum {
	DTMacAttributedTextContentViewRelayoutNever            = 0,
	DTMacAttributedTextContentViewRelayoutOnWidthChanged   = 1 << 0,
	DTMacAttributedTextContentViewRelayoutOnHeightChanged  = 1 << 1,
};
typedef NSUInteger DTMacAttributedTextContentViewRelayoutMask;


/**
 Attributed Text Content Views display attributed strings generated by DTHTMLAttributedStringBuilder. They can display images and hyperlinks inline or optionally place custom subviews (which get provided via the <delegate> in the appropriate places. By itself content views do not scroll, for that there is the `UIScrollView` subclass <DTAttributedTextView>.
 
 Generally you have two options to providing content:
 
 - set the attributed string
 - set a layout frame
 
 The first you would normally use, the second you would use if you are layouting a larger text and then simply want to display individual parts (e.g. pages from an e-book) in a content view.
 
 DTMacAttributedTextContentView is designed to be used as the content view inside a DTAttributedTextView and thus sizes its intrinsicContentSize always to be the same as the width of the set frame. Use DTAttributedLabel if you don't require scrolling behavior.
 */


@interface DTMacAttributedTextContentView : NSView
{
	NSAttributedString *_attributedString;
	DTCoreTextLayoutFrame *_layoutFrame;
	
	DTEdgeInsets _edgeInsets;
	
	NSMutableDictionary *customViewsForAttachmentsIndex;
	
	BOOL _flexibleHeight;
	
	// for layoutFrame
	NSInteger _numberOfLines;
	NSLineBreakMode _lineBreakMode;
	NSAttributedString *_truncationString;
}


/**
 @name Sizing
 */

/**
 Calculates the suggested frame size that would fit the entire <attributedString> with a maximum width.
 
 This does a full layout pass that is cached in <DTCoreTextLayouter>. If you specify a frame that fits the result from this method then the resulting layoutFrame is reused.
 
 Since this obeys the <edgeInsets> you have to add these to the final frame size.
 
 @param width The maximum width to layout for
 @returns The suggested frame size
 */
- (CGSize)suggestedFrameSizeToFitEntireStringConstraintedToWidth:(CGFloat)width; // obeys the edge insets

/**
 The size of contents of the receiver. This is possibly used by auto-layout, but also for example if you want to get the size of the receiver necessary for a scroll view
 
 This method is defined as of iOS 6, but to support earlier OS versions
 */
- (CGSize)intrinsicContentSize;

/**
 Whether the receiver calculates layout limited to the view bounds.
 
 If set to `YES` then the layout process calculates the layoutFrame with open ended height. If set to ´NO` then the current bounds of the receiver determine the height.
 */
@property (nonatomic, assign) BOOL layoutFrameHeightIsConstrainedByBounds;


/**
 @name Layouting
 */

/**
 Discards the current <layoutFrame> and creates a new one based on the <attributedString>.
 */
- (void)relayoutText;

/**
 Discards the current <layoutFrame> and creates a new one based on the <attributedString>.
  @param force If set to `YES` relayouting will be done even if the view has no superview. This might be useful in situations where rendering is done off-screen or similar.
 */
- (void)relayoutTextForced:(BOOL)force;

/**
 The layouter to use for the receiver. Created by default.
 
 By default this is generated automatically for the current <attributedString>. You can also supply your own if you require special layouting behavior.
 */
@property (atomic, strong) DTCoreTextLayouter *layouter;


/**
 The layout frame to use for the receiver. Created by default.
 
 A layout frame is basically one rectangle, inset by the <edgeInsets>. By default this is automatically generated for the current <attributedString>. You can also create a <DTCoreTextLayoutFrame> seperately and set this property to display the layout frame. This is usedful for example if you layout entire e-book and then set the <layoutFrame> for displaying individual pages.
 */
@property (atomic, strong) DTCoreTextLayoutFrame *layoutFrame;


/**
 @name Working with Custom Subviews
 */

/**
 Removes all custom subviews (excluding views representing links) from the receiver.
 */
- (void)removeAllCustomViews;


/**
 Removes all custom subviews representing links from the receiver
 */
- (void)removeAllCustomViewsForLinks;


/**
 Removes invisible custom subviews and lays out subviews visible in the given rectangle
 @param rect The bounds of the visible area to layout custom subviews in.
 */
- (void)layoutSubviewsInRect:(CGRect)rect;


/**
 @name Providing Content
 */

/**
 The attributed string to display in the receiver
 */
@property (nonatomic, copy) NSAttributedString *attributedString;


/**
 The delegate that is in charge of supplying custom behavior for the receiver. It must conform to <DTMacAttributedTextContentViewDelegate> and provide custom subviews, link buttons, etc.
 */

@property (nonatomic, DT_WEAK_PROPERTY) IBOutlet id <DTMacAttributedTextContentViewDelegate> delegate;

/**
 @name Customizing Content Display
 */

/**
 The insets to apply around the text content
 */
@property (nonatomic) DTEdgeInsets edgeInsets;

/**
 Specifies if the receiver should draw image text attachments.
 
 Set to `NO` if you use the delegate methods to provide custom subviews to display images.
 */
@property (nonatomic) BOOL shouldDrawImages;


/**
 Specified if the receiver should draw hyperlinks.
 
 If set to `NO` then your custom subview/button for hyperlinks is responsible for displaying hyperlinks. You can use <DTLinkButton> to have links show a differently for normal and highlighted style
 */
@property (nonatomic) BOOL shouldDrawLinks;


/**
 Specifies if the receiver should layout custom subviews in layoutSubviews.
 
 If set to `YES` then all custom subviews will always be layouted. Set to `NO` to only layout visible subviews, e.g. in a scroll view. Defaults to `YES` if used stand-alone, `NO` inside a <DTAttributedTextView>.
 */
@property (nonatomic) BOOL shouldLayoutCustomSubviews;


/**
 The amount by which all contents of the receiver will offset of display and subview layouting
 */
@property (nonatomic) CGPoint layoutOffset;


/**
 The offset to apply for drawing the background.
 
 If you set a pattern color as background color you can have the pattern phase be offset by this value.
 */
@property (nonatomic) CGSize backgroundOffset;


/**
 An integer bit mask that determines how the receiver relayouts its contents when its bounds change.
 
 When the view’s bounds change, that view automatically re-layouts its text according to the relayout mask. You specify the value of this mask by combining the constants described in DTMacAttributedTextContentViewRelayoutMask using the C bitwise OR operator. Combining these constants lets you specify which dimensions will cause a re-layout if modified. The default value of this property is DTMacAttributedTextContentViewRelayoutOnWidthChanged, which indicates that the text will be re-layouted if the width changes, but not if the height changes.
 */
@property (nonatomic) DTMacAttributedTextContentViewRelayoutMask relayoutMask;


/**
 Mimicking UIView's backgroundColor property
 */
@property (nonatomic, strong) DTColor *backgroundColor;

/**
 Yosemite defines opaque as readOnly property in NSView (opaque since 10.10). So we have to use opaqueValue as property.
 
 Mimicking UIView's opaque property
 */
@property (nonatomic, assign) BOOL opaqueValue;

@end


/**
 Methods for drawing the content view
 */
@interface DTMacAttributedTextContentView (Drawing)

/**
 Creates an image from a part of the receiver's content view
 @param bounds The bounds of the content to draw
 @param options The drawing options to apply when drawing
 @see [DTCoreTextLayoutFrame drawInContext:options:] for a list of available drawing options
 @returns A `UIImage` with the specified content
 */
- (NSImage *)contentImageWithBounds:(CGRect)bounds options:(DTCoreTextLayoutFrameDrawingOptions)options;

@end


/**
 Methods for getting cursor position and frame. Those are convenience methods that call through to the layoutFrame property which has the same coordinate system as the receiver.
 */
@interface DTMacAttributedTextContentView (Cursor)

/**
 Determines the closest string index to a point in the receiver's frame.
 
 This can be used to find the cursor position to position an input caret at.
 @param point The point
 @returns The resulting string index
 */
- (NSInteger)closestCursorIndexToPoint:(CGPoint)point;

/**
 The rectangle to draw a caret for a given index
 @param index The string index for which to determine a cursor frame
 @returns The cursor rectangle
 */
- (CGRect)cursorRectAtIndex:(NSInteger)index;

@end
