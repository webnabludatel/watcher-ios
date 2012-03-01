//
//  WatcherManualProfileController.m
//  ElectionsWatcher
//
//  Created by xfire on 18.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherManualProfileController.h"
#import "AppDelegate.h"
#import "WatcherChecklistScreenCell.h"
#import "WatcherProfile.h"
#import "WatcherDataManager.h"

@implementation WatcherManualProfileController

static NSString *settingsSections[] = { @"personal_info" };

@synthesize profileControllerDelegate;
@synthesize settings;
@synthesize latestActiveResponder;
@synthesize managedObjectContext = _managedObjectContext;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"ФИО + Email";
    }
    return self;
}

-(void)dealloc {
    [settings release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) mergeContextChanges: (NSNotification *) notification {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.managedObjectContext performSelectorOnMainThread: @selector(mergeChangesFromContextDidSaveNotification:) 
                                                       withObject: notification 
                                                    waitUntilDone: YES];
    
    [appDelegate.dataManager.managedObjectContext performSelector: @selector(mergeChangesFromContextDidSaveNotification:) 
                                                         onThread: appDelegate.dataManager.dataManagerThread 
                                                       withObject: notification 
                                                    waitUntilDone: NO];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *defaultPath = [[NSBundle mainBundle] pathForResource: @"WatcherProfile" 
                                                            ofType: @"plist"];
    self.settings = [NSDictionary dictionaryWithContentsOfFile: defaultPath];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle: @"Сохранить"
                                                                               style: UIBarButtonItemStyleDone
                                                                              target: self
                                                                              action: @selector(handleDoneButton:)] autorelease];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle: @"Отменить"
                                                                              style: UIBarButtonItemStylePlain
                                                                             target: self
                                                                             action: @selector(handleCancelButton:)] autorelease];

    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator: appDelegate.persistentStoreCoordinator];
    
    [[NSNotificationCenter defaultCenter] addObserver: self 
                                             selector: @selector(mergeContextChanges:) 
                                                 name: NSManagedObjectContextDidSaveNotification 
                                               object: _managedObjectContext];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [_managedObjectContext release]; _managedObjectContext = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
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

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[section]];
    return [sectionInfo objectForKey: @"title"];
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    return [[self.settings allKeys] count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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

- (void) tableView: (UITableView *) tableView willDisplayCell: (UITableViewCell *) cell forRowAtIndexPath: (NSIndexPath *) indexPath {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: [itemInfo objectForKey: @"name"], @"ITEM_NAME", nil];
    NSArray *results = [appDelegate executeFetchRequest: @"findItemByName" 
                                              forEntity: @"ChecklistItem" 
                                            withContext: _managedObjectContext
                                         withParameters: params];
    
    if ( results.count ) {
        [(WatcherChecklistScreenCell *) cell setChecklistItem: [results lastObject]];
    } else {
        ChecklistItem *checklistItem = [NSEntityDescription insertNewObjectForEntityForName: @"ChecklistItem" 
                                                                     inManagedObjectContext: _managedObjectContext];
        [(WatcherChecklistScreenCell *) cell setChecklistItem: checklistItem];
    }
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    NSString *cellId = [NSString stringWithFormat: @"SettingsCell_%d_%d", indexPath.section, indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    
    if ( cell == nil ) {
        cell = [[[WatcherChecklistScreenCell alloc] initWithStyle: UITableViewCellStyleDefault 
                                                  reuseIdentifier: cellId 
                                                     withItemInfo: itemInfo
                                                        inContext: _managedObjectContext] autorelease];
        [(WatcherChecklistScreenCell *) cell setSaveDelegate: self];
    }
    
    return cell;
}

#pragma mark - Button handlers

- (void) handleCancelButton: (id) sender {
    [self.latestActiveResponder resignFirstResponder];
    [self.profileControllerDelegate watcherManualProfileControllerDidCancel: self];
}

- (void) handleDoneButton: (id) sender {
    [self.latestActiveResponder resignFirstResponder];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [self.profileControllerDelegate watcherManualProfileController: self 
                                                    didSaveProfile: appDelegate.watcherProfile];
}

#pragma mark - Attribute save delegate 

- (void) didSaveAttributeItem:(ChecklistItem *)item {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];

    NSArray *profileResults = [appDelegate executeFetchRequest: @"findProfile" 
                                                     forEntity: @"WatcherProfile" 
                                                   withContext: _managedObjectContext 
                                                withParameters: [NSDictionary dictionary]];
    
    WatcherProfile *profile = [profileResults lastObject];
    if ( [@"last_name" isEqualToString: item.name] )
        profile.lastName = item.value;
    
    if ( [@"first_name" isEqualToString: item.name] )
        profile.firstName = item.value;
    
    if ( [@"email" isEqualToString: item.name] )
        profile.email = item.value;
    
    [profile addProfileChecklistItemsObject: item];
}

@end
