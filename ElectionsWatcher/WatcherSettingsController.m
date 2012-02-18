//
//  WatcherSettingsController.m
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherSettingsController.h"
#import "WatcherChecklistScreenCell.h"
#import "WatcherManualProfileController.h"
#import "WatcherProfile.h"
#import "AppDelegate.h"

@implementation WatcherSettingsController

@synthesize settings;

static NSString *settingsSections[] = { @"auth_selection", @"observer_info" };

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if ( self ) {
        self.title = @"Я"; // NSLocalizedString(@"First", @"First");
        self.tabBarItem.image = [UIImage imageNamed:@"profile"];
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
    [settings release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *defaultPath = [[NSBundle mainBundle] pathForResource: @"WatcherSettings" 
                                                            ofType: @"plist"];
    self.settings = [NSDictionary dictionaryWithContentsOfFile: defaultPath];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    [appDelegate.watcherProfile addObserver: self 
                                 forKeyPath: @"fbNickname" 
                                    options: NSKeyValueObservingOptionNew 
                                    context: nil];
    
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableViewController

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    return [[self.settings allKeys] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[section]];
    return [sectionInfo objectForKey: @"title"];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[section]];
    return [[sectionInfo objectForKey: @"items"] count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( indexPath.section == 0 ) {
        return 35;
    } else {
        NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
        NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
        NSString *itemTitle = [itemInfo objectForKey: @"title"];
        
        CGSize labelSize = [itemTitle sizeWithFont: [UIFont boldSystemFontOfSize: 13] 
                                 constrainedToSize: CGSizeMake(280, 120) 
                                     lineBreakMode: UILineBreakModeWordWrap];
        
        return labelSize.height + 65;
    }
}

- (void) tableView: (UITableView *) tableView willDisplayCell: (UITableViewCell *) cell forRowAtIndexPath: (NSIndexPath *) indexPath {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    
    if ( indexPath.section == 0 ) {
        cell.textLabel.text = [itemInfo objectForKey: @"title"];
        
        if ( [@"manual" isEqualToString: [itemInfo objectForKey: @"name"]] ) {
            AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
            
            if ( appDelegate.watcherProfile.firstName.length )
                cell.detailTextLabel.text = [NSString stringWithFormat: @"%@ %@", 
                                             appDelegate.watcherProfile.firstName, appDelegate.watcherProfile.lastName];
        }
        
        if ( [@"facebook" isEqualToString: [itemInfo objectForKey: @"name"]] ) {
            AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
            if ( appDelegate.watcherProfile.fbNickname.length )
                cell.detailTextLabel.text = appDelegate.watcherProfile.fbNickname;
        }
    } else {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: [itemInfo objectForKey: @"name"], @"ITEM_NAME", nil];
        NSArray *results = [appDelegate executeFetchRequest: @"findItemByName" 
                                                  forEntity: @"ChecklistItem" 
                                             withParameters: params];
        
        if ( results.count ) {
            [(WatcherChecklistScreenCell *) cell setChecklistItem: [results lastObject]];
        } else {
            ChecklistItem *checklistItem = [NSEntityDescription insertNewObjectForEntityForName: @"ChecklistItem" 
                                                                         inManagedObjectContext: appDelegate.managedObjectContext];
            [(WatcherChecklistScreenCell *) cell setChecklistItem: checklistItem];
        }
    }
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    NSString *cellId = [NSString stringWithFormat: @"SettingsCell_%d_%d", indexPath.section, indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
    
    if ( indexPath.section == 0 ) {
        if ( cell == nil )
            cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleValue1 reuseIdentifier: cellId] autorelease];
        
        cell.textLabel.text = nil;
    } else {
        NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
        NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
        
        if ( cell == nil ) {
            cell = [[[WatcherChecklistScreenCell alloc] initWithStyle: UITableViewCellStyleDefault 
                                                      reuseIdentifier: cellId 
                                                         withItemInfo: itemInfo] autorelease];
            [(WatcherChecklistScreenCell *) cell setSaveDelegate: self];
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( indexPath.section == 0 ) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
        NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
        
        if ( [@"facebook" isEqualToString: [itemInfo objectForKey: @"name"]] ) {
            if ( ![appDelegate.facebook isSessionValid] )
                [appDelegate.facebook authorize: nil];
        }
        
        if ( [@"manual" isEqualToString: [itemInfo objectForKey: @"name"]] ) {
            WatcherManualProfileController *profileController = [[WatcherManualProfileController alloc] initWithNibName: @"WatcherManualProfileController" bundle: nil];
            profileController.profileControllerDelegate = self;
            
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController: profileController];
            nc.navigationBar.tintColor = [UIColor blackColor];
            [self presentModalViewController: nc animated: YES];
            [profileController release];
            [nc release];
            
        }
    }
}

#pragma mark - Attribute save delegate

- (void) didSaveAttributeItem:(ChecklistItem *)item {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSError *error = nil;
    [appDelegate.managedObjectContext save: &error];
    
    if ( error ) 
        NSLog(@"error saving settings attribute: %@", error.description);
}

-(BOOL)isCancelling {
    return NO;
}

#pragma mark - Profile save delegate

- (void) watcherManualProfileControllerDidCancel: (WatcherManualProfileController *) controller {
    [self dismissModalViewControllerAnimated: YES];
}

- (void) watcherManualProfileController: (WatcherManualProfileController *) controller
                         didSaveProfile: (WatcherProfile *) watcherProfile {
    
    [self dismissModalViewControllerAnimated: YES];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSError *error = nil;
    [appDelegate.managedObjectContext save: &error];
    
    if ( error ) 
        NSLog(@"error saving profile attribute: %@", error.description);
}

#pragma mark - Key/value observation 

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context {
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ( object == appDelegate.watcherProfile && [@"fbNickname" isEqualToString: keyPath] )
        [self.tableView reloadData];
}


@end
