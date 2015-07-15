//
//  CTLineUtils.m
//  DTCoreText
//
//  Created by Oleksandr Deundiak on 7/15/15.
//  Copyright 2015. All rights reserved.
//

#import "CTLineUtils.h"

BOOL areLinesEqual(CTLineRef line1, CTLineRef line2)
{
    CFArrayRef glyphRuns1 = CTLineGetGlyphRuns(line1);
    CFArrayRef glyphRuns2 = CTLineGetGlyphRuns(line2);
    int runCount1 = CFArrayGetCount(glyphRuns1), runCount2 = CFArrayGetCount(glyphRuns2);
    
    if (runCount1 != runCount2)
        return NO;
    
    for (int i = 0; i < runCount1; i++)
    {
        CTRunRef run1 = CFArrayGetValueAtIndex(glyphRuns1, i);
        CTRunRef run2 = CFArrayGetValueAtIndex(glyphRuns2, i);
        
        int countInRun1 = CTRunGetGlyphCount(run1), countInRun2 = CTRunGetGlyphCount(run2);
        if (countInRun1 != countInRun2)
            return NO;
        
        const CGGlyph* glyphs1 = CTRunGetGlyphsPtr(run1);
        const CGGlyph* glyphs2 = CTRunGetGlyphsPtr(run2);
        
        for (int j = 0; j < countInRun1; j++) {
            if (glyphs1[j] != glyphs2[j])
                return NO;
        }
    }
    
    return YES;
}

CFIndex getTruncationIndex(CTLineRef line, CTLineRef trunc)
{
    CFIndex truncCount = CFArrayGetCount(CTLineGetGlyphRuns(trunc));
    
    CFArrayRef lineRuns = CTLineGetGlyphRuns(line);
    CFIndex lineRunsCount = CFArrayGetCount(lineRuns);
    
    CTRunRef lineLastRun = CFArrayGetValueAtIndex(lineRuns, lineRunsCount - truncCount - 1);
    
    CFRange lastRunRange = CTRunGetStringRange(lineLastRun);
    
    return lastRunRange.location = lastRunRange.length;
}