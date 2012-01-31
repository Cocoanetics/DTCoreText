//
//  DTImage+HTML.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 31.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTImage+HTML.h"

#if TARGET_OS_IPHONE

@implementation UIImage (HTML)

- (NSData *)dataForPNGRepresentation
{
	return UIImagePNGRepresentation(self);
}

@end

#else

@implementation NSImage (HTML)

- (NSData *)dataForPNGRepresentation
{
	[self lockFocus];
	NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, self.size.width, self.size.height)];
	[self unlockFocus];
	
	return [bitmapRep representationUsingType:NSPNGFileType properties:Nil];
}

@end

#endif