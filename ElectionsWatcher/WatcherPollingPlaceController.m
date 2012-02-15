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

@synthesize saveDelegate;
@synthesize pollingPlace;
@synthesize settings;

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
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone 
                                                                                            target: self.saveDelegate 
                                                                                            action: @selector(didFinishEditingPollingPlace:)] autorelease];
    
    self.title = @"Участок";
    
    [self loadSettings];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Settings management

- (void) loadSettings {
    NSFileManager *fm   = [NSFileManager defaultManager];
    NSArray*  paths     = NSSearchPathForDirectoriesInDomains ( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString* settingsPath = [[paths lastObject] stringByAppendingPathComponent: @"WatcherPollingPlace.plist"];
    
    NSError *error = nil;
    
    if ( [fm fileExistsAtPath: settingsPath] ) {
        self.settings = [NSDictionary dictionaryWithContentsOfFile: settingsPath];
        if ( error ) 
            NSLog ( @"error opening settings: %@", error.description );
        
    } else {
        NSString *defaultPath = [[NSBundle mainBundle] pathForResource: @"WatcherPollingPlace" 
                                                                ofType: @"plist"];
        
        self.settings = [NSDictionary dictionaryWithContentsOfFile: defaultPath];
        
        if ( error ) 
            NSLog ( @"error opening settings: %@", error.description );
        
        [fm copyItemAtPath: defaultPath toPath: settingsPath error: &error];
        
        if ( error ) 
            NSLog ( @"error copying settings to docs path: %@", error.description );
    }
    
    [self.tableView reloadData];
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
    
    if ( existingItems.count ) {
        return [existingItems lastObject];
    } else {
        ChecklistItem *item = [NSEntityDescription insertNewObjectForEntityForName: @"ChecklistItem" 
                                                            inManagedObjectContext: appDelegate.managedObjectContext];
        [appDelegate.managedObjectContext save: nil];
        return item;
    }
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
        pollingPlace.number = [nf numberFromString: item.value];
    
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
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.managedObjectContext save: nil];
}

@end
