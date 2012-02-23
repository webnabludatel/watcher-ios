//
//  WatcherChecklistScreenController.m
//  ElectionsWatcher
//
//  Created by xfire on 22.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherChecklistScreenController.h"
#import "WatcherChecklistScreenCell.h"
#import "AppDelegate.h"
#import "PollingPlace.h"
#import "WatcherProfile.h"

@implementation WatcherChecklistScreenController

@synthesize screenIndex;
@synthesize sectionName;
@synthesize screenInfo;
@synthesize isCancelling;
@synthesize latestActiveResponder;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self) {
        self.tableView.allowsSelection = NO;
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
    [screenInfo release];
    [sectionName release];
    
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
    
    CGFloat height = self.navigationController.navigationBar.frame.size.height-10;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160, height)];
    label.font = [UIFont boldSystemFontOfSize: 12];
    label.text = [screenInfo objectForKey: @"title"];
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
    
//    self.title = [self.screenInfo objectForKey: @"title"];
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

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    return 1;
}

/*
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.screenInfo objectForKey: @"title"];
}
 */

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
    return [[screenInfo objectForKey: @"items"] count];
}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    NSDictionary *itemInfo = [[screenInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    NSString *itemTitle = [itemInfo objectForKey: @"title"];
    int controlType = [[itemInfo objectForKey: @"control"] intValue];
    
    CGSize labelSize;
    
    if ( [itemTitle length] )
        labelSize = [itemTitle sizeWithFont: [UIFont boldSystemFontOfSize: 13] 
                          constrainedToSize: CGSizeMake(280, 120) 
                              lineBreakMode: UILineBreakModeWordWrap];
    else
        labelSize = CGSizeZero;
    
    return controlType == INPUT_COMMENT ? 
            labelSize.height + 140 : 
        itemTitle.length ? 
            labelSize.height + 70 : 60;
}

- (void) tableView: (UITableView *) tableView willDisplayCell: (UITableViewCell *) cell forRowAtIndexPath: (NSIndexPath *) indexPath {
    NSArray *items              = [screenInfo objectForKey: @"items"];
    NSDictionary *itemInfo      = [items objectAtIndex: indexPath.row];
    AppDelegate *appDelegate    = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSArray *checklistItems     = [[appDelegate.watcherProfile.currentPollingPlace checklistItems] allObjects];
    NSPredicate *itemPredicate  = [NSPredicate predicateWithFormat: @"SELF.sectionName LIKE %@ && SELF.screenIndex == %d && SELF.name LIKE %@", 
                                   self.sectionName, self.screenIndex, [itemInfo objectForKey: @"name"]];
    
    NSArray *existingItems = [checklistItems filteredArrayUsingPredicate: itemPredicate];
    ChecklistItem *checklistItem = nil;
    
    if ( existingItems.count ) {
        checklistItem = [existingItems lastObject];
//        [appDelegate.managedObjectContext refreshObject: checklistItem mergeChanges: NO];
        [(WatcherChecklistScreenCell *) cell setChecklistItem: checklistItem];
    } else {
        checklistItem = [NSEntityDescription insertNewObjectForEntityForName: @"ChecklistItem" 
                                                                     inManagedObjectContext: appDelegate.managedObjectContext];
        
        [(WatcherChecklistScreenCell *) cell setChecklistItem: checklistItem];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *items              = [screenInfo objectForKey: @"items"];
    NSDictionary *itemInfo      = [items objectAtIndex: indexPath.row];
//    NSString *CellIdentifier    = [@"inputCell_" stringByAppendingString: [[itemInfo objectForKey: @"control"] stringValue]];
    NSString *CellIdentifier    = [NSString stringWithFormat: @"cell_%d_%d", indexPath.section, indexPath.row];
    UITableViewCell *cell       = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if ( cell == nil ) {
        cell = [[[WatcherChecklistScreenCell alloc] initWithStyle: UITableViewCellStyleDefault 
                                                  reuseIdentifier: CellIdentifier 
                                                     withItemInfo: itemInfo] autorelease];
        
        WatcherChecklistScreenCell *watcherCell = (WatcherChecklistScreenCell *) cell;
        watcherCell.saveDelegate = self;
        watcherCell.checklistCellDelegate = self;
        watcherCell.sectionName = self.sectionName;
        watcherCell.screenIndex = self.screenIndex;
    }

    
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    
    return cell;
}

#pragma mark - Save delegate

-(void)didSaveAttributeItem:(ChecklistItem *)item {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ( ! [appDelegate.watcherProfile.currentPollingPlace.checklistItems containsObject: item] )
        [appDelegate.watcherProfile.currentPollingPlace addChecklistItemsObject: item];
    
    NSError *error = nil;
    [appDelegate.managedObjectContext refreshObject: item mergeChanges: YES]; // required if it's in sync now
    [appDelegate.managedObjectContext save: &error];
    
    if ( error )
        NSLog(@"error saving checklist item: %@", error.description);
}

@end
