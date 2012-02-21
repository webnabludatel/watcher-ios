//
//  WatcherChecklistSectionController.m
//  ElectionsWatcher
//
//  Created by xfire on 22.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherChecklistSectionController.h"
#import "WatcherChecklistScreenController.h"
#import "AppDelegate.h"
#import "PollingPlace.h"
#import "WatcherProfile.h"

@implementation WatcherChecklistSectionController

@synthesize sectionData;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self) {
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)dealloc {
    [sectionData release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle: @"Вернуться" 
                                                                              style: UIBarButtonItemStylePlain 
                                                                             target: nil 
                                                                             action: nil] autorelease];
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
    
    CGFloat height = self.navigationController.navigationBar.frame.size.height-10;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160, height)];
    label.font = [UIFont boldSystemFontOfSize: 12];
    label.text = [sectionData objectForKey: @"title"];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 2;
    label.textAlignment = UITextAlignmentCenter;
    
    self.navigationItem.titleView = label;
    
    [label release];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
//    self.title = [sectionData objectForKey: @"title"];
    [self.tableView reloadData];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.sectionData objectForKey: @"screens"] count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *screens = [self.sectionData objectForKey: @"screens"];
    NSDictionary *screenInfo = [screens objectAtIndex: indexPath.row];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSArray *checklistItems = [[appDelegate.watcherProfile.currentPollingPlace checklistItems] allObjects];
    NSPredicate *screenPredicate = [NSPredicate predicateWithFormat: @"SELF.sectionName LIKE %@ && SELF.screenIndex == %d", 
                                    [self.sectionData objectForKey: @"name"], indexPath.row];
    NSArray *screenItems = [checklistItems filteredArrayUsingPredicate: screenPredicate];
    
    cell.textLabel.text = [screenInfo objectForKey: @"title"];
    cell.detailTextLabel.text = [screenItems count] ? [NSString stringWithFormat: @"Отмечено %d пунктов", [screenItems count]] : @"Отметок нет";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"screenInfoCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *screens = [self.sectionData objectForKey: @"screens"];
    
    WatcherChecklistScreenController *screenController = [[WatcherChecklistScreenController alloc] initWithStyle: UITableViewStyleGrouped];
    screenController.screenInfo = [screens objectAtIndex: indexPath.row];
    screenController.screenIndex = indexPath.row;
    screenController.sectionName = [self.sectionData objectForKey: @"name"];
    
    [self.navigationController pushViewController: screenController animated: YES];
    [screenController release];
}

@end
