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
	if(line1 == nil || line2 == nil) {
		return NO;
	}
	
    CFArrayRef glyphRuns1 = CTLineGetGlyphRuns(line1);
    CFArrayRef glyphRuns2 = CTLineGetGlyphRuns(line2);
    CFIndex runCount1 = CFArrayGetCount(glyphRuns1), runCount2 = CFArrayGetCount(glyphRuns2);
    
    if (runCount1 != runCount2)
        return NO;
    
    for (CFIndex i = 0; i < runCount1; i++)
    {
        CTRunRef run1 = CFArrayGetValueAtIndex(glyphRuns1, i);
        CTRunRef run2 = CFArrayGetValueAtIndex(glyphRuns2, i);
        
        CFIndex countInRun1 = CTRunGetGlyphCount(run1), countInRun2 = CTRunGetGlyphCount(run2);
        if (countInRun1 != countInRun2)
            return NO;
        
        const CGGlyph* constGlyphs1 = CTRunGetGlyphsPtr(run1);
		CGGlyph* glyphs1 = NULL;
        if (constGlyphs1 == NULL)
        {
            glyphs1 = (CGGlyph*)malloc(countInRun1*sizeof(CGGlyph));
            CTRunGetGlyphs(run1, CFRangeMake(0, countInRun1), glyphs1);
			constGlyphs1 = glyphs1;
        }
        
        const CGGlyph* constGlyphs2 = CTRunGetGlyphsPtr(run2);
		CGGlyph* glyphs2 = NULL;
        if (constGlyphs2 == NULL)
        {
            glyphs2 = (CGGlyph*)malloc(countInRun2*sizeof(CGGlyph));
            CTRunGetGlyphs(run2, CFRangeMake(0, countInRun2), glyphs2);
			constGlyphs2 = glyphs2;
        }
        
        BOOL result = YES;
        for (CFIndex j = 0; j < countInRun1; j++)
        {
            if (constGlyphs1[j] != constGlyphs2[j])
            {
                result = NO;
                break;
            }
        }
        
        if (glyphs1 != NULL)
            free(glyphs1);
        
        if (glyphs2 != NULL)
            free(glyphs2);
        
        if (!result)
            return NO;
    }
    
    return YES;
}

CFIndex getTruncationIndex(CTLineRef line, CTLineRef trunc)
{
	if (line == nil || trunc == nil) return 0;
	
	CFIndex truncCount = CFArrayGetCount(CTLineGetGlyphRuns(trunc));
    
    CFArrayRef lineRuns = CTLineGetGlyphRuns(line);
    CFIndex lineRunsCount = CFArrayGetCount(lineRuns);
    
		CFIndex index = lineRunsCount - truncCount - 1;

		// If the index is negative, CFArrayGetValueAtIndex will crash on iOS 10 beta.
		// We will just return 0 because on iOS 9, CFArrayGetValueAtIndex would have
		// returned nil anyways and the return truncation index would be 0.
		// Apple might have enabled an assert that only appears in the iOS 10 beta
		// release, but we will just avoid passing invalid arguments just to be safe.
		if (index < 0)
		{
			return 0;
		}
		else
		{
			CTRunRef lineLastRun = CFArrayGetValueAtIndex(lineRuns, index);

			CFRange lastRunRange = CTRunGetStringRange(lineLastRun);

			return lastRunRange.location = lastRunRange.length;
		}
}
