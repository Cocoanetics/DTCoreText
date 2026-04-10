//
//  DemoSnippetsViewController.h
//  DTCoreText
//
//  Created by Sam Soffes on 1/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DemoSnippetsViewController : UITableViewController {

	NSArray *_snippets;
	
	NSCache *cellCache;
}

@end
