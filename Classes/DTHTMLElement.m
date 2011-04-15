//
//  DTHTMLElement.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTHTMLElement.h"
#import "DTCoreTextParagraphStyle.h"
#import "DTCoreTextFontDescriptor.h"
#import "NSAttributedStringRunDelegates.h"
#import "NSString+HTML.h"
#import "UIColor+HTML.h"
#import "NSCharacterSet+HTML.h"


@interface DTHTMLElement ()

@property (nonatomic, retain) NSMutableDictionary *fontCache;

@end


@implementation DTHTMLElement

- (id)init
{
    self = [super init];
    if (self)
    {
        _isInline = -1;
    }
    
    return self;
    
}



- (void)dealloc
{
    [fontDescriptor release];
    [paragraphStyle release];
    [textAttachment release];
    
    [textColor release];
    [tagName release];
    [text release];
    [link release];
    
    [shadows release];
    
    [_fontCache release];
    
    [super dealloc];
}


- (NSDictionary *)attributesDictionary
{
    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
    
    // add text attachment
    if (textAttachment)
    {
        // need run delegate for sizing
        CTRunDelegateRef embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(textAttachment);
        [tmpDict setObject:(id)embeddedObjectRunDelegate forKey:(id)kCTRunDelegateAttributeName];
        
        // add attachment
        [tmpDict setObject:textAttachment forKey:@"DTTextAttachment"];
    }
    else
    {
        // otherwise we have a font
        
        // try font cache first
        NSNumber *key = [NSNumber numberWithInt:[fontDescriptor hash]];
        CTFontRef font = (CTFontRef)[self.fontCache objectForKey:key];
        
        if (!font)
        {
            font = [fontDescriptor newMatchingFont];
            [self.fontCache setObject:(id)font forKey:key];
            CFRelease(font);
        }
        [tmpDict setObject:(id)font forKey:(id)kCTFontAttributeName];
        [tmpDict setObject:(id)paragraphStyle forKey:(id)kCTParagraphStyleAttributeName];
    }
    
    // add hyperlink
    if (link)
    {
        [tmpDict setObject:link forKey:@"DTLink"];
        
        // add a GUID to group multiple glyph runs belonging to same link
        [tmpDict setObject:[NSString guid] forKey:@"DTGUID"];
    }
    
    // add strikout if applicable
    if (strikeOut)
    {
        [tmpDict setObject:[NSNumber numberWithBool:YES] forKey:@"_StrikeOut"];
    }
    
    // set underline style
    if (underlineStyle)
    {
        [tmpDict setObject:[NSNumber numberWithInteger:underlineStyle] forKey:(id)kCTUnderlineStyleAttributeName];
        
        // we could set an underline color as well if we wanted, but not supported by HTML
        //      [attributes setObject:(id)[UIColor redColor].CGColor forKey:(id)kCTUnderlineColorAttributeName];
    }
    
    if (textColor)
    {
        [tmpDict setObject:(id)[textColor CGColor] forKey:(id)kCTForegroundColorAttributeName];
    }
    
    // add paragraph style
    [tmpDict setObject:(id)[self.paragraphStyle createCTParagraphStyle] forKey:(id)kCTParagraphStyleAttributeName];
    
    // add shadow array if applicable
    if (shadows)
    {
        [tmpDict setObject:shadows forKey:@"_Shadows"];
    }
    
    return tmpDict;
}


- (NSAttributedString *)attributedString
{
    NSDictionary *attributes = [self attributesDictionary];
    
    if (textAttachment)
    {
        // ignore text, use unicode object placeholder
        return [[[NSAttributedString alloc] initWithString:UNICODE_OBJECT_PLACEHOLDER attributes:attributes] autorelease];
    }
    else
    {
        return [[[NSAttributedString alloc] initWithString:text attributes:attributes] autorelease];
    }
}

- (void)parseStyleString:(NSString *)styleString
{
    NSDictionary *styles = [styleString dictionaryOfCSSStyles];
    
    NSString *fontSize = [styles objectForKey:@"font-size"];
    if (fontSize)
    {
        fontDescriptor.pointSize = [fontSize CSSpixelSize];
    }
    
    NSString *color = [styles objectForKey:@"color"];
    if (color)
    {
        self.textColor = [UIColor colorWithHTMLName:color];       
    }
    
    // TODO: better mapping from font families to available families
    NSString *fontFamily = [[styles objectForKey:@"font-family"] stringByTrimmingCharactersInSet:[NSCharacterSet quoteCharacterSet]];
    
    if (fontFamily)
    {
        NSString *lowercaseFontFamily = [fontFamily lowercaseString];
        
        if ([lowercaseFontFamily rangeOfString:@"helvetica"].length || [lowercaseFontFamily rangeOfString:@"arial"].length || [lowercaseFontFamily rangeOfString:@"geneva"].length)
        {
            fontDescriptor.fontFamily = @"Helvetica";
        }
        else if ([lowercaseFontFamily rangeOfString:@"courier"].length)
        {
            fontDescriptor.fontFamily = @"Courier";
        }
        else if ([lowercaseFontFamily rangeOfString:@"cursive"].length)
        {
            fontDescriptor.stylisticClass = kCTFontScriptsClass;
            fontDescriptor.fontFamily = nil;
        }
        else if ([lowercaseFontFamily rangeOfString:@"sans-serif"].length)
        {
            // too many matches (24)
            // fontDescriptor.stylisticClass = kCTFontSansSerifClass;
            fontDescriptor.fontFamily = @"Helvetica";
        }
        else if ([lowercaseFontFamily rangeOfString:@"serif"].length)
        {
            // kCTFontTransitionalSerifsClass = Baskerville
            // kCTFontClarendonSerifsClass = American Typewriter
            // kCTFontSlabSerifsClass = Courier New
            // 
            // strangely none of the classes yields Times
            fontDescriptor.fontFamily = @"Times New Roman";
        }
        else if ([lowercaseFontFamily rangeOfString:@"fantasy"].length)
        {
            fontDescriptor.fontFamily = @"Papyrus"; // only available on iPad
        }
        else if ([lowercaseFontFamily rangeOfString:@"monospace"].length) 
        {
            fontDescriptor.monospaceTrait = YES;
            fontDescriptor.fontFamily = nil;
        }
        else
        {
            // probably custom font registered in info.plist
            fontDescriptor.fontFamily = fontFamily;
        }
    }
    
    NSString *fontStyle = [[styles objectForKey:@"font-style"] lowercaseString];
    if (fontStyle)
    {
        if ([fontStyle isEqualToString:@"normal"])
        {
            fontDescriptor.italicTrait = NO;
        }
        else if ([fontStyle isEqualToString:@"italic"] || [fontStyle isEqualToString:@"oblique"])
        {
            fontDescriptor.italicTrait = YES;
        }
        else if ([fontStyle isEqualToString:@"inherit"])
        {
            // nothing to do
        }
    }
    
    NSString *fontWeight = [[styles objectForKey:@"font-weight"] lowercaseString];
    if (fontWeight)
    {
        if ([fontWeight isEqualToString:@"normal"])
        {
            fontDescriptor.boldTrait = NO;
        }
        else if ([fontWeight isEqualToString:@"bold"])
        {
            fontDescriptor.boldTrait = YES;
        }
        else if ([fontWeight isEqualToString:@"bolder"])
        {
            fontDescriptor.boldTrait = YES;
        }
        else if ([fontWeight isEqualToString:@"lighter"])
        {
            fontDescriptor.boldTrait = NO;
        }
        else 
        {
            // can be 100 - 900
            
            NSInteger value = [fontWeight intValue];
            
            if (value<=600)
            {
                fontDescriptor.boldTrait = NO;
            }
            else 
            {
                fontDescriptor.boldTrait = YES;
            }
        }
    }
    
    
    NSString *decoration = [[styles objectForKey:@"text-decoration"] lowercaseString];
    if (decoration)
    {
        if ([decoration isEqualToString:@"underline"])
        {
            self.underlineStyle = kCTUnderlineStyleSingle;
        }
        else if ([decoration isEqualToString:@"line-through"])
        {
            self.strikeOut = YES;
        }
        else if ([decoration isEqualToString:@"none"])
        {
            // remove all
            self.underlineStyle = kCTUnderlineStyleNone;
            self.strikeOut = NO;
        }
        else if ([decoration isEqualToString:@"overline"])
        {
            //TODO: add support for overline decoration
        }
        else if ([decoration isEqualToString:@"blink"])
        {
            //TODO: add support for blink decoration
        }
        else if ([decoration isEqualToString:@"inherit"])
        {
            // nothing to do
        }
    }
    
    NSString *alignment = [[styles objectForKey:@"text-align"] lowercaseString];
    if (alignment)
    {
        if ([alignment isEqualToString:@"left"])
        {
            self.paragraphStyle.textAlignment = kCTLeftTextAlignment;
        }
        else if ([alignment isEqualToString:@"right"])
        {
            self.paragraphStyle.textAlignment = kCTRightTextAlignment;
        }
        else if ([alignment isEqualToString:@"center"])
        {
            self.paragraphStyle.textAlignment = kCTCenterTextAlignment;
        }
        else if ([alignment isEqualToString:@"justify"])
        {
            self.paragraphStyle.textAlignment = kCTJustifiedTextAlignment;
        }
        else if ([alignment isEqualToString:@"inherit"])
        {
            // nothing to do
        }
    }
    
    NSString *shadow = [styles objectForKey:@"text-shadow"];
    if (shadow)
    {
        self.shadows = [shadow arrayOfCSSShadowsWithCurrentTextSize:fontDescriptor.pointSize currentColor:textColor];
    }
    
    NSString *lineHeight = [[styles objectForKey:@"line-height"] lowercaseString];
    if (lineHeight)
    {
        if ([lineHeight isEqualToString:@"normal"])
        {
            self.paragraphStyle.lineHeightMultiple = 0.0; // default
        }
        else if ([lineHeight isEqualToString:@"inherit"])
        {
            // no op, we already inherited it
        }
        else if ([lineHeight isNumeric])
        {
            self.paragraphStyle.lineHeight = fontDescriptor.pointSize * (CGFloat)[lineHeight intValue];
        }
        else // interpret as length
        {
            self.paragraphStyle.lineHeight = [lineHeight pixelSizeOfCSSMeasureRelativeToCurrentTextSize:fontDescriptor.pointSize];
        }
    }
}

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
    DTHTMLElement *newObject = [[DTHTMLElement allocWithZone:zone] init];
    
    newObject.fontDescriptor = self.fontDescriptor; // copy
    newObject.paragraphStyle = self.paragraphStyle; // copy
    
    newObject.underlineStyle = self.underlineStyle;
    newObject.tagContentInvisible = self.tagContentInvisible;
    newObject.textColor = self.textColor; // copy
    newObject.strikeOut = self.strikeOut;
    newObject.superscriptStyle = self.superscriptStyle;
    
    newObject.link = self.link; // copy
    
    newObject.fontCache = self.fontCache; // reference
    
    return newObject;
}

#pragma mark Properties

- (NSMutableDictionary *)fontCache
{
    if (!_fontCache)
    {
        _fontCache = [[NSMutableDictionary alloc] init];
    }
    
    return _fontCache;
}

- (BOOL)isInline
{
    if (_isInline<0)
    {
        _isInline = [tagName isInlineTag];
    }
    
    return _isInline;
}

@synthesize fontDescriptor;
@synthesize paragraphStyle;
@synthesize textColor;
@synthesize tagName;
@synthesize text;
@synthesize link;
@synthesize underlineStyle;
@synthesize textAttachment;
@synthesize tagContentInvisible;
@synthesize strikeOut;
@synthesize superscriptStyle;
@synthesize headerLevel;
@synthesize shadows;
@synthesize isInline;
@synthesize fontCache = _fontCache;


@end


