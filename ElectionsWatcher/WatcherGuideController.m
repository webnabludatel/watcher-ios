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
    
    self.watcherGuideView.delegate = self;
    
    UIImage * prevImage   = [UIImage imageNamed:@"guide_back"];
    UIImage * nextImage   = [UIImage imageNamed:@"guide_forward"];
    UISegmentedControl *prevNextControl = [[[UISegmentedControl alloc] initWithItems: 
                                            [NSArray arrayWithObjects: prevImage, nextImage, nil]] autorelease];
    prevNextControl.momentary = YES;
    prevNextControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView: prevNextControl] autorelease];
    [prevNextControl addTarget: self action: @selector(navigateBackOrForward:) forControlEvents: UIControlEventValueChanged];

    [prevNextControl setEnabled: self.watcherGuideView.canGoBack forSegmentAtIndex:0];
    [prevNextControl setEnabled: self.watcherGuideView.canGoForward forSegmentAtIndex:1];    
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

    NSString *bundlePath = [[NSBundle mainBundle] pathForResource: @"WatcherGuide" ofType: @"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath: bundlePath];
    NSString *indexPath = [bundle pathForResource: @"index" ofType: @"html"];
    
    NSURL *indexUrl = [NSURL fileURLWithPath: indexPath];
    [self.watcherGuideView loadRequest: [NSURLRequest requestWithURL: indexUrl]];
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
        cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellId] autorelease];
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
    NSString *trimmedSearchString = [searchString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    for ( NSString *filename in guideContents) {
        NSString *filepath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: filename];
        NSString *contents = [NSString stringWithContentsOfFile: filepath encoding: NSUTF8StringEncoding error: nil];
        if ( [contents rangeOfString: trimmedSearchString options: NSCaseInsensitiveSearch].location != NSNotFound ) {
            NSString *htmlTitle = [contents stringByMatching: @"<h1>(.+?)</h1>" 
                                                     options: RKLCaseless 
                                                     inRange: NSMakeRange(0, contents.length) 
                                                     capture: 1 
                                                       error: nil];
            if ( htmlTitle.length ) {
                NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys: 
                                        filepath, @"path", htmlTitle, @"title", nil];
                [self.searchResults addObject: result];
            }
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

#pragma mark - Back/forward navigation

- (void) navigateBackOrForward: (id) sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
    
    if ( segmentedControl.selectedSegmentIndex == 0 )
        [self.watcherGuideView goBack];
    
    if ( segmentedControl.selectedSegmentIndex == 1 )
        [self.watcherGuideView goForward];
    
}

#pragma mark - UIWebView delegate

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    UISegmentedControl *prevNextControl = (UISegmentedControl *) self.navigationItem.leftBarButtonItem.customView;
    [prevNextControl setEnabled: webView.canGoBack forSegmentAtIndex:0];
    [prevNextControl setEnabled: webView.canGoForward forSegmentAtIndex:1];    
    
}

@end
