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
    CGFloat lineHeight;
    
    CTTextAlignment textAlignment;
    CTWritingDirection writingDirection;
    
    NSMutableArray *tabStops;
}

@property (nonatomic, assign) CGFloat firstLineIndent;
@property (nonatomic, assign) CGFloat defaultTabInterval;
@property (nonatomic, assign) CGFloat paragraphSpacingBefore;
@property (nonatomic, assign) CGFloat paragraphSpacing;
@property (nonatomic, assign) CGFloat lineHeightMultiple;
@property (nonatomic, assign) CGFloat lineHeight;
@property (nonatomic, assign) CGFloat headIndent;
@property (nonatomic, copy) NSMutableArray *tabStops;

@property (nonatomic, assign) CTTextAlignment textAlignment;
@property (nonatomic, assign) CTWritingDirection writingDirection;


+ (DTCoreTextParagraphStyle *)defaultParagraphStyle;

- (CTParagraphStyleRef)createCTParagraphStyle;

- (void)addTabStopAtPosition:(CGFloat)position alignment:(CTTextAlignment)alignment;

@end
