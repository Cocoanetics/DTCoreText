//
//  DTCoreTextFunctions.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

/**
 Creates a CTFont from a UIFont
 @param font The `UIFont`
 @returns The matching CTFont
 */
CTFontRef DTCTFontCreateWithUIFont(UIFont *font);