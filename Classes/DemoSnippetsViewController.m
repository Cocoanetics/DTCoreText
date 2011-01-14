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


- (void)dealloc {
	[_snippets release];
	[super dealloc];
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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = [_snippets objectAtIndex:indexPath.row];
    
    return cell;
}


#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	DemoTextViewController *viewController = [[DemoTextViewController alloc] init];
	viewController.fileName = [_snippets objectAtIndex:indexPath.row];
	[self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
}

@end
