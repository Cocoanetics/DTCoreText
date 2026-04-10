//
//  DTCoreTextConstants.h
//  DTCoreText DemoApp
//
//  Re-declares string constants from the Swift DTCoreTextSwift module so that
//  Objective-C code in the Demo can use the bare identifiers (the Swift
//  package exposes them as top-level `public let`s, which Clang's @import
//  cannot see).
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString * const DTDefaultTextColor;
extern NSString * const DTDefaultLinkColor;
extern NSString * const DTDefaultLinkHighlightColor;
extern NSString * const DTDefaultFontFamily;
extern NSString * const DTMaxImageSize;
extern NSString * const DTWillFlushBlockCallBack;
extern NSString * const DTLinkAttribute;
extern NSString * const DTGUIDAttribute;
extern NSString * const NSBaseURLDocumentOption;
extern NSString * const NSTextSizeMultiplierDocumentOption;

// CSS-style color name → UIColor
UIColor * _Nullable DTColorCreateWithHTMLName(NSString * _Nonnull name);
