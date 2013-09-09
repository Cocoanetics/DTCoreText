DTCoreText Programming Guide
============================

This document is meant to serve as a collection of programming questions related to DTCoreText.

Smoke Test
----------

After having integrated DTCoreText and its dependencies into your project you should be able to build your app be able to use DTCoreText functionality. As a quick *Smoke Test* - to see if all is setup correctly - you can test your setup by adding this code to your app delegate:


    #import "DTCoreText.h"

    NSString *html = @"<p>Some Text</p>";
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithHTMLData:data
                                                               documentAttributes:NULL];
    NSLog(@"%@", attrString);

You should see that this executes and that the NSLog outputs a description of the generated attributed string.

Font Matching Performance
-------------------------

DTCoreText employs an internal lookup table which contains a font face name for each combination of font family and bold and italic traits. This lookup table can be initialized by including a `DTCoreTextFontOverrides.plist` in your app bundle and/or prepopulating it with all available system fonts. Which of these you want to use depends on your app.

If you only use a very limited number of fonts you should have the plist file contain only these.

For most normal use cases you can use the overrides plist that is part of the DTCoreText demo app. This contains most commonly used fonts on iOS.

If you don't know the set of fonts used by your app you can trigger an asynchronous pre-loading of the internal lookup table. To start the loading process you add the following to your app delegate.

    // preload font matching table
    [DTCoreTextFontDescriptor asyncPreloadFontLookupTable];
	 
Calling this does not replace entries already existing in the lookup table, for example loaded from the `DTCoreTextFontOverrides.plist` included in the app bundle.