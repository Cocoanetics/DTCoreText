//
//  DTCrossPlatformScrollView.m
//  DTCoreText
//
//  Created by Michael Markowski on 21/02/14.
//

#import "DTCrossPlatformScrollView.h"

@implementation DTCrossPlatformScrollView

#if !TARGET_OS_IPHONE

- (void)setDocumentView:(id)documentView {
    [super setDocumentView:documentView];
    
    if (self.contentView) {
        [self.contentView setPostsBoundsChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:)
                                                     name:NSViewBoundsDidChangeNotification object:self.contentView];
        _isObservingBoundsChanges = YES;
    } else {
        if (_isObservingBoundsChanges) {
            [self.contentView setPostsBoundsChangedNotifications:NO];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            _isObservingBoundsChanges = NO;
        }
    }
}

- (void)setContentView:(NSClipView *)contentView {
    [super setContentView:contentView];
    if (contentView) {
        [contentView setPostsBoundsChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:)
                                                     name:NSViewBoundsDidChangeNotification object:contentView];
        _isObservingBoundsChanges = YES;
    } else {
        if (_isObservingBoundsChanges) {
            [contentView setPostsBoundsChangedNotifications:NO];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            _isObservingBoundsChanges = NO;
        }
    }
}

- (void)boundsDidChange:(NSNotification*)notification {
    if ([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
		[self.delegate performSelector:@selector(scrollViewDidScroll:) withObject:self];
	}
}

- (CGPoint)contentOffset {
    return [self documentVisibleRect].origin;
}

- (CGSize)contentSize {
    return [[self documentView] frame].size;
}

- (void)setContentOffset:(CGPoint)contentOffset {
    [[self documentView] scrollPoint:contentOffset];
}

- (void)setContentSize:(CGSize)size {
    [[self documentView] setFrameSize:size];
}

+ (BOOL)isCompatibleWithResponsiveScrolling {
    return YES;
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    BOOL shouldScroll = self.scrollEnabled;
    NSRect docBounds = [(NSView*)self.documentView bounds];
    
    if (docBounds.size.width <= self.bounds.size.width &&
        docBounds.size.height <= self.bounds.size.height)
    {
        shouldScroll = NO;
    }
    
    if (shouldScroll) {
        [super scrollWheel:theEvent];
    } else {
        [[self nextResponder] scrollWheel:theEvent];
    }
}

- (void)dealloc
{
    if (_isObservingBoundsChanges) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];        
        _isObservingBoundsChanges = NO;
    }
}
#endif



@end
