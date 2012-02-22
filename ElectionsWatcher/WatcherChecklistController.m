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
#import "WatcherProfile.h"

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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.navigationItem.title = appDelegate.watcherProfile.currentPollingPlace ? 
    appDelegate.watcherProfile.currentPollingPlace.titleString : @"Наблюдение";
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

#pragma mark - Helper methods

- (NSArray *) sortedAndFilteredSections {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSArray *sortDescriptors = [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"order" ascending: YES]];
    NSArray *sortedSections  = [[watcherChecklist allValues] sortedArrayUsingDescriptors: sortDescriptors];
    
    NSPredicate *pollingPlaceTypePredicate = [NSPredicate predicateWithFormat: @"ANY SELF.district_types LIKE %@", 
                                              appDelegate.watcherProfile.currentPollingPlace.type];
    
    return [sortedSections filteredArrayUsingPredicate: pollingPlaceTypePredicate];
}

#pragma mark - UITableView

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    return appDelegate.watcherProfile.currentPollingPlace ? 2 : 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ( section == 0 ) {
        NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                        forEntity: @"PollingPlace" 
                                                   withParameters: nil];
        return [pollingPlaces count]+1;
    } else {
        return [[self sortedAndFilteredSections] count];
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Избирательные участки" : @"Наблюдение";
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 ? 40 : 60;
}

- (void) tableView: (UITableView *) tableView willDisplayCell: (UITableViewCell *) cell forRowAtIndexPath: (NSIndexPath *) indexPath {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    if ( indexPath.section == 1 && appDelegate.watcherProfile.currentPollingPlace ) {
        
        NSDictionary *sectionInfo = [[self sortedAndFilteredSections] objectAtIndex: indexPath.row];
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSArray *checklistItems = [[appDelegate.watcherProfile.currentPollingPlace checklistItems] allObjects];
        NSPredicate *sectionPredicate = [NSPredicate predicateWithFormat: @"SELF.sectionName LIKE %@", [sectionInfo objectForKey: @"name"]];
        NSArray *sectionItems = [checklistItems filteredArrayUsingPredicate: sectionPredicate];
        
        cell.textLabel.text = [sectionInfo objectForKey: @"title"];
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
            cell.textLabel.text = pollingPlace.titleString;
            cell.textLabel.textAlignment = UITextAlignmentLeft;
            
            if ( pollingPlace == appDelegate.watcherProfile.currentPollingPlace ) 
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
            
        } else {
            cell.textLabel.text = @"Добавить участок...";
            cell.textLabel.textAlignment = UITextAlignmentLeft;
        }
        
        return cell;
    } else {
        static NSString *cellId = @"sectionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: cellId];
        
        if ( cell == nil ) {
            cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: cellId] autorelease];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
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
            appDelegate.watcherProfile.currentPollingPlace = [pollingPlaces objectAtIndex: indexPath.row];
            NSError *error = nil;
            [appDelegate.managedObjectContext save: &error];
            if ( error ) 
                NSLog(@"error saving current polling place: %@", error.description);
            [self.tableView reloadData];
            
            // update title
            self.navigationItem.title = appDelegate.watcherProfile.currentPollingPlace ?
            appDelegate.watcherProfile.currentPollingPlace.titleString : @"Наблюдение";
        } else {
            WatcherPollingPlaceController *pollingPlaceController = [[WatcherPollingPlaceController alloc] initWithNibName: @"WatcherPollingPlaceController" bundle: nil];
            pollingPlaceController.pollingPlaceControllerDelegate = self;
            pollingPlaceController.pollingPlace = [NSEntityDescription insertNewObjectForEntityForName: @"PollingPlace" 
                                                                                inManagedObjectContext: [appDelegate managedObjectContext]];
            
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController: pollingPlaceController];
            nc.navigationBar.tintColor = [UIColor blackColor];
            nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentModalViewController: nc animated: YES];
            [pollingPlaceController release];
            [nc release];
        }
    } else {
        WatcherChecklistSectionController *sectionController = [[WatcherChecklistSectionController alloc] initWithStyle: UITableViewStyleGrouped];
        sectionController.sectionData = [[self sortedAndFilteredSections] objectAtIndex: indexPath.row];
        
        [self.navigationController pushViewController: sectionController animated: YES];
        [sectionController release];
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                    forEntity: @"PollingPlace" 
                                               withParameters: nil];
    
    return indexPath.section == 0 && indexPath.row < pollingPlaces.count;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( editingStyle == UITableViewCellEditingStyleDelete ) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                        forEntity: @"PollingPlace" 
                                                   withParameters: nil];
        PollingPlace *pollingPlaceToRemove = [pollingPlaces objectAtIndex: indexPath.row];
        
        if ( pollingPlaceToRemove == appDelegate.watcherProfile.currentPollingPlace ) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Ошибка" 
                                                                message: @"Нельзя удалить активный избирательный участок" 
                                                               delegate: nil 
                                                      cancelButtonTitle: @"OK" 
                                                      otherButtonTitles: nil];
            [alertView show];
            [alertView release];
        } else {
            [appDelegate.managedObjectContext deleteObject: pollingPlaceToRemove];
            
            NSError *error = nil;
            [appDelegate.managedObjectContext save: &error];
            if ( error ) 
                NSLog(@"error removing polling place: %@", error.description);
            
            [self.tableView reloadData];
        }
    }
}

#pragma mark - Polling place controller delegate

-(void)watcherPollingPlaceController:(WatcherPollingPlaceController *)controller didSavePollingPlace:(PollingPlace *)pollinngPlace {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    appDelegate.watcherProfile.currentPollingPlace = controller.pollingPlace;

    NSError *error = nil;
    [appDelegate.managedObjectContext save: &error];
    
    if ( error )
        NSLog(@"error saving polling place info: %@", error.description);
    
    
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
