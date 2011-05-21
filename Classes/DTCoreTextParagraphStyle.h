//
//  DTCoreTextParagraphStyle.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreText/CoreText.h>

@interface DTCoreTextParagraphStyle : NSObject <NSCopying>
{
    CGFloat firstLineIndent;
	CGFloat defaultTabInterval;
    CGFloat paragraphSpacingBefore;
    CGFloat paragraphSpacing;
    CGFloat headIndent;
    CGFloat lineHeightMultiple;
    CGFloat minimumLineHeight;
    CGFloat maximumLineHeight;
    
    CTTextAlignment textAlignment;
    CTWritingDirection writingDirection;
    
    NSMutableArray *_tabStops;
}

@property (nonatomic, assign) CGFloat firstLineIndent;
@property (nonatomic, assign) CGFloat defaultTabInterval;
@property (nonatomic, assign) CGFloat paragraphSpacingBefore;
@property (nonatomic, assign) CGFloat paragraphSpacing;
@property (nonatomic, assign) CGFloat lineHeightMultiple;
@property (nonatomic, assign) CGFloat minimumLineHeight;
@property (nonatomic, assign) CGFloat maximumLineHeight;
@property (nonatomic, assign) CGFloat headIndent;
@property (nonatomic, copy) NSArray *tabStops;

@property (nonatomic, assign) CTTextAlignment textAlignment;
@property (nonatomic, assign) CTWritingDirection writingDirection;


+ (DTCoreTextParagraphStyle *)defaultParagraphStyle;
+ (DTCoreTextParagraphStyle *)paragraphStyleWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle;

- (id)initWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle;
- (CTParagraphStyleRef)createCTParagraphStyle;

- (void)addTabStopAtPosition:(CGFloat)position alignment:(CTTextAlignment)alignment;

@end
