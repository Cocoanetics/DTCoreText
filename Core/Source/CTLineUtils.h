//
//  CTLineUtils.h
//  DTCoreText
//
//  Created by Oleksandr Deundiak on 7/15/15.
//  Copyright 2015. All rights reserved.
//

#import <CoreText/CoreText.h>

BOOL areLinesEqual(CTLineRef line1, CTLineRef line2);
CFIndex getTruncationIndex(CTLineRef line, CTLineRef trunc);
