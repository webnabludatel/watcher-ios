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
@synthesize activePollingPlace;

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
    [activePollingPlace release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    [self loadSettings];
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

#pragma mark - Settings management

- (void) loadSettings {
    NSFileManager *fm   = [NSFileManager defaultManager];
    NSArray*  paths     = NSSearchPathForDirectoriesInDomains ( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString* settingsPath = [[paths lastObject] stringByAppendingPathComponent: @"WatcherSettings.plist"];
    
    NSError *error = nil;
    
    if ( [fm fileExistsAtPath: settingsPath] ) {
        self.settings = [NSDictionary dictionaryWithContentsOfFile: settingsPath];
        if ( error ) 
            NSLog ( @"error opening settings: %@", error.description );
        
    } else {
        NSString *defaultPath = [[NSBundle mainBundle] pathForResource: @"WatcherSettings" 
                                                                ofType: @"plist"];
        
        self.settings = [NSDictionary dictionaryWithContentsOfFile: defaultPath];
        
        if ( error ) 
            NSLog ( @"error opening settings: %@", error.description );
        
        [fm copyItemAtPath: defaultPath toPath: settingsPath error: &error];
        
        if ( error ) 
            NSLog ( @"error copying settings to docs path: %@", error.description );
    }
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.activePollingPlace = appDelegate.currentPollingPlace;
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewController

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[section]];
    return [sectionInfo objectForKey: @"title"];
}

/*
-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ( section == [[self.settings allKeys] count] - 1 ) {
        UIView *footerView      = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, tableView.bounds.size.width, 60)] autorelease];
        UIButton *saveButton    = [UIButton buttonWithType: UIButtonTypeRoundedRect];
        UIButton *resetButton   = [UIButton buttonWithType: UIButtonTypeRoundedRect];
        
        CGRect saveButtonFrame, resetButtonFrame;
        CGRectDivide(footerView.bounds, &saveButtonFrame, &resetButtonFrame, footerView.bounds.size.width/2, CGRectMinXEdge);
        
        saveButton.frame = CGRectInset(saveButtonFrame, 10, 10);
        resetButton.frame = CGRectInset(resetButtonFrame, 10, 10);
        
        [saveButton setTitle: @"Сохранить" forState: UIControlStateNormal];
        [resetButton setTitle: @"Сменить участок" forState: UIControlStateNormal];
        
        [footerView addSubview: saveButton];
        [footerView addSubview: resetButton];
        
        return footerView;
    } else {
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return ( section == [[self.settings allKeys] count] - 1 ) ? 60 : 0;
}
*/

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
            cell.textLabel.text = [NSString stringWithFormat: @"%@ № %d", pollingPlace.type, [pollingPlace.number intValue]];
            cell.textLabel.textAlignment = UITextAlignmentLeft;
            
            if ( pollingPlace == self.activePollingPlace ) 
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
            NSArray *pollingPlaces = [appDelegate executeFetchRequest: @"listPollingPlaces" 
                                                            forEntity: @"PollingPlace" 
                                                       withParameters: nil];
            self.activePollingPlace = [pollingPlaces objectAtIndex: indexPath.row];
            appDelegate.currentPollingPlace = self.activePollingPlace;
            [self.tableView reloadData];
        } else {
            // create new polling place
            self.activePollingPlace = [NSEntityDescription insertNewObjectForEntityForName: @"PollingPlace" 
                                                                    inManagedObjectContext: [appDelegate managedObjectContext]];
            [appDelegate.managedObjectContext save: nil];
            
            WatcherPollingPlaceController *pollingPlaceController = [[WatcherPollingPlaceController alloc] initWithNibName: @"WatcherPollingPlaceController" bundle: nil];
            pollingPlaceController.saveDelegate = self;
            pollingPlaceController.pollingPlace = self.activePollingPlace;
            
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController: pollingPlaceController];
            nc.navigationBar.tintColor = [UIColor blackColor];
            [self presentModalViewController: nc animated: YES];
            [pollingPlaceController release];
            [nc release];
        }
    }
    
}

#pragma mark - Own event handlers

- (void) selectActivePollingPlace: (id) sender {
    UIButton *button = sender;
    [button setSelected: ! button.selected];
}

- (void) didFinishEditingPollingPlace: (id) sender {
    if ( self.activePollingPlace.type.length && self.activePollingPlace.number.intValue ) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        [appDelegate.managedObjectContext save: nil];
        appDelegate.currentPollingPlace = self.activePollingPlace;
        [self dismissModalViewControllerAnimated: YES];
        [self.tableView reloadData];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Ошибка" 
                                                            message: @"Не заполнено обязательное поле" 
                                                           delegate: nil 
                                                  cancelButtonTitle: @"OK" 
                                                  otherButtonTitles: nil];
        
        [alertView show];
        [alertView release];
    }
}

- (void) didSaveAttributeItem:(ChecklistItem *)item {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.managedObjectContext save: nil];
}

@end
