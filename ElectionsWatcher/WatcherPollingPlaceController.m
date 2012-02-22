//
//  WatcherPollingPlaceController.m
//  ElectionsWatcher
//
//  Created by xfire on 15.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherPollingPlaceController.h"
#import "WatcherChecklistScreenCell.h"
#import "PollingPlace.h"
#import "AppDelegate.h"

@implementation WatcherPollingPlaceController

static NSString *settingsSections[] = { @"ballot_district_info" };

@synthesize pollingPlaceControllerDelegate;
@synthesize pollingPlace;
@synthesize settings;
@synthesize isCancelling;
@synthesize latestActiveResponder;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle: @"Сохранить"
                                                                               style: UIBarButtonItemStyleDone
                                                                              target: self
                                                                              action: @selector(handleDoneButton:)] autorelease];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle: @"Отменить"
                                                                              style: UIBarButtonItemStylePlain
                                                                             target: self
                                                                             action: @selector(handleCancelButton:)] autorelease];

    self.navigationItem.rightBarButtonItem.tag = 12;
    self.navigationItem.leftBarButtonItem.tag = 13;
    
    self.title = @"Участок";
    
    NSString *defaultPath = [[NSBundle mainBundle] pathForResource: @"WatcherPollingPlace" 
                                                            ofType: @"plist"];
    self.settings = [NSDictionary dictionaryWithContentsOfFile: defaultPath];
    self.isCancelling = NO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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

#pragma mark - Save/cancel handlers

- (void) handleDoneButton: (id) sender {
    if ( self.pollingPlace.type.length && self.pollingPlace.nameOrNumber.length && self.pollingPlace.region.intValue ) {
        [self.latestActiveResponder resignFirstResponder];
        [pollingPlaceControllerDelegate watcherPollingPlaceController: self didSavePollingPlace: self.pollingPlace];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Ошибка" 
                                                            message: @"Не заполнены обязательные поля" 
                                                           delegate: nil 
                                                  cancelButtonTitle: @"OK" 
                                                  otherButtonTitles: nil];
        
        [alertView show];
        [alertView release];
    }
}

- (void) handleCancelButton: (id) sender {
    [self.latestActiveResponder resignFirstResponder];
    
    self.isCancelling = YES;
    [pollingPlaceControllerDelegate watcherPollingPlaceControllerDidCancel: self];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[section]];
    return [sectionInfo objectForKey: @"title"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.settings allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[section]];
    return [[sectionInfo objectForKey: @"items"] count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    NSString *itemTitle = [itemInfo objectForKey: @"title"];
    
    CGSize labelSize = [itemTitle sizeWithFont: [UIFont boldSystemFontOfSize: 13] 
                             constrainedToSize: CGSizeMake(280, 120) 
                                 lineBreakMode: UILineBreakModeWordWrap];
    
    return labelSize.height + 70;
}

- (ChecklistItem *) findOrCreateItem: (NSDictionary *) itemInfo {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"SELF.name LIKE %@", [itemInfo objectForKey: @"name"]];
    NSArray *existingItems = [[self.pollingPlace.checklistItems allObjects] filteredArrayUsingPredicate: predicate];
    
    if ( existingItems.count )
        return [existingItems lastObject];
    else
        return [NSEntityDescription insertNewObjectForEntityForName: @"ChecklistItem" 
                                             inManagedObjectContext: appDelegate.managedObjectContext];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = [NSString stringWithFormat: @"SettingsCell_%d_%d", indexPath.section, indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    
    if ( cell == nil ) {
        cell = [[[WatcherChecklistScreenCell alloc] initWithStyle: UITableViewCellStyleDefault 
                                                  reuseIdentifier: cellId 
                                                     withItemInfo: itemInfo] autorelease];
        
        [(WatcherChecklistScreenCell *) cell setSaveDelegate: self];
    }
    
    [(WatcherChecklistScreenCell *) cell setChecklistItem: [self findOrCreateItem: itemInfo]];
    
    return cell;
}

#pragma mark - Save attribute delegate

- (void) didSaveAttributeItem: (ChecklistItem *) item {
    if ( ! [self.pollingPlace.checklistItems containsObject: item] )
        [self.pollingPlace addChecklistItemsObject: item];
    
    NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];    
    
    if ( [@"district_number" isEqualToString: item.name] )
        pollingPlace.nameOrNumber = item.value;
    
    if ( [@"district_region" isEqualToString: item.name] )
        pollingPlace.region = [nf numberFromString: item.value];
    
    if ( [@"district_type" isEqualToString: item.name] ) 
        pollingPlace.type = item.value;
    
    if ( [@"district_chairman" isEqualToString: item.name] ) 
        pollingPlace.chairman = item.value;
    
    if ( [@"district_secretary" isEqualToString: item.name] )
        pollingPlace.secretary = item.value;
    
    if ( [@"district_watchers_count" isEqualToString: item.name] )
        pollingPlace.totalObservers = [nf numberFromString: item.value];
    
    if ( [@"district_banner_photo" isEqualToString: item.name] )
        pollingPlace.mediaItems = item.mediaItems;
    
    [nf release];
}

@end
