//
//  DTColor+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#if TARGET_OS_IPHONE

@interface UIColor (HTML)

typedef UIColor DTColor;

+ (UIColor *)colorWithHexString:(NSString *)hex;
+ (UIColor *)colorWithHTMLName:(NSString *)name;
- (NSString *)htmlHexString;

- (CGFloat)alphaComponent;

@end

#else

typedef NSColor DTColor;

@interface NSColor (HTML)

+ (NSColor *)colorWithHexString:(NSString *)hex;
+ (NSColor *)colorWithHTMLName:(NSString *)name;
- (NSString *)htmlHexString;

+ (NSColor *)colorWithCGColor:(CGColorRef)cgColor;

// pass through
- (NSColor *)CGColor;

@end

#endif