#import "DTCoreTextTestHelpers.h"
@import DTCoreText;

@interface DTCSSStylesheet ()
- (NSInteger)_weightForSelector:(NSString *)selector;
- (void)_uncompressShorthands:(NSMutableDictionary *)styles;
@end

@implementation DTCSSStylesheetTestHelper

+ (NSInteger)weightForSelector:(NSString *)selector inStylesheet:(DTCSSStylesheet *)stylesheet
{
    return [stylesheet _weightForSelector:selector];
}

+ (NSDictionary *)uncompressShorthands:(NSDictionary *)styles usingStylesheet:(DTCSSStylesheet *)stylesheet
{
    NSMutableDictionary *mutable = [styles mutableCopy];
    [stylesheet _uncompressShorthands:mutable];
    return [mutable copy];
}

@end
