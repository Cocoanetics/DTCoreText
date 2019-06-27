//
//  DemoSnippetsViewController.m
//  DTCoreText
//
//  Created by Sam Soffes on 1/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DemoSnippetsViewController.h"
#import "DemoTextViewController.h"
#import "DemoAboutViewController.h"
#import "AutoLayoutDemoViewController.h"

// identifier for cell reuse
NSString * const AttributedTextCellReuseIdentifier = @"AttributedTextCellReuseIdentifier";

@implementation DemoSnippetsViewController
{
	BOOL _useStaticRowHeight;
}

#pragma mark NSObject

- (id)init
{
	self = [super initWithStyle:UITableViewStylePlain];
	
	if (self)
	{
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
	
	//_useStaticRowHeight = YES;
	
	/*
	 if you enable static row height in this demo then the cell height is determined from the tableView.rowHeight. Cells can be reused in this mode.
	 If you disable this then cells are prepared and cached to reused their internal layouter and layoutFrame. Reuse is not recommended since the cells are cached anyway.
	 */
	
	if (_useStaticRowHeight)
	{
		// use a static row height
		self.tableView.rowHeight = 60;
	}
	else
	{
		// establish a cache for prepared cells because heightForRow... and cellForRow... both need the same cell for an index path
		cellCache = [[NSCache alloc] init];
	}
	
	// on iOS 6 we can register the attributed cells for the identifier
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
	[self.tableView registerClass:[DTAttributedTextCell class] forCellReuseIdentifier:AttributedTextCellReuseIdentifier];
#endif
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"About" style:UIBarButtonItemStylePlain target:self action:@selector(showAbout:)];
}

#pragma mark - Actions

- (void)showAbout:(id)sender
{
	DemoAboutViewController *aboutViewController = [[DemoAboutViewController alloc] init];
	[self.navigationController pushViewController:aboutViewController animated:YES];
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

- (BOOL)_canReuseCells
{
	// reuse does not work for variable height
	
	if ([self respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)])
	{
		return NO;
	}
	
	// only reuse cells with fixed height
	return YES;
}

- (DTAttributedTextCell *)tableView:(UITableView *)tableView preparedCellForIndexPath:(NSIndexPath *)indexPath
{
	// workaround for iOS 5 bug
	NSString *key = [NSString stringWithFormat:@"%ld-%ld", (long)indexPath.section, (long)indexPath.row];
	
	DTAttributedTextCell *cell = [cellCache objectForKey:key];

	if (!cell)
	{
		if ([self _canReuseCells])
		{
			cell = (DTAttributedTextCell *)[tableView dequeueReusableCellWithIdentifier:AttributedTextCellReuseIdentifier];
		}
	
		if (!cell)
		{
			cell = [[DTAttributedTextCell alloc] initWithReuseIdentifier:AttributedTextCellReuseIdentifier];
		}
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.hasFixedRowHeight = _useStaticRowHeight;
		
		// cache it, if there is a cache
		[cellCache setObject:cell forKey:key];
	}
	
	[self configureCell:cell forIndexPath:indexPath];
	
	return cell;
}

// disable this method to get static height = better performance
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (_useStaticRowHeight)
	{
		return tableView.rowHeight;
	}
	
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

    if (rowSnippet[@"AutoLayoutTest"]) {
        AutoLayoutDemoViewController *viewController = [[AutoLayoutDemoViewController alloc] init];
        viewController.fileName = rowSnippet[@"File"];
        [self.navigationController pushViewController:viewController animated:YES];
    }
    else {
        DemoTextViewController *viewController = [[DemoTextViewController alloc] init];
        viewController.fileName = [rowSnippet objectForKey:@"File"];
        viewController.baseURL = [NSURL URLWithString:[rowSnippet  objectForKey:@"BaseURL"]];

        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end
