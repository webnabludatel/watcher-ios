//
//  SecondViewController.m
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherGuideController.h"
#import "RegexKitLite.h"

@implementation WatcherGuideController

@synthesize watcherGuideView;
@synthesize searchResults;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if ( self ) {
        self.title = @"Справочник"; // NSLocalizedString(@"Second", @"Second");
        self.tabBarItem.image = [UIImage imageNamed:@"guide"];
    }
    
    return self;
}
							
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [watcherGuideView release];
    [searchResults release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void) viewDidLoad
{
    [super viewDidLoad];
    

    NSString *indexPath = [[NSBundle mainBundle] pathForResource: @"golos_index" 
                                                          ofType: @"html"];
    
    NSURL *indexUrl = [NSURL fileURLWithPath: indexPath];
    [self.watcherGuideView loadRequest: [NSURLRequest requestWithURL: indexUrl]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Search results table

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.searchResults count];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *result = [self.searchResults objectAtIndex: indexPath.row];
    cell.textLabel.text = [result objectForKey: @"title"];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"SearchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
    
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellId];
        cell.textLabel.font = [UIFont systemFontOfSize: 12];
        cell.textLabel.numberOfLines = 3;
        cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
    }
    
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *result = [self.searchResults objectAtIndex: indexPath.row];
    if ( result ) {
        NSURL *url = [NSURL fileURLWithPath: [result objectForKey: @"path"]];
        [self.watcherGuideView loadRequest: [NSURLRequest requestWithURL: url]];
        [self.searchDisplayController setActive: NO];
    }
    
}

#pragma mark - Search

-(void) refreshSearchResultsForString: (NSString *) searchString {
    self.searchResults = [NSMutableArray array];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *bundleContents = [fm contentsOfDirectoryAtPath: [[NSBundle mainBundle] bundlePath]  error: nil];
    NSPredicate *guidePredicate = [NSPredicate predicateWithFormat: @"SELF LIKE 'golos*.html'"];
    NSArray *guideContents = [bundleContents filteredArrayUsingPredicate: guidePredicate];
    
    for ( NSString *filename in guideContents) {
        NSString *filepath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: filename];
        NSString *contents = [NSString stringWithContentsOfFile: filepath encoding: NSUTF8StringEncoding error: nil];
        if ( [contents rangeOfString: searchString].location != NSNotFound ) {
            NSString *htmlTitle = [contents stringByMatching: @"<h1>(.+?)</h1>" capture:1];
            NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys: filepath, @"path", htmlTitle, @"title", nil];
            [self.searchResults addObject: result];
        }
    }
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ( [searchText length] >= 5 ) {
        [self refreshSearchResultsForString: searchText];
    }
}

-(void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    self.searchResults = [NSMutableArray array];
}


@end
