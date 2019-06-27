//
//  DTDictationPlaceholderView.m
//  DTRichTextEditor
//
//  Created by Oliver Drobnik on 05.02.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTDictationPlaceholderView.h"

// if you change any of these then also make sure to adjust the sizes in DTDictationPlaceholderTextAttachment
#define DOT_WIDTH 10.0f
#define DOT_DISTANCE 2.5f
#define DOT_OUTSIDE_MARGIN 3.0f

@implementation DTDictationPlaceholderView
{
    NSUInteger _phase;
    NSTimer *_phaseTimer;
}

+ (DTDictationPlaceholderView *)placeholderView;
{
    return [[DTDictationPlaceholderView alloc] initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        [self sizeToFit];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(DOT_OUTSIDE_MARGIN*2.0f + DOT_WIDTH*3.0f + DOT_DISTANCE*2.0f, DOT_OUTSIDE_MARGIN*2.0f + DOT_WIDTH);
}

- (UIColor *)_lightDotColor
{
    return [UIColor colorWithRed:(CGFloat)(238.0/255.0) green:(CGFloat)(128.0/255.0) blue:(CGFloat)(238.0/255.0) alpha:1.0];
}

- (UIColor *)_darkDotColor
{
    return [UIColor colorWithRed:(CGFloat)(191.0/255.0) green:(CGFloat)(51.0/255.0) blue:(CGFloat)(191.0/255.0) alpha:1.0];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
  
	[_phaseTimer invalidate];
	_phaseTimer = nil;
    
    if (newSuperview)
    {
        _phaseTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_phaseTimerTick:) userInfo:nil repeats:YES];
    }
}


- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGRect dotRect = CGRectMake(DOT_OUTSIDE_MARGIN, 4, DOT_WIDTH, DOT_WIDTH);
    
    if (_phase==0)
    {
        CGContextSetFillColorWithColor(ctx, [self _darkDotColor].CGColor);
    }
    else
    {
        CGContextSetFillColorWithColor(ctx, [self _lightDotColor].CGColor);
    }
    
    CGContextFillEllipseInRect(ctx, dotRect);
    
    dotRect.origin.x = DOT_DISTANCE + CGRectGetMaxX(dotRect);
    
    if (_phase==1)
    {
        CGContextSetFillColorWithColor(ctx, [self _darkDotColor].CGColor);
    }
    else
    {
        CGContextSetFillColorWithColor(ctx, [self _lightDotColor].CGColor);
    }
    
    CGContextFillEllipseInRect(ctx, dotRect);

    dotRect.origin.x = DOT_DISTANCE + CGRectGetMaxX(dotRect);
    
    if (_phase==2)
    {
        CGContextSetFillColorWithColor(ctx, [self _darkDotColor].CGColor);
    }
    else
    {
        CGContextSetFillColorWithColor(ctx, [self _lightDotColor].CGColor);
    }
    
    CGContextFillEllipseInRect(ctx, dotRect);
}

- (void)_phaseTimerTick:(id)sender
{
    _phase = (_phase+1)%3;
    [self setNeedsDisplay];
}


@end
