//
//  DTHTMLElementLI.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 27.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLElementLI.h"

@implementation DTHTMLElementLI


- (NSUInteger)_indexOfListItemInListRoot:(DTHTMLElement *)listRoot
{
	NSInteger index = -1;
	
	for (DTHTMLElement *oneElement in listRoot.childNodes)
	{
		if ([oneElement isKindOfClass:[DTHTMLElementLI class]])
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

- (NSAttributedString *)attributedString
{
	NSMutableAttributedString *tmpString = [[NSMutableAttributedString alloc] init];
	
	DTCSSListStyle *effectiveList = [self.paragraphStyle.textLists lastObject];
	
	DTHTMLElement *listRoot = self.parentElement;
	
	NSUInteger counter = [self _indexOfListItemInListRoot:listRoot]+effectiveList.startingItemNumber;
	
	// need to get prefix text color from list parent
	NSAttributedString *prefixString = [NSAttributedString prefixForListItemWithCounter:counter listStyle:effectiveList listIndent:self.paragraphStyle.listIndent attributes:[listRoot attributesDictionary]];
	
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
