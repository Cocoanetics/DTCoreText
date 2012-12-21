//
//  DTCoreTextFunctions.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCoreTextFunctions.h"

CTFontRef DTCTFontCreateWithUIFont(UIFont *font)
{
	return CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
}