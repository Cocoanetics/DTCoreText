//
//  DTHTMLElement.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTCoreTextParagraphStyle;
@class DTCoreTextFontDescriptor;
@class DTTextAttachment;

#import <CoreText/CoreText.h>


@interface DTHTMLElement : NSObject <NSCopying>
{
    DTCoreTextFontDescriptor *fontDescriptor;
    DTCoreTextParagraphStyle *paragraphStyle;
    DTTextAttachment *textAttachment;
    NSURL *link;
    
    UIColor *textColor;
    
    CTUnderlineStyle underlineStyle;
    
    NSString *tagName;
    NSString *text;
    
    BOOL tagContentInvisible;
    BOOL strikeOut;
    NSInteger superscriptStyle;
    
    NSInteger headerLevel;
    
    NSArray *shadows;
    
    NSMutableDictionary *_fontCache;
    
    NSInteger _isInline;
}

@property (nonatomic, copy) DTCoreTextFontDescriptor *fontDescriptor;
@property (nonatomic, copy) DTCoreTextParagraphStyle *paragraphStyle;
@property (nonatomic, retain) DTTextAttachment *textAttachment;
@property (nonatomic, copy) NSURL *link;

@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, copy) NSString *tagName;
@property (nonatomic, copy) NSString *text;

@property (nonatomic, retain) NSArray *shadows;

@property (nonatomic, assign) CTUnderlineStyle underlineStyle;

@property (nonatomic, assign) BOOL tagContentInvisible;
@property (nonatomic, assign) BOOL strikeOut;
@property (nonatomic, assign) NSInteger superscriptStyle;

@property (nonatomic, assign) NSInteger headerLevel;
@property (nonatomic, readonly) BOOL isInline;



- (NSAttributedString *)attributedString;
- (NSDictionary *)attributesDictionary;

- (void)parseStyleString:(NSString *)styleString;


@end
