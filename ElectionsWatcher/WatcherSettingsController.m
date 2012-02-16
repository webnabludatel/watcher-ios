//
//  WatcherSettingsController.m
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherSettingsController.h"
#import "WatcherChecklistScreenCell.h"
#import "AppDelegate.h"
#import "PollingPlace.h"
#import "WatcherPollingPlaceController.h"

@implementation WatcherSettingsController

@synthesize settings;

static NSString *settingsSections[] = { @"personal_info" };

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if ( self ) {
        self.title = @"Профиль"; // NSLocalizedString(@"First", @"First");
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[section]];
    return [sectionInfo objectForKey: @"title"];
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    return [[self.settings allKeys] count]+1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( section == 0 ) {
        NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[section]];
        return [[sectionInfo objectForKey: @"items"] count];
    } else {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                        forEntity: @"PollingPlace" 
                                                   withParameters: nil];
        return [pollingPlaces count]+1;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( indexPath.section == 0 ) {
        NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
        NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
        NSString *itemTitle = [itemInfo objectForKey: @"title"];
        
        CGSize labelSize = [itemTitle sizeWithFont: [UIFont boldSystemFontOfSize: 13] 
                                 constrainedToSize: CGSizeMake(280, 120) 
                                     lineBreakMode: UILineBreakModeWordWrap];
        
        return labelSize.height + 70;
    } else {
        return 60;
    }
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    if  ( indexPath.section == 0 ) {
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
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: [itemInfo objectForKey: @"name"], @"ITEM_NAME", nil];
        NSArray *results = [appDelegate executeFetchRequest: @"findItemByName" 
                                                  forEntity: @"ChecklistItem" 
                                             withParameters: params];
        
        if ( results.count ) {
            [(WatcherChecklistScreenCell *) cell setChecklistItem: [results lastObject]];
        } else {
            [(WatcherChecklistScreenCell *) cell setChecklistItem: [NSEntityDescription insertNewObjectForEntityForName: @"ChecklistItem" 
                                                                                                 inManagedObjectContext: appDelegate.managedObjectContext]];
            [appDelegate.managedObjectContext save: nil];
        }
        
        return cell;
    } else {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                        forEntity: @"PollingPlace" 
                                                   withParameters: nil];

        NSString *cellId = [NSString stringWithFormat: @"PollingPlaceCell_%d_%d", indexPath.section, indexPath.row];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
        
        if ( cell == nil ) {
            cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellId] autorelease];
        }
        
        if ( indexPath.row < pollingPlaces.count ) {
            PollingPlace *pollingPlace = [pollingPlaces objectAtIndex: indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat: @"%@ № %@", pollingPlace.type, pollingPlace.number];
            cell.textLabel.textAlignment = UITextAlignmentLeft;
            
            if ( pollingPlace == appDelegate.currentPollingPlace ) 
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
            
        } else {
            cell.textLabel.text = @"Добавить участок...";
            cell.textLabel.textAlignment = UITextAlignmentCenter;
        }
        
        return cell;
        
    }
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                    forEntity: @"PollingPlace" 
                                               withParameters: nil];
    if ( indexPath.section == 1 ) {
        if ( indexPath.row < pollingPlaces.count ) {
            AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
            appDelegate.currentPollingPlace = [pollingPlaces objectAtIndex: indexPath.row];
            [self.tableView reloadData];
        } else {
            WatcherPollingPlaceController *pollingPlaceController = [[WatcherPollingPlaceController alloc] initWithNibName: @"WatcherPollingPlaceController" bundle: nil];
            pollingPlaceController.pollingPlaceControllerDelegate = self;
            pollingPlaceController.pollingPlace = [NSEntityDescription insertNewObjectForEntityForName: @"PollingPlace" 
                                                                                inManagedObjectContext: [appDelegate managedObjectContext]];
            
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController: pollingPlaceController];
            nc.navigationBar.tintColor = [UIColor blackColor];
            [self presentModalViewController: nc animated: YES];
            [pollingPlaceController release];
            [nc release];
        }
    }
    
}

#pragma mark - Polling place controller delegate

-(void)watcherPollingPlaceController:(WatcherPollingPlaceController *)controller didSavePollingPlace:(PollingPlace *)pollinngPlace {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.managedObjectContext save: nil];
    
    appDelegate.currentPollingPlace = controller.pollingPlace;
    
    [self dismissModalViewControllerAnimated: YES];
    [self.tableView reloadData];
}

-(void)watcherPollingPlaceControllerDidCancel:(WatcherPollingPlaceController *)controller {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.managedObjectContext deleteObject: controller.pollingPlace];
    [self dismissModalViewControllerAnimated: YES];
    [self.tableView reloadData];
}

#pragma mark - Attribute save delegate

- (void) didSaveAttributeItem:(ChecklistItem *)item {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.managedObjectContext save: nil];
}

-(BOOL)isCancelling {
    return NO;
}

@end
