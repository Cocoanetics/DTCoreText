//
//  TextView.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextContentView.h"
#import "NSAttributedString+HTML.h"
#import "NSString+HTML.h"
#import "UIColor+HTML.h"


@interface DTAttributedTextContentView ()

@property (nonatomic) CTFramesetterRef framesetter;
@property (nonatomic) CTFrameRef textFrame;

@end


/* Callbacks */
void MyDeallocationCallback( void* refCon ){
    NSLog(@"Deallocation being set %@", refCon);
}
CGFloat MyGetAscentCallback( void *refCon ){
    NSLog(@"Ascent being set");
    return 20;
}
CGFloat MyGetDescentCallback( void *refCon ){
    NSLog(@"Descent being set");
    return 10;
}

CGFloat MyGetWidthCallback( void* refCon ){
    NSLog(@"Width being set");
    return 10;
}

@implementation DTAttributedTextContentView

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
		
		self.contentMode = UIViewContentModeRedraw;
		self.backgroundColor = [UIColor whiteColor];
		
    }
    return self;
}

/*
 // Example: Using CATextLayer. But it ignores paragraph spacing!
 
 + (Class)layerClass
 {
 return [CATextLayer class];
 }
 
 - (void)awakeFromNib
 {
 NSString *readmePath = [[NSBundle mainBundle] pathForResource:@"README" ofType:@"html"];
 NSString *html = [NSString stringWithContentsOfFile:readmePath encoding:NSUTF8StringEncoding error:NULL];
 NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
 
 NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:NULL];
 
 CATextLayer *textLayer = (CATextLayer *)self.layer;
 
 textLayer.frame = CGRectInset(self.bounds, 10, 10);
 textLayer.string = string;
 textLayer.wrapped = YES;
 }
 
 */


- (void)drawRect:(CGRect)rect 
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// flip the coordinate system
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	// draw
	CTFrameDraw(self.textFrame, context);
}


- (void)dealloc 
{
	if (framesetter)
	{
		CFRelease(framesetter);
	}
	
	if (textFrame)
	{
		CFRelease(textFrame);
	}
	
	[_string release];
	
    [super dealloc];
}

- (CGSize)sizeThatFits:(CGSize)size
{
	CGSize neededSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, CFRangeMake(0, 0), NULL, 
																	 CGSizeMake(self.bounds.size.width-23.0, CGFLOAT_MAX),
																	 NULL);
	
	return CGSizeMake(self.bounds.size.width, ceilf(neededSize.height+20));
}

#pragma mark Properties
- (CTFramesetterRef) framesetter
{
	if (!framesetter)
	{
		framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_string);
	}
	
	return framesetter;
}

- (CTFrameRef)textFrame
{
	if (!textFrame)
	{
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathAddRect(path, NULL, CGRectInset(self.bounds, 10, 10));
		
		textFrame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, 0), path, NULL);
		
		CGPathRelease(path);
	}
	
	return textFrame;
}

- (void)setString:(NSAttributedString *)string
{
	if (string != _string)
	{
		[_string release];
		
		/*
		
		NSMutableAttributedString *tmpStr =[string mutableCopy];
		// create the delegate
		CTRunDelegateCallbacks callbacks;
		callbacks.version = kCTRunDelegateCurrentVersion;
		callbacks.dealloc = MyDeallocationCallback;
		callbacks.getAscent = MyGetAscentCallback;
		callbacks.getDescent = MyGetDescentCallback;
		callbacks.getWidth = MyGetWidthCallback;
		CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, NULL);
		
		// set the delegate as an attribute
		NSDictionary *dict = [NSDictionary dictionaryWithObject:(id)delegate forKey:(id)kCTRunDelegateAttributeName] ;
		[tmpStr setAttributes:dict range:NSMakeRange(0, [tmpStr	length])];
		//CFAttributedStringSetAttribute((CFMutableAttributedStringRef)tmpStr, CFRangeMake(0, [tmp), , delegate);
		
		 CFRelease(delegate);
		
		_string = [tmpStr copy];
		[tmpStr release];
		 */
		
		_string = [string retain];
		
		if (framesetter)
		{
			CFRelease(framesetter);
			framesetter = nil;
		}
		
		if (textFrame)
		{
			CFRelease(textFrame);
			textFrame = nil;
		}
		
		CGSize neededSize = [self sizeThatFits:CGSizeZero];
		self.frame = CGRectMake(0, 0, neededSize.width, neededSize.height);
		
		[self setNeedsDisplay];
	}
}


@synthesize framesetter;
@synthesize textFrame;
@synthesize string = _string;


@end
