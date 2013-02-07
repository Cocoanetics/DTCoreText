//
//  DemoSnippetsViewController.m
//  CoreTextExtensions
//
//  Created by Sam Soffes on 1/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DemoSnippetsViewController.h"
#import "DemoTextViewController.h"

@implementation DemoSnippetsViewController

#pragma mark NSObject

- (id)init {
	if ((self = [super initWithStyle:UITableViewStylePlain])) {
		self.title = @"Snippets";
		self.tabBarItem.image = [UIImage imageNamed:@"snippets.png"];
	}
	return self;
}

#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Load snippets from plist
	NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Snippets" ofType:@"plist"];
	_snippets = [[NSArray alloc] initWithContentsOfFile:plistPath];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_snippets count];
}

- (void)configureCell:(DTAttributedTextCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *snippet = [_snippets objectAtIndex:indexPath.row];
	
	NSString *title = [snippet objectForKey:@"Title"];
	NSString *description = [snippet objectForKey:@"Description"];
	
	NSString *html = [NSString stringWithFormat:@"<h3>%@</h3><p><font color=\"gray\">%@</font></p>", title, description];
	
	[cell setHTMLString:html];
	
	cell.attributedTextContextView.shouldDrawImages = YES;
}

- (DTAttributedTextCell *)tableView:(UITableView *)tableView preparedCellForIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"cellIdentifier";

	if (!cellCache)
	{
		cellCache = [[NSCache alloc] init];
	}
	
	// workaround for iOS 5 bug
	NSString *key = [NSString stringWithFormat:@"%d-%d", indexPath.section, indexPath.row];
	
	DTAttributedTextCell *cell = [cellCache objectForKey:key];

	if (!cell)
	{
		// reuse does not work for variable height
		//cell = (DTAttributedTextCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
		if (!cell)
		{
			cell = [[DTAttributedTextCell alloc] initWithReuseIdentifier:cellIdentifier accessoryType:UITableViewCellAccessoryDisclosureIndicator];
		}
		
		// cache it
		[cellCache setObject:cell forKey:key];
	}
	
	[self configureCell:cell forIndexPath:indexPath];
	
	return cell;
}

// disable this method to get static height = better performance
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	DTAttributedTextCell *cell = (DTAttributedTextCell *)[self tableView:tableView preparedCellForIndexPath:indexPath];

	return [cell requiredRowHeightInTableView:tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	DTAttributedTextCell *cell = (DTAttributedTextCell *)[self tableView:tableView preparedCellForIndexPath:indexPath];
	
	return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	NSDictionary *rowSnippet = [_snippets objectAtIndex:indexPath.row];
	
	DemoTextViewController *viewController = [[DemoTextViewController alloc] init];
	viewController.fileName = [rowSnippet objectForKey:@"File"];
	viewController.baseURL = [NSURL URLWithString:[rowSnippet  objectForKey:@"BaseURL"]];
	
	[self.navigationController pushViewController:viewController animated:YES];
}

@end
