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

DTCoreText uses the `DTCoreTextFontOverrides.plist` file - if present in your app bundle - to pre-populate the font matching table. This table has the desired font name for each combination of font family name, italic and bold traits.

Depending on your use case you may want to add your own custom fonts to the plist or use the plist that is part of the DTCoreText demo app.

The override table is populated when a DTCoreTextFontDescriptor class is instantiated for the first time. To start the loading process you can add the following to your app delegate.

    [DTCoreTextFontDescriptor class]; // preload font matching table