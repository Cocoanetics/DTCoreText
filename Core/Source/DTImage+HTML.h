//
//  DTImage+HTML.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#if TARGET_OS_IPHONE

/**
 Category used to have the same method available for unit testing on Mac on iOS.
 */
@interface UIImage (HTML)

/** 
 Retrieve the NSData representation of a UIImage. Used to encode UIImages in DTTextAttachments.
 
 @returns The NSData representation of the UIImage instance receiving this message. Convenience method for UIImagePNGRepresentation(). 
 */
- (NSData *)dataForPNGRepresentation;

@end

#else

/**
 Category used to have the same method available for unit testing on Mac on iOS.
 */
@interface NSImage (HTML)


/** 
 Retrieve the NSData representation of a NSImage.
 
 @returns The NSData representation of the NSImage instance receiving this message. 
 */
- (NSData *)dataForPNGRepresentation;

@end

#endif
