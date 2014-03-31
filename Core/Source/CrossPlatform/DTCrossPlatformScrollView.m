//
//  DTCrossPlatformScrollView.m
//  DTCoreText
//
//  Created by Michael Markowski on 21/02/14.
//

#import "DTCrossPlatformScrollView.h"

@implementation DTCrossPlatformScrollView

#if !TARGET_OS_IPHONE

- (void)setContentView:(NSClipView *)contentView {
    [super setContentView:contentView];
    if (contentView) {
        [contentView setPostsBoundsChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:)
                                                     name:NSViewBoundsDidChangeNotification object:contentView];
    } else {
        [contentView setPostsBoundsChangedNotifications:NO];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    return [[self documentView] size];
}

- (void)setContentOffset:(CGPoint)contentOffset {
    [[self documentView] scrollPoint:contentOffset];
}

- (void)setContentSize:(CGSize)size {
    [[self documentView] setFrameSize:size];
}

#endif



@end
