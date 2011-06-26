//
//  DemoSnippetsViewController.m
//  CoreTextExtensions
//
//  Created by Sam Soffes on 1/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DemoSnippetsViewController.h"
#import "DemoTextViewController.h"

#import "DTAttributedTextContentView.h"

@implementation DemoSnippetsViewController

#pragma mark NSObject

- (id)init {
	if ((self = [super initWithStyle:UITableViewStylePlain])) {
		self.title = @"Snippets";
		self.tabBarItem.image = [UIImage imageNamed:@"snippets.png"];
	}
	return self;
}


- (void)dealloc {
	[_snippets release];
	[contentViewCache release];
	[super dealloc];
}


#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Load snippets from plist
	NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Snippets" ofType:@"plist"];
	_snippets = [[NSArray alloc] initWithContentsOfFile:plistPath];
}


#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_snippets count];
}


- (DTAttributedTextContentView *)contentViewForIndexPath:(NSIndexPath *)indexPath
{
	if (!contentViewCache)
	{
		contentViewCache = [[NSMutableDictionary alloc] init];
	}
	
	DTAttributedTextContentView *contentView = (id)[contentViewCache objectForKey:indexPath];
	
	if (!contentView)
	{
		NSDictionary *snippet = [_snippets objectAtIndex:indexPath.row];
		
		NSString *title = [snippet objectForKey:@"Title"];
		NSString *description = [snippet objectForKey:@"Description"];
		
		NSString *html = [NSString stringWithFormat:@"<h3>%@</h3><p><font color=\"gray\">%@</font></p>", title, description];
		NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
		NSAttributedString *string = [[[NSAttributedString alloc] initWithHTML:data documentAttributes:NULL] autorelease];
		
		// set width, height is calculated later from text
		CGFloat width = self.view.frame.size.width;
		[DTAttributedTextContentView setLayerClass:nil];
		contentView = [[[DTAttributedTextContentView alloc] initWithAttributedString:string width:width - 20.0] autorelease];
		
		contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		contentView.edgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
		[contentViewCache setObject:contentView forKey:indexPath];
	}
	
	return contentView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	DTAttributedTextContentView *contentView = [self contentViewForIndexPath:indexPath];
	
	return contentView.bounds.size.height+1; // for cell seperator
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *cellIdentifier = @"cellIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	[cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	
	DTAttributedTextContentView *contentView = [self contentViewForIndexPath:indexPath];
	
	contentView.frame = cell.contentView.bounds;
	[cell.contentView addSubview:contentView];
	
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
	[viewController release];
}

@end
