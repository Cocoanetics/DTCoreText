Setup Guide
===========

You have multiple options available for integrating DTCoreText into your own apps. Ranked from most to least convenient they are:

- [Using Cocoapods](#Cocoapods)
- [As Sub-Project and/or Git Submodule](#Subproject)
- [As Framework](#Framework)

DTCoreText is designed to be included as static library from a subproject, it embeds several classes from the **DTFoundation** project. If you want to use DTFoundation as well in your project you need to use the "Static Library (no DTFoundation)" target to avoid duplicate symbols.

GitHub offers tar balls for the individual tagged versions but you shouldn't try to set these up with your project because those are missing the external references. Doing a recursive clone insures that you get all the files from all involved GitHub repositories.

Requirements
------------

DTCoreText needs a minimum iOS deployment target of iOS 4.2 because of:

- NSCache
- GCD-based threading and locking
- Blocks
- ARC

Support for OS X is currently being developed.

<a id="Cocoapods"></a>
Integrating via Cocoapods
-------------------------

Having [set up Cocoapods](http://www.cocoanetics.com/2013/01/digging-into-cocoapods/) you add DTCoreText to your `Podfile` like this:

    platform :ios
    pod 'DTCoreText'

This always gets the latest version of the pod spec from the global repository. It also automatically resolves the DTFoundation reference.

Cocoapods works by copying all source files into an Xcode project that compiles into a static library. It also automatically sets up all header search path and dependencies.

One mild disadvantage of using Cocoapods is that you cannot easily make changes and submit them as pull requests. But generally you should not need to modify DTCoreText code anyway.

<a id="Subproject"></a>
Integrating via Sub-Project
---------------------------

This is the recommended approach as it lets Xcode see all the project symbols and dependencies and also allows for execution of the special build rule that processes the `default.css` file into a link-able form.

If you use `git` as SCM of your apps you would add DTCoreText as a submodule, if not then you would simply clone the project into an Externals sub-folder of your project. The repo URL can either be the one of the master repository or - if you plan to [contribute to it](http://www.cocoanetics.com/2012/01/github-fork-fix-pull-request/) - could be a fork of the project.

### Getting the Files

The process of getting the source files of DTCoreText differs slightly whether or not you use `git` for your project's source code management.

#### As Git Submodule

You add DTCoreText as a submodule:

    git submodule add https://github.com/Cocoanetics/DTCoreText.git Externals/DTCoreText
   
DTCoreText has several dependencies into the DTFoundation project. To have git clone the main project and also set up the dependencies do this:
	
    git submodule update --init --recursive
   
Now you have a clone of DTCoreText in Externals/DTCoreText as well as a clone of DTFoundation in Externals/DTCoreText/Core/Externals/DTFoundation.

   
#### As Git Clone

If you don't use git for your project's SCM you clone the project into the Externals folder:

    git clone --recursive https://github.com/Cocoanetics/DTCoreText.git Externals/DTCoreText
   
Now you have a clone of DTCoreText in `Externals/DTCoreText` as well as a clone of DTFoundation in `Externals/DTCoreText/Core/Externals/DTFoundation`.

### Project Setup

You want to add a reference to `DTCoreText.xcodeproj` in your Xcode project so that you can access its targets. You also have to set the header search paths, add some framework/library references and check your linker flags.

#### Adding the Sub-Project

Open the destination project and create an "Externals" group.

Add files… or drag `DTCoreText.xcodeproj` to the Externals group. Make sure to uncheck the Copy checkbox. You want to create a reference, not a copy.

![DTCoreText_Reference](DTCoreText_Reference.png)

#### Adding Dependencies

Add the following to your application target's Build Phases, under *Link Binary With Libraries*:

- **libDTCoreText.a** (target from the DTCoreText sub-project)
- libxml2.dylib
- ImageIO.framework
- QuartzCore.framework
- CoreText.framework
- MobileCoreServices.framework

Adding libDTCoreText creates an implicit dependency. That means if you are building your app and there is no current lib then Xcode would build it first.

You can move all the additional framework and library links that Xcode adds into your frameworks group.

#### Setting up Header Search Paths

For Xcode to find the headers of DTCoreText add `Externals/DTCoreText/Core` to the *User Header Search Paths*. To find the headers of DTFoundation referenced by DTCoreText you also need to add `Externals/DTCoreText/Externals/DTFoundation/Core`. Make sure you select the *Recursive* check box on both.

![DTCoreText_Reference](DTCoreText_Search_Paths.png)

#### Setting Linker Flags

For the linker to be able to find the symbols of DTCoreText, specifically category methods, you need to add the `-ObjC` linker flag:

![DTCoreText_Reference](DTCoreText_Linker_Flags.png)

In Xcode versions before 4.6 you also needed the `-all_load` flag but that appears to no longer be necessary.

#### Resources

DTCoreText uses the `DTCoreTextFontOverrides.plist` to speed up font matching. The version in the Demo App resources has the commonly used font families set up so that it can quickly get the name of a specific font face given font family and the italic and bold settings. It works without this as well, but will be slower. Add your own custom fonts to the plist and include it in your app to make use of this optimization.

The `default.css` stylesheet that is used for defining the default HTML CSS styles is compiled into `default.css.h` via a build rule. It is linked into the static library, so you don't need to do anything there. If you want to customize something then please do so via the parse options documented in the [NSAttributedString HTML Category](../../Categories/NSAttributedString+HTML.html).

#### Smoke Test

At this point your project should build and be able to use DTCoreText functionality. As a quick *Smoke Test* - to see if all is setup correctly - you can test your setup by adding this code to your app delegate:


    #import "DTCoreText.h"

    NSString *html = @"<p>Some Text</p>";
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithHTMLData:data
                                                               documentAttributes:NULL];
    NSLog(@"%@", attrString);

You should see that this executes and that the NSLog outputs a description of the generated attributed string.

<a id="Framework"></a>
Integrating via Framework
-------------------------

There are two framework targets available in the project:

- **Static Framework** - This is the static universal framework for use with iOS apps
- **Mac Framework** - This is a dynamic framework for use with Mac apps

Both include the headers and when adding them to a project Xcode should set up the header search path accordingly.
