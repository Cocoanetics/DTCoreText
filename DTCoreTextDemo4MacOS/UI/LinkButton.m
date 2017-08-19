//
//  DTLinkButton.m
//
//  Created by cntrump on 2017/8/7.
//

#import "LinkButton.h"

// constant for notification
NSString *DTLinkButtonDidHighlightNotification = @"DTLinkButtonDidHighlightNotification";

@interface LinkButton () {
    NSURL *_URL;
    NSString *_GUID;

    CGSize _minimumHitSize;
    BOOL _showsTouchWhenHighlighted;
    NSTrackingArea *_area;
}

@end

@implementation LinkButton

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DTLinkButtonDidHighlightNotification object:nil];
    [self removeTrackingArea:_area];
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.bordered = NO;
        [self setButtonType:NSButtonTypeMomentaryChange];

        _showsTouchWhenHighlighted = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(highlightNotification:) name:DTLinkButtonDidHighlightNotification object:nil];

        _area =[[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow owner:self userInfo:nil];
        [self addTrackingArea:_area];
    }

    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    CGContextRef ctx = [NSGraphicsContext currentContext].graphicsPort;
    
    if (self.isHighlighted) {
        if (_showsTouchWhenHighlighted) {
            NSBezierPath *roundedPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:3.0 yRadius:3.0];
            CGContextSetGrayFillColor(ctx, 0.73f, 0.4f);
            [roundedPath fill];
        }
    }

    [super drawRect:dirtyRect];
}

- (void)highlightNotification:(NSNotification *)notification {
    if ([notification object] == self) {
        // that was me
        return;
    }

    NSDictionary *userInfo = [notification userInfo];

    NSString *guid = [userInfo objectForKey:@"GUID"];

    if ([guid isEqualToString:_GUID]) {
        BOOL highlighted = [[userInfo objectForKey:@"Highlighted"] boolValue];
        if (self.isHighlighted == highlighted) {
            return;
        }

        [self highlight:highlighted];
        [self setNeedsDisplay];
    }
}

- (void)mouseEntered:(NSEvent *)event {
    [super mouseEntered:event];
    [self postHighlighted:YES];
}

- (void)mouseExited:(NSEvent *)event {
    [super mouseExited:event];
    [self postHighlighted:NO];
}

- (void)mouseMoved:(NSEvent *)event {
    [super mouseMoved:event];

    if (!self.isHighlighted) {
        [self postHighlighted:YES];
    }
}

- (void)mouseDown:(NSEvent *)event {
    [super mouseDown:event];
    [self postHighlighted:NO];
}

- (void)postHighlighted:(BOOL)highlighted {
    [self highlight:highlighted];
    [self setNeedsDisplay];

    // notify other parts of the same link
    if (_GUID) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:highlighted], @"Highlighted", _GUID, @"GUID", nil];

        [[NSNotificationCenter defaultCenter] postNotificationName:DTLinkButtonDidHighlightNotification object:self userInfo:userInfo];
    }
}

@end
