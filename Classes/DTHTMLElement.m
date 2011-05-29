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
#import "DTTextAttachment.h"
#import "NSAttributedString+HTML.h"

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
    
    [_textColor release];
	[backgroundColor release];
	
    [tagName release];
    [text release];
    [link release];
    
    [shadows release];
    
    [_fontCache release];
	[_additionalAttributes release];
    
    [super dealloc];
}


- (NSDictionary *)attributesDictionary
{
    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	// copy additional attributes
	if (_additionalAttributes)
	{
		[tmpDict setDictionary:_additionalAttributes];
	}
    
    // add text attachment
    if (textAttachment)
    {
        // need run delegate for sizing
        CTRunDelegateRef embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(textAttachment);
        [tmpDict setObject:(id)embeddedObjectRunDelegate forKey:(id)kCTRunDelegateAttributeName];
        
        // add attachment
        [tmpDict setObject:textAttachment forKey:@"DTTextAttachment"];
		
		// --- begin workaround for image squishing bug in iOS < 4.2
		
		// add a font that is display height plus a bit more for the descender
		self.fontDescriptor.fontName = @"Times New Roman";
		self.fontDescriptor.fontFamily = nil;
		self.fontDescriptor.pointSize = textAttachment.displaySize.height*0.5+0.3*self.fontDescriptor.pointSize;
		CTFontRef font = (CTFontRef)[self.fontDescriptor newMatchingFont];
        [tmpDict setObject:(id)font forKey:(id)kCTFontAttributeName];
		CFRelease(font);
		
		// --- end workaround
		
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
        [tmpDict setObject:[NSNumber numberWithBool:YES] forKey:@"DTStrikeOut"];
    }
    
    // set underline style
    if (underlineStyle)
    {
        [tmpDict setObject:[NSNumber numberWithInteger:underlineStyle] forKey:(id)kCTUnderlineStyleAttributeName];
        
        // we could set an underline color as well if we wanted, but not supported by HTML
        //      [attributes setObject:(id)[UIColor redColor].CGColor forKey:(id)kCTUnderlineColorAttributeName];
    }
    
    if (_textColor)
    {
        [tmpDict setObject:(id)[_textColor CGColor] forKey:(id)kCTForegroundColorAttributeName];
    }
	
	if (backgroundColor)
	{
		[tmpDict setObject:(id)[backgroundColor CGColor] forKey:@"DTBackgroundColor"];
	}
	
	if (superscriptStyle)
	{
		[tmpDict setObject:(id)[NSNumber numberWithInt:superscriptStyle] forKey:(id)kCTSuperscriptAttributeName];
	}
    
    // add paragraph style
    self.paragraphStyle.paragraphSpacing = self.fontDescriptor.pointSize;
    
	CTParagraphStyleRef newParagraphStyle = [self.paragraphStyle createCTParagraphStyle];
    [tmpDict setObject:(id)newParagraphStyle forKey:(id)kCTParagraphStyleAttributeName];
	CFRelease(newParagraphStyle);
    
    // add shadow array if applicable
    if (shadows)
    {
        [tmpDict setObject:shadows forKey:@"DTShadows"];
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
		if (self.fontVariant == DTHTMLElementFontVariantNormal)
		{
			return [[[NSAttributedString alloc] initWithString:text attributes:attributes] autorelease];
		}
		else
		{
            if ([self.fontDescriptor supportsNativeSmallCaps])
            {
                DTCoreTextFontDescriptor *smallDesc = [self.fontDescriptor copy];
                smallDesc.smallCapsFeature = YES;
                
                CTFontRef smallerFont = [smallDesc newMatchingFont];
                
                NSMutableDictionary *smallAttributes = [attributes mutableCopy];
                [smallAttributes setObject:(id)smallerFont forKey:(id)kCTFontAttributeName];
                CFRelease(smallerFont);
                
                [smallDesc release];

                return [[[NSAttributedString alloc] initWithString:text attributes:smallAttributes] autorelease];
            }
            
			return [NSAttributedString synthesizedSmallCapsAttributedStringWithText:text attributes:attributes];
		}
    }
}

- (NSAttributedString *)prefixForListItemWithCounter:(NSInteger)counter
{
    // make a font without italic or bold
    DTCoreTextFontDescriptor *fontDesc = [self.fontDescriptor copy];
    fontDesc.boldTrait = NO;
    fontDesc.italicTrait = NO;
    
    CTFontRef font = [fontDesc newMatchingFont];
    [fontDesc release];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:(id)font forKey:(id)kCTFontAttributeName];
    CFRelease(font);
    
    // add paragraph style (this has the tabs)
	CTParagraphStyleRef newParagraphStyle = [self.paragraphStyle createCTParagraphStyle];
    [attributes setObject:(id)newParagraphStyle forKey:(id)kCTParagraphStyleAttributeName];
	CFRelease(newParagraphStyle);
    
    switch (self.listStyle) 
    {
        case DTHTMLElementListStyleNone:
        {
            return nil;
        }
        case DTHTMLElementListStyleCircle:
        {
            return [[[NSAttributedString alloc] initWithString:@"\x09\u25e6\x09" attributes:attributes] autorelease];
        }
        case DTHTMLElementListStyleDecimal:
        {
            NSString *string = [NSString stringWithFormat:@"\x09%d.\x09", counter];
            return [[[NSAttributedString alloc] initWithString:string attributes:attributes] autorelease];
        }
        case DTHTMLElementListStyleDecimalLeadingZero:
        {
            NSString *string = [NSString stringWithFormat:@"\x09%02d.\x09", counter];
            return [[[NSAttributedString alloc] initWithString:string attributes:attributes] autorelease];
        }
        case DTHTMLElementListStyleDisc:
        {
            return [[[NSAttributedString alloc] initWithString:@"\x09\u2022\x09" attributes:attributes] autorelease];
        }
        case DTHTMLElementListStyleUpperAlpha:
        case DTHTMLElementListStyleUpperLatin:
        {
			char letter = 'A' + counter-1;
			NSString *string = [NSString stringWithFormat:@"\x09%c.\x09", letter];
			
            return [[[NSAttributedString alloc] initWithString:string attributes:attributes] autorelease];
        }
        case DTHTMLElementListStyleLowerAlpha:
        case DTHTMLElementListStyleLowerLatin:
        {
			char letter = 'a' + counter-1;
			NSString *string = [NSString stringWithFormat:@"\x09%c.\x09", letter];

            return [[[NSAttributedString alloc] initWithString:string attributes:attributes] autorelease];
        }
        case DTHTMLElementListStylePlus:
        {
            return [[[NSAttributedString alloc] initWithString:@"\x09+\x09" attributes:attributes] autorelease];
        }
        case DTHTMLElementListStyleUnderscore:
        {
            return [[[NSAttributedString alloc] initWithString:@"\x09_\x09" attributes:attributes] autorelease];
        }
        default:
            return nil;
    }
    
    return nil;
}


- (void)parseStyleString:(NSString *)styleString
{
    NSDictionary *styles = [styleString dictionaryOfCSSStyles];
    
    NSString *fontSize = [styles objectForKey:@"font-size"];
    if (fontSize)
    {
        if ([fontSize isNumeric])
        {
            fontDescriptor.pointSize = [fontSize pixelSizeOfCSSMeasureRelativeToCurrentTextSize:fontDescriptor.pointSize]; // already multiplied with textScale
        }
        else
        {
            // absolute sizes based on 12.0 CoreText default size, Safari has 16.0
            
            if ([fontSize isEqualToString:@"smaller"])
            {
                fontDescriptor.pointSize /= 1.2f;
            }
            else if ([fontSize isEqualToString:@"larger"])
            {
                fontDescriptor.pointSize *= 1.2f;
            }
            else if ([fontSize isEqualToString:@"xx-small"])
            {
                fontDescriptor.pointSize = 9.0f/1.3333f * textScale;
            }
            else if ([fontSize isEqualToString:@"x-small"])
            {
                fontDescriptor.pointSize = 10.0f/1.3333f * textScale;
            }
            else if ([fontSize isEqualToString:@"small"])
            {
                fontDescriptor.pointSize = 13.0f/1.3333f * textScale;
            }
            else if ([fontSize isEqualToString:@"medium"])
            {
                fontDescriptor.pointSize = 16.0f/1.3333f * textScale;
            }
            else if ([fontSize isEqualToString:@"large"])
            {
                fontDescriptor.pointSize = 22.0f/1.3333f * textScale;
            }
            else if ([fontSize isEqualToString:@"x-large"])
            {
                fontDescriptor.pointSize = 24.0f/1.3333f * textScale;
            }
            else if ([fontSize isEqualToString:@"xx-large"])
            {
                fontDescriptor.pointSize = 37.0f/1.3333f * textScale;
            }
            else if ([fontSize isEqualToString:@"inherit"])
            {
                fontDescriptor.pointSize = parent.fontDescriptor.pointSize;
            }
        }
    }
    
    NSString *color = [styles objectForKey:@"color"];
    if (color)
    {
        self.textColor = [UIColor colorWithHTMLName:color];       
    }
	
	NSString *bgColor = [styles objectForKey:@"background-color"];
    if (bgColor)
    {
        self.backgroundColor = [UIColor colorWithHTMLName:bgColor];       
    }
    
	NSString *floatString = [styles objectForKey:@"float"];
	
	if (floatString)
	{
		if ([floatString isEqualToString:@"left"])
		{
			floatStyle = DTHTMLElementFloatStyleLeft;
		}
		else if ([floatString isEqualToString:@"right"])
		{
			floatStyle = DTHTMLElementFloatStyleRight;
		}
		else if ([floatString isEqualToString:@"none"])
		{
			floatStyle = DTHTMLElementFloatStyleNone;
		}
	}
	
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
            fontDescriptor.fontFamily = @"Courier";
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
        self.shadows = [shadow arrayOfCSSShadowsWithCurrentTextSize:fontDescriptor.pointSize currentColor:_textColor];
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
            self.paragraphStyle.lineHeightMultiple = [lineHeight floatValue];
//            self.paragraphStyle.minimumLineHeight = fontDescriptor.pointSize * (CGFloat)[lineHeight intValue];
//            self.paragraphStyle.maximumLineHeight = self.paragraphStyle.minimumLineHeight;
        }
        else // interpret as length
        {
            self.paragraphStyle.minimumLineHeight = [lineHeight pixelSizeOfCSSMeasureRelativeToCurrentTextSize:fontDescriptor.pointSize];
            self.paragraphStyle.maximumLineHeight = self.paragraphStyle.minimumLineHeight;
        }
    }
	
	NSString *fontVariantStr = [[styles objectForKey:@"font-variant"] lowercaseString];
	if (fontVariantStr)
	{
		if ([fontVariantStr isEqualToString:@"small-caps"])
		{
			fontVariant = DTHTMLElementFontVariantSmallCaps;
		}
		else if ([fontVariantStr isEqualToString:@"inherit"])
		{
			fontVariant = DTHTMLElementFontVariantInherit;
		}
		else
		{
			fontVariant = DTHTMLElementFontVariantNormal;
		}
	}
    
    NSString *listStyleStr = [[styles objectForKey:@"list-style"] lowercaseString];
	if (listStyleStr)
	{
		if ([listStyleStr isEqualToString:@"inherit"])
		{
			listStyle = DTHTMLElementListStyleInherit;
		}
		else if ([listStyleStr isEqualToString:@"none"])
		{
			listStyle = DTHTMLElementListStyleNone;
		}
		else if ([listStyleStr isEqualToString:@"circle"])
		{
			listStyle = DTHTMLElementListStyleCircle;
		}		
		else if ([listStyleStr isEqualToString:@"decimal"])
		{
			listStyle = DTHTMLElementListStyleDecimal;
		}
		else if ([listStyleStr isEqualToString:@"decimal-leading-zero"])
		{
			listStyle = DTHTMLElementListStyleDecimalLeadingZero;
		}        
		else if ([listStyleStr isEqualToString:@"disc"])
		{
			listStyle = DTHTMLElementListStyleDisc;
		}
		else if ([listStyleStr isEqualToString:@"upper-alpha"]||[listStyleStr isEqualToString:@"upper-latin"])
		{
			listStyle = DTHTMLElementListStyleUpperAlpha;
		}		
		else if ([listStyleStr isEqualToString:@"lower-alpha"]||[listStyleStr isEqualToString:@"lower-latin"])
		{
			listStyle = DTHTMLElementListStyleLowerAlpha;
		}		
		else if ([listStyleStr isEqualToString:@"plus"])
		{
			listStyle = DTHTMLElementListStylePlus;
		}        
		else if ([listStyleStr isEqualToString:@"underscore"])
		{
			listStyle = DTHTMLElementListStyleUnderscore;
		}  
        else
        {
            listStyle = DTHTMLElementListStyleInherit;
        }
	}
}

- (void)addAdditionalAttribute:(id)attribute forKey:(id)key
{
	if (!_additionalAttributes)
	{
		_additionalAttributes = [[NSMutableDictionary alloc] init];
	}
	
	[_additionalAttributes setObject:attribute forKey:key];
}

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
    DTHTMLElement *newObject = [[DTHTMLElement allocWithZone:zone] init];
    
    newObject.fontDescriptor = self.fontDescriptor; // copy
    newObject.paragraphStyle = self.paragraphStyle; // copy
    
    newObject.fontVariant = self.fontVariant;
    
    newObject.underlineStyle = self.underlineStyle;
    newObject.tagContentInvisible = self.tagContentInvisible;
    newObject.textColor = self.textColor;
	newObject.isColorInherited = YES;
	newObject.backgroundColor = self.backgroundColor;
    newObject.strikeOut = self.strikeOut;
    newObject.superscriptStyle = self.superscriptStyle;
	newObject.shadows = self.shadows;
    
    newObject.link = self.link; // copy
	
	newObject.preserveNewlines = self.preserveNewlines;
    
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

- (void)setTextColor:(UIColor *)textColor
{
	if (_textColor != textColor)
	{
		[_textColor release];
		
		_textColor = [textColor retain];
		isColorInherited = NO;
	}
}

- (DTHTMLElementFontVariant)fontVariant
{
	if (fontVariant == DTHTMLElementFontVariantInherit)
	{
		if (parent)
		{
			return parent.fontVariant;
		}
		
		return DTHTMLElementFontVariantNormal;
	}
	
	return fontVariant;
}

- (DTHTMLElementListStyle)listStyle
{
	if (listStyle == DTHTMLElementListStyleInherit)
	{
        // defaults
        if ([tagName isEqualToString:@"ul"])
        {
            return DTHTMLElementListStyleDisc;
        }
        else if ([tagName isEqualToString:@"ol"])
        {
            return DTHTMLElementListStyleDecimal;
        }

		if (parent)
		{
			return parent.listStyle;
		}
		
        
		return DTHTMLElementListStyleNone;
	}
	
	return listStyle;
}



@synthesize parent;
@synthesize fontDescriptor;
@synthesize paragraphStyle;
@synthesize textColor = _textColor;
@synthesize backgroundColor;
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
@synthesize floatStyle;
@synthesize isColorInherited;
@synthesize preserveNewlines;
@synthesize fontVariant;
@synthesize listStyle;
@synthesize textScale;

@synthesize fontCache = _fontCache;



@end


