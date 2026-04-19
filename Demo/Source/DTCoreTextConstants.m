//
//  DTCoreTextConstants.m
//  DTCoreText DemoApp
//

#import "DTCoreTextConstants.h"

NSString * const DTDefaultTextColor = @"DTDefaultTextColor";
NSString * const DTDefaultLinkColor = @"DTDefaultLinkColor";
NSString * const DTDefaultLinkHighlightColor = @"DTDefaultLinkHighlightColor";
NSString * const DTDefaultFontFamily = @"DTDefaultFontFamily";
NSString * const DTMaxImageSize = @"DTMaxImageSize";
NSString * const DTLinkAttribute = @"NSLink";
NSString * const DTGUIDAttribute = @"DTGUID";
NSString * const NSBaseURLDocumentOption = @"NSBaseURLDocumentOption";
NSString * const NSTextSizeMultiplierDocumentOption = @"NSTextSizeMultiplierDocumentOption";

UIColor * DTColorCreateWithHTMLName(NSString *name) {
    if (!name.length) return nil;
    NSString *lower = name.lowercaseString;

    // Hex form: #rgb / #rrggbb
    if ([lower hasPrefix:@"#"]) {
        NSScanner *scanner = [NSScanner scannerWithString:[lower substringFromIndex:1]];
        unsigned long long value = 0;
        if (![scanner scanHexLongLong:&value]) return nil;
        CGFloat r, g, b;
        if (lower.length == 4) {
            r = ((value >> 8) & 0xF) / 15.0;
            g = ((value >> 4) & 0xF) / 15.0;
            b = (value & 0xF) / 15.0;
        } else {
            r = ((value >> 16) & 0xFF) / 255.0;
            g = ((value >> 8) & 0xFF) / 255.0;
            b = (value & 0xFF) / 255.0;
        }
        return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
    }

    // Named CSS colors used by the demo
    static NSDictionary<NSString *, UIColor *> *named;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        named = @{
            @"black":   [UIColor blackColor],
            @"white":   [UIColor whiteColor],
            @"red":     [UIColor redColor],
            @"green":   [UIColor greenColor],
            @"blue":    [UIColor blueColor],
            @"yellow":  [UIColor yellowColor],
            @"orange":  [UIColor orangeColor],
            @"purple":  [UIColor purpleColor],
            @"brown":   [UIColor brownColor],
            @"gray":    [UIColor grayColor],
            @"grey":    [UIColor grayColor],
            @"cyan":    [UIColor cyanColor],
            @"magenta": [UIColor magentaColor],
            @"pink":    [UIColor systemPinkColor],
        };
    });
    return named[lower];
}
