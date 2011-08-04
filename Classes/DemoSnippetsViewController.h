//
//  DemoSnippetsViewController.h
//  CoreTextExtensions
//
//  Created by Sam Soffes on 1/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@class DTCache;

@interface DemoSnippetsViewController : UITableViewController {

	NSArray *_snippets;
	
	DTCache *cellCache;
}

@end
