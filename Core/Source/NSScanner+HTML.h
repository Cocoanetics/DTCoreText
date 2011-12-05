//
//  NSScanner+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



@interface NSScanner (HTML)

- (NSString *)peekNextTagSkippingClosingTags:(BOOL)skipClosingTags;
- (BOOL)scanHTMLTag:(NSString **)tagName attributes:(NSDictionary **)attributes isOpen:(BOOL *)isOpen isClosed:(BOOL *)isClosed;
- (BOOL)scanDOCTYPE:(NSString **)contents;
- (BOOL)scanCSSAttribute:(NSString **)name value:(NSString **)value;
- (BOOL)scanCSSURL:(NSString **)urlString;

- (void)logPosition;
@end
