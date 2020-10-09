//
//  DTCoreTextLayoutFrameAccessibilityElementGenerator.m
//  DTCoreText
//
//  Created by Austen Green on 3/13/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreTextLayoutFrameAccessibilityElementGenerator.h"

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

#import "DTCoreTextLayoutFrame.h"
#import "DTCoreTextLayoutLine.h"
#import "DTCoreTextGlyphRun.h"
#import "DTAccessibilityElement.h"
#import "DTCoreTextConstants.h"
#import "DTTextAttachment.h"

@implementation DTCoreTextLayoutFrameAccessibilityElementGenerator

- (NSArray *)accessibilityElementsForLayoutFrame:(DTCoreTextLayoutFrame *)frame view:(UIView *)view attachmentViewProvider:(DTAttachmentViewProvider)block
{
	NSMutableArray *elements = [NSMutableArray array];

	for (NSUInteger idx = 0; idx < frame.paragraphRanges.count; idx++)
	{
		NSArray *paragraphElements = [self accessibilityElementsInParagraphAtIndex:idx layoutFrame:frame view:view attachmentViewProvider:block];
		[elements addObjectsFromArray:paragraphElements];
	}
		
	return elements;
}

- (NSArray *)accessibilityElementsInParagraphAtIndex:(NSUInteger)index layoutFrame:(DTCoreTextLayoutFrame *)frame view:(UIView *)view attachmentViewProvider:(DTAttachmentViewProvider)block
{
	NSMutableArray *elements = [NSMutableArray array];
	
	[self enumerateAccessibleGroupsInFrame:frame forParagraphAtIndex:index usingBlock:^(NSDictionary *attrs, NSRange substringRange, BOOL *stop, NSArray *runs) {
		id element = [self accessibilityElementForTextInAttributedString:frame.attributedStringFragment atRange:substringRange attributes:attrs run:runs view:view attachmentViewProvider:block];
		if (element)
			[elements addObject:element];
	}];
	
	return elements;
}

- (void)enumerateAccessibleGroupsInFrame:(DTCoreTextLayoutFrame *)frame forParagraphAtIndex:(NSUInteger)index usingBlock:(void(^)(NSDictionary *attrs, NSRange substringRange, BOOL *stop, NSArray *runs))block
{
	NSValue *value = [frame.paragraphRanges objectAtIndex:index];
	NSRange paragraphRange = value.rangeValue;
	NSArray *lines = [frame linesInParagraphAtIndex:index];
	
	[frame.attributedStringFragment enumerateAttributesInRange:paragraphRange options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
		NSMutableArray *runs = [NSMutableArray array];
		for (DTCoreTextLayoutLine *line in lines)
		{
			[runs addObjectsFromArray:[line glyphRunsWithRange:range]];
		}
		
		block(attrs, range, stop, runs);
	}];
}

- (id)accessibilityElementForTextInAttributedString:(NSAttributedString *)attributedString atRange:(NSRange)range attributes:(NSDictionary *)attributes run:(NSArray *)runs view:(UIView *)view attachmentViewProvider:(DTAttachmentViewProvider)block
{
	DTTextAttachment *attachment = [attributes objectForKey:NSAttachmentAttributeName];
	
	if (attachment != nil)
		return [self viewForAttachment:attachment attachmentViewProvider:block];
	else
		return [self accessibilityElementForTextInAttributedString:attributedString atRange:range attributes:attributes run:runs view:view];
}

- (DTAccessibilityElement *)accessibilityElementForTextInAttributedString:(NSAttributedString *)attributedString atRange:(NSRange)range attributes:(NSDictionary *)attributes run:(NSArray *)runs view:(UIView *)view
{
	NSString *text = [attributedString.string substringWithRange:range];
	
	DTAccessibilityElement *element = [[DTAccessibilityElement alloc] initWithParentView:view];
	element.accessibilityLabel = text;
	element.localCoordinateAccessibilityFrame = [self frameForRuns:runs];
	
	// We're trying to keep the accessibility frame behavior consistent with web view, which seems to do a union of the rects for all the runs composing a single accessibility group,
	// even if that spans across multiple lines.  Set the local coordinate activation point to support multi-line links. A link that is at the end of one line and
	// wraps to the beginning of the next would have a rect that's the size of both lines combined.  The center of that rect would be outside the hit areas for either of the
	// runs individually, so we set the accessibility activation point to be the origin of the first run.
	if (runs.count > 1)
	{
		DTCoreTextGlyphRun *run = [runs objectAtIndex:0];
		element.localCoordinateAccessibilityActivationPoint = run.frame.origin;
	}
	
	element.accessibilityTraits = UIAccessibilityTraitStaticText;
	
	if ([attributes objectForKey:DTLinkAttribute])
		element.accessibilityTraits |= UIAccessibilityTraitLink;
	
	return element;
}

- (UIView *)viewForAttachment:(DTTextAttachment *)attachment attachmentViewProvider:(DTAttachmentViewProvider)block
{
	UIView *view = nil;
	
	if (block)
	{
		view = block(attachment);
	}
	
	return view;
}

- (CGRect)frameForRuns:(NSArray *)runs
{
	CGRect frame = CGRectNull;
	for (DTCoreTextGlyphRun *run in runs)
		frame = CGRectUnion(frame, run.frame);
	
	return frame;
}

@end

#endif
