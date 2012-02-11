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

@implementation WatcherChecklistSectionController

@synthesize sectionData;
@synthesize sectionIndex;

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
    
    self.title = [sectionData objectForKey: @"title"];
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

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *screens = [self.sectionData objectForKey: @"screens"];
    NSDictionary *screenInfo = [screens objectAtIndex: indexPath.row];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSDictionary *bindParams = [NSDictionary dictionaryWithObjectsAndKeys: 
                                [NSNumber numberWithInt: sectionIndex], @"SECTION_INDEX",
                                [NSNumber numberWithInt: indexPath.row], @"SCREEN_INDEX", nil];
    
    NSArray *results = [appDelegate executeFetchRequest: @"findItemsByScreen" forEntity: @"ChecklistItem" withParameters: bindParams];
    
    cell.textLabel.text = [screenInfo objectForKey: @"title"];
    cell.detailTextLabel.text = [results count] ? [NSString stringWithFormat: @"Отмечено %d пунктов", [results count]] : @"Нарушений не отмечено";
    
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
    screenController.sectionIndex = self.sectionIndex;
    
    [self.navigationController pushViewController: screenController animated: YES];
    [screenController release];
}

@end
