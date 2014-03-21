DTCoreText Programming Guide
============================

This document is meant to serve as a collection of programming questions related to DTCoreText.

Smoke Test
----------

After having integrated DTCoreText and its dependencies into your project you should be able to build your app be able to use DTCoreText functionality. As a quick *Smoke Test* - to see if all is setup correctly - you can test your setup by adding this code to your app delegate:


```
#import "DTCoreText.h"

NSString *html = @"<p>Some Text</p>";
NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];

NSAttributedString *attrString = [[NSAttributedString alloc] initWithHTMLData:data documentAttributes:NULL];
NSLog(@"%@", attrString);
```

You should see that this executes and that the NSLog outputs a description of the generated attributed string.

Using Helvetica Neue Light
--------------------------

If you want to use a specific font to be used there are 2 ways: 1) use the **font** tag specifiying the postscript font face name 2) use the **font-family** CSS attribute and specify an override face name.

Variant 1:

```
<p><font face="HelveticaNeue-Light">HelveticaNeue-Light</font></p>
```

Setting the font face will use exactly this font face if it exists on the system. If not then the fallback mechanism will be used (see below). Tags which modify the bold or italic traits cause the font face to be removed from the inheritance and instead the font family technique be used.

Variant 2:

```
[DTCoreTextFontDescriptor setOverrideFontName:@"HelveticaNeue-Light" forFontFamily:@"Helvetica Neue" bold:NO italic:NO];
```

This has the effect that whenever a font is needed with a family "Helvetica Neue" that is neither bold nor italic then the "HelveticaNeue-Light" font face will be used. 


Font Matching Performance
-------------------------

DTCoreText employs an internal lookup table which contains a font face name for each combination of font family and bold and italic traits. This lookup table can be initialized by including a `DTCoreTextFontOverrides.plist` in your app bundle and/or prepopulating it with all available system fonts. Which of these you want to use depends on your app.

If you only use a very limited number of fonts you should have the plist file contain only these.

For most normal use cases you can use the overrides plist that is part of the DTCoreText demo app. This contains most commonly used fonts on iOS.

If you don't know the set of fonts used by your app you can trigger an asynchronous pre-loading of the internal lookup table. To start the loading process you add the following to your app delegate.

```
// preload font matching table
[DTCoreTextFontDescriptor asyncPreloadFontLookupTable];
```
	 
Calling this does not replace entries already existing in the lookup table, for example loaded from the `DTCoreTextFontOverrides.plist` included in the app bundle.

Setting a Fallback Font Family
------------------------------

When encountering a font family in HTML that is not known to the system the fallback font family is used. This can be set like this:

```
[DTCoreTextFontDescriptor setFallbackFontFamily:@"Helvetica Neue"];
```
	
Note that the font family name must be valid on the system that this run on, either because it is a system font or a font you have installed at runtime. If you try to set an invalid font family name an exception will be thrown.

Getting a Tapped Word
-----------------------

To retrieve the word a user tapped on you get the closest cursor position to the tapped point. Then you iterate over the plain text's words until you find the one that contains the cursor position's string index.

```
- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint location = [gesture locationInView:_textView];
        NSUInteger tappedIndex = [_textView closestCursorIndexToPoint:location];
    
        __block NSRange wordRange = NSMakeRange(0, 0);
    
        [plainText enumerateSubstringsInRange:NSMakeRange(0, [plainText length]) options:NSStringEnumerationByWords usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
            if (NSLocationInRange(tappedIndex, enclosingRange))
            {
                *stop = YES;
                wordRange = substringRange;
            }
        }];
    
        NSString *word = [plainText substringWithRange:wordRange];
        NSLog(@"%d: '%@' word: '%@'", tappedIndex, tappedChar, word);
    }
}
```
    

Visible String Range
--------------------

To retrieve the string range in the `NSAttributedString` you set on an DTAttributedTextView you have to get the scroll view bounds. Then you retrieve an array of lines visible in this rectangle from the DTCoreTextLayoutFrame. Finally you retrieve and create a union of the string ranges.

```
CGRect visibleRect = _textView.bounds;
NSArray *visibleLines = [_textView.attributedTextContentView.layoutFrame linesVisibleInRect:visibleRect];

NSRange stringRange = [visibleLines[0] stringRange];
stringRange = NSUnionRange([[visibleLines lastObject] stringRange], stringRange);

NSLog(@"visible string range: %@", NSStringFromRange(stringRange));
```

Determing Size Required for an Attributed String
------------------------------------------------

When creating a DTCoreTextLayoutFrame you can specify the maximum width and height that should be filled with text. If you specify `CGFLOAT_WIDTH_UNKNOWN` for the frame size width then the needed with will be calculated. If you specify `CGFLOAT_HEIGHT_UNKNOWN` the height will be calculated. You can get the needed size from the layoutFrame's frame property.

```
NSAttributedString *attributedString = ...
DTCoreTextLayouter *layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:attributedString];

CGRect maxRect = CGRectMake(10, 20, CGFLOAT_WIDTH_UNKNOWN, CGFLOAT_HEIGHT_UNKNOWN);
NSRange entireString = NSMakeRange(0, [attributedString length]);
DTCoreTextLayoutFrame *layoutFrame = [layouter layoutFrameWithRect:maxRect range:entireString];

CGSize sizeNeeded = [layoutFrame frame].size;
```


Displaying remote images
------------------------

The best way to display remote images is to use `DTLazyImageView`. 
First you will need to return `DTLazyImageView` instance for your image attachments.

```
- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame
{
    if([attachment isKindOfClass:[DTImageTextAttachment class]])
	 {
        DTLazyImageView *imageView = [[DTLazyImageView alloc] initWithFrame:frame];
        imageView.delegate = self;

        // url for deferred loading
        imageView.url = attachment.contentURL;
        return imageView;
    }
    return nil;
}
```

Then in the in delegate method for `DTLazyImageView` reset the layout for the affected `DTAttributedContextView`.

```
- (void)lazyImageView:(DTLazyImageView *)lazyImageView didChangeImageSize:(CGSize)size 
{
    NSURL *url = lazyImageView.url;
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"contentURL == %@", url];

    // update all attachments that matching this URL
    for (DTTextAttachment *oneAttachment in [self.attributedTextContentView.layoutFrame textAttachmentsWithPredicate:pred]) 
	 {
        oneAttachment.originalSize = size;
    }

    // need to reset the layouter because otherwise we get the old framesetter or cached layout frames
    self.attributedTextContentView.layouter = nil;

    // here we're layouting the entire string,
    // might be more efficient to only relayout the paragraphs that contain these attachments
    [self.attributedTextContentView relayoutText];
}
```

Changing the default font and font size
---------------------------------------
When you want to render the HTML in a different font and fontsize, you need to specify this using the `options` parameter.

```
NSDictionary* options = @{ NSTextSizeMultiplierDocumentOption: [NSNumber numberWithFloat: 1.0],
			  				DTDefaultFontFamily: @"Helvetica Neue",
			  			};

NSString *html = @"<p>Some Text</p>";
NSData* descriptionData = [html dataUsingEncoding:NSUTF8StringEncoding];
NSAttributedString* attributedDescription = [[NSAttributedString alloc] initWithHTMLData:descriptionData options:options documentAttributes:NULL];
```


