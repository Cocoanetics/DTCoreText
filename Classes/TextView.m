//
//  TextView.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TextView.h"
#import "NSAttributedString+HTML.h"
#import "NSString+HTML.h"
#import "UIColor+HTML.h"


@implementation TextView


- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
    }
    return self;
}

- (void)awakeFromNib
{
	//self.backgroundColor = [UIColor colorWithHTMLName:@"purple"];
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {

    // Drawing code.
	
	//NSString *html = @"<h1>A header</h2><p>Some <b>bold</b> and some <i>italic</i> Text. <FONT COLOR=\"#cc6600\">Possibly</FONT> a <a href=\"http://www.cocoanetics.com\"link</a> too?</p>";
	
	//NSString *html = @"<b>bold</b>,<i>italic</i>,<em>emphasized</em>,<strong>strong</strong> string.\n\tand a tab \t and a tab";
	
	NSString *html = @"<font face=\"Helvetica\" color=\"red\">red <b>bold</b></font><br>Standard<br/><font face=\"Courier\" color=\"blue\">blue<em> italic</font></em><br/></font>Standard";
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:NULL];
	
	NSDictionary *attributes;
	
	NSRange effectiveRange = NSMakeRange(0, 0);
	
	while (attributes = [string attributesAtIndex:effectiveRange.location effectiveRange:&effectiveRange])
	{
		NSLog(@"Range: (%d, %d), %@", effectiveRange.location, effectiveRange.length, attributes);
		effectiveRange.location += effectiveRange.length;
		
		if (effectiveRange.location >= [string length])
		{
			break;
		}
	}
	
	// now for the actual drawing
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// flip the coordinate system
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	

	// layout master
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(
																		   (CFAttributedStringRef)string);
	
	// left column form
	CGMutablePathRef leftColumnPath = CGPathCreateMutable();
	CGPathAddRect(leftColumnPath, NULL, 
				  CGRectMake(0, 0, 
							 self.bounds.size.width,
							 self.bounds.size.height));
	
	// left column frame
	CTFrameRef leftFrame = CTFramesetterCreateFrame(framesetter, 
													CFRangeMake(0, 0),
													leftColumnPath, NULL);
	
	// draw
	CTFrameDraw(leftFrame, context);
	
	// cleanup
	CFRelease(leftFrame);
	CGPathRelease(leftColumnPath);
	CFRelease(framesetter);
	
	[string release];
}


- (void)dealloc {
    [super dealloc];
}


@end
