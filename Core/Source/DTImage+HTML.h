

#if TARGET_OS_IPHONE

typedef UIImage DTImage;

@interface UIImage (HTML)

/** Retrieve the NSData representation of a UIImage. Used to encode UIImages in DTTextAttachments. 
 @return The NSData repreentation of the UIImage instance receiving this message. Convenience method for UIImagePNGRepresentation(). */
- (NSData *)dataForPNGRepresentation;

@end

#else

typedef NSImage DTImage;

@interface NSImage (HTML)

/** Retrieve the NSData representation of a NSImage.  
 @return The NSData repreentation of the NSImage instance receiving this message. */
- (NSData *)dataForPNGRepresentation;

@end

#endif
