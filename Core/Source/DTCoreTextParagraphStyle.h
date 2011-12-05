//
//  DTCoreTextParagraphStyle.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreText/CoreText.h>

@interface DTCoreTextParagraphStyle : NSObject <NSCopying>

@property (nonatomic, assign) CGFloat firstLineIndent;
@property (nonatomic, assign) CGFloat defaultTabInterval;
@property (nonatomic, assign) CGFloat paragraphSpacingBefore;
@property (nonatomic, assign) CGFloat paragraphSpacing;
@property (nonatomic, assign) CGFloat lineHeightMultiple;
@property (nonatomic, assign) CGFloat minimumLineHeight;
@property (nonatomic, assign) CGFloat maximumLineHeight;
@property (nonatomic, assign) CGFloat headIndent;
@property (nonatomic, assign) CGFloat listIndent;
@property (nonatomic, copy) NSArray *tabStops;

@property (nonatomic, assign) CTTextAlignment textAlignment;
@property (nonatomic, assign) CTWritingDirection writingDirection;


+ (DTCoreTextParagraphStyle *)defaultParagraphStyle;
+ (DTCoreTextParagraphStyle *)paragraphStyleWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle;

- (id)initWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle;
- (CTParagraphStyleRef)createCTParagraphStyle;

- (BOOL)addTabStopAtPosition:(CGFloat)position alignment:(CTTextAlignment)alignment;

- (NSString *)cssStyleRepresentation;

@end
