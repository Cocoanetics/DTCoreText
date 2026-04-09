@import Foundation;

/// Swift-callable wrappers for private DTCSSStylesheet methods used in testing.
@interface DTCSSStylesheetTestHelper : NSObject

+ (NSInteger)weightForSelector:(NSString * _Nullable)selector inStylesheet:(id _Nonnull)stylesheet;
+ (NSDictionary * _Nonnull)uncompressShorthands:(NSDictionary * _Nonnull)styles usingStylesheet:(id _Nonnull)stylesheet;

@end
