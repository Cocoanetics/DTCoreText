//
//  DTHTMLElementLI.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 27.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTListItemHTMLElement.h"

@implementation DTListItemHTMLElement


- (NSUInteger)_indexOfListItemInListRoot:(DTHTMLElement *)listRoot
{
	@synchronized(self)
	{
		NSInteger index = -1;
		
		for (DTHTMLElement *oneElement in listRoot.childNodes)
		{
			if ([oneElement isKindOfClass:[DTListItemHTMLElement class]])
			{
				index++;
			}
			
			if (oneElement == self)
			{
				break;
			}
		}
		
		return index;
	}
}

- (NSAttributedString *)attributedString
{
	NSMutableAttributedString *tmpString = [[NSMutableAttributedString alloc] init];
	
	DTCSSListStyle *effectiveList = [self.paragraphStyle.textLists lastObject];
	
	DTHTMLElement *listRoot = self.parentElement;
	
	NSUInteger counter = [self _indexOfListItemInListRoot:listRoot]+effectiveList.startingItemNumber;
	
	// make a temporary version of self that has same font attributes as list root
	DTListItemHTMLElement *tmpCopy = [[DTListItemHTMLElement alloc] init];
	[tmpCopy inheritAttributesFromElement:self];

/*
 // OD: disabled, was causing problems in the editor. Who does really use 3-level nested lists?!
 
	DTCSSListStyleType type = listRoot.listStyle.type;
    // Only force Times New Roman if bullet types
    if (type == DTCSSListStyleTypeCircle || type == DTCSSListStyleTypeSquare || type == DTCSSListStyleTypeDisc)
    {
        // force bullet font to be Times New Roman because iOS 6 has a larger level 3 bullet
        tmpCopy.fontDescriptor = listRoot.fontDescriptor;
        tmpCopy.fontDescriptor.fontFamily = @"Times New Roman";
    }
*/
	// take the parents text color
	tmpCopy.textColor = listRoot.textColor;

	NSAttributedString *prefixString = [NSAttributedString prefixForListItemWithCounter:counter listStyle:effectiveList listIndent:self.paragraphStyle.listIndent attributes:[tmpCopy attributesDictionary]];
	
	if (prefixString)
	{
		[tmpString appendAttributedString:prefixString];
	}

	if ([self.childNodes count])
	{
		DTHTMLElement *firstchild = [self.childNodes objectAtIndex:0];
		if (firstchild.displayStyle != DTHTMLElementDisplayStyleInline)
		{
			[tmpString appendString:@"\n"];
		}
	}
	
	NSAttributedString *childrenString = [super attributedString];
	
	if (childrenString)
	{
		[tmpString appendAttributedString:childrenString];
	}

	return tmpString;
}

@end
