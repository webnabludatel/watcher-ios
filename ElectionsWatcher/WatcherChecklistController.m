//
//  FirstViewController.m
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherChecklistController.h"
#import "WatcherChecklistSectionController.h"
#import "WatcherPollingPlaceController.h"
#import "AppDelegate.h"
#import "PollingPlace.h"

@implementation WatcherChecklistController

@synthesize watcherChecklist;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if ( self ) {
        self.tabBarItem.image = [UIImage imageNamed:@"checklist"];
        self.tabBarItem.title = @"Наблюдение";
        self.watcherChecklist = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"WatcherChecklist" 
                                                                                                            ofType: @"plist"]];
    }
    
    return self;
}
							
- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void) dealloc {
    [watcherChecklist release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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
    
    [self.tableView reloadData];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.navigationItem.title = appDelegate.currentPollingPlace ?
        [NSString stringWithFormat: @"Наблюдение на %@ № %@", 
         appDelegate.currentPollingPlace.type, appDelegate.currentPollingPlace.number] : 
        @"Наблюдение";
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

#pragma mark - UITableView

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    return appDelegate.currentPollingPlace ? 2 : 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ( section == 0 ) {
        NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                        forEntity: @"PollingPlace" 
                                                   withParameters: nil];
        return [pollingPlaces count]+1;
    } else {
        return appDelegate.currentPollingPlace ? [watcherChecklist count] : 0;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Избирательные участки" : @"Наблюдение";
}

- (void) tableView: (UITableView *) tableView willDisplayCell: (UITableViewCell *) cell forRowAtIndexPath: (NSIndexPath *) indexPath {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    if ( indexPath.section == 1 && appDelegate.currentPollingPlace ) {
        NSArray *values = [watcherChecklist allValues];
        NSArray *sortedValues = [values sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"order" 
                                                                                                                             ascending: YES]]];
        NSDictionary *screenInfo = [sortedValues objectAtIndex: indexPath.row];
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSArray *checklistItems = [[appDelegate.currentPollingPlace checklistItems] allObjects];
        NSPredicate *sectionPredicate = [NSPredicate predicateWithFormat: @"SELF.sectionIndex == %d", indexPath.row];
        NSArray *sectionItems = [checklistItems filteredArrayUsingPredicate: sectionPredicate];
        
        cell.textLabel.text = [screenInfo objectForKey: @"title"];
        cell.detailTextLabel.text = [sectionItems count] ? [NSString stringWithFormat: @"Отмечено %d пунктов", [sectionItems count]] : @"Отметок нет";
    }
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    if ( indexPath.section == 0 ) {
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
    } else {
        static NSString *cellId = @"sectionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
        
        if ( cell == nil ) {
            cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: cellId] autorelease];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
        
        return cell;
    }
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
    if ( indexPath.section == 0 ) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                        forEntity: @"PollingPlace" 
                                                   withParameters: nil];
        if ( indexPath.row < pollingPlaces.count ) {
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
    } else {
        NSArray *values = [watcherChecklist allValues];
        NSArray *sortedValues = [values sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"order" 
                                                                                                                             ascending: YES]]];
        WatcherChecklistSectionController *sectionController = [[WatcherChecklistSectionController alloc] initWithStyle: UITableViewStyleGrouped];
        sectionController.sectionData = [sortedValues objectAtIndex: indexPath.row];
        sectionController.sectionIndex = indexPath.row;
        
        [self.navigationController pushViewController: sectionController animated: YES];
        [sectionController release];
    }
}

#pragma mark - Polling place controller delegate

-(void)watcherPollingPlaceController:(WatcherPollingPlaceController *)controller didSavePollingPlace:(PollingPlace *)pollinngPlace {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSError *error = nil;
    [appDelegate.managedObjectContext save: &error];
    
    if ( error )
        NSLog(@"error saving polling place info: %@", error.description);
    else
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



@end
