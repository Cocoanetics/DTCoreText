//
//  NSString+CSS.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 31.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"
#import "DTColor+HTML.h"

@interface NSString (CSS)

- (NSDictionary *)dictionaryOfCSSStyles;
- (CGFloat)pixelSizeOfCSSMeasureRelativeToCurrentTextSize:(CGFloat)textSize;
- (NSArray *)arrayOfCSSShadowsWithCurrentTextSize:(CGFloat)textSize currentColor:(DTColor *)color;
- (CGFloat)CSSpixelSize;

@end
