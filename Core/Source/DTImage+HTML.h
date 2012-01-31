

#if TARGET_OS_IPHONE

typedef UIImage DTImage;

@interface UIImage (HTML)

- (NSData *)dataForPNGRepresentation;

@end

#else

typedef NSImage DTImage;

@interface NSImage (HTML)

- (NSData *)dataForPNGRepresentation;

@end

#endif
