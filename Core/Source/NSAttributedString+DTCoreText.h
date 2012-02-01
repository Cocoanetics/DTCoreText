//
//  NSAttributedString+DTCoreText.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 2/1/12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

@interface NSAttributedString (DTCoreText)

// convenience methods
+ (NSAttributedString *)attributedStringWithHTML:(NSData *)data options:(NSDictionary *)options;

// attachment handling
- (NSArray *)textAttachmentsWithPredicate:(NSPredicate *)predicate;

// encoding back to HTML
- (NSString *)htmlString;
- (NSString *)plainTextString;

@end
