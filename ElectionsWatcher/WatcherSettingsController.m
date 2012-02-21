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
#import "WatcherTwitterSetupController.h"
#import "WatcherProfile.h"
#import "AppDelegate.h"
#import "WatcherDataManager.h"

@implementation WatcherSettingsController

@synthesize settings = _settings;
@synthesize HUD = _HUD;

static NSString *settingsSections[] = { @"auth_selection", @"observer_status", @"observer_info" };

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
    [_settings release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *defaultPath = nil;
    if ( [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString: @"."] objectAtIndex: 0] intValue] >= 5 )
        defaultPath = [[NSBundle mainBundle] pathForResource: @"WatcherSettings" 
                                                      ofType: @"plist"];
    else
        defaultPath = [[NSBundle mainBundle] pathForResource: @"WatcherSettingsPre50" 
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
    
    [appDelegate.watcherProfile addObserver: self 
                                 forKeyPath: @"twNickname" 
                                    options: NSKeyValueObservingOptionNew 
                                    context: nil];
    
    [appDelegate.watcherProfile addObserver: self 
                                 forKeyPath: @"userId" 
                                    options: NSKeyValueObservingOptionNew 
                                    context: nil];
    
    [self.tableView reloadData];
 
    if ( ! appDelegate.watcherProfile.userId.length )
        [appDelegate.dataManager performSelector: @selector(registerCurrentDevice) withObject: nil afterDelay: 10];
//        [appDelegate.dataManager registerCurrentDevice];
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
        return 42;
    } else if ( indexPath.section == 1 ) {
        return 42;
    } else {
        NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
        NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
        NSString *itemTitle = [itemInfo objectForKey: @"title"];
        
        CGSize labelSize = [itemTitle sizeWithFont: [UIFont boldSystemFontOfSize: 13] 
                                 constrainedToSize: CGSizeMake(280, 120) 
                                     lineBreakMode: UILineBreakModeWordWrap];
        
        return labelSize.height + 70;
    }
}

- (void) tableView: (UITableView *) tableView willDisplayCell: (UITableViewCell *) cell forRowAtIndexPath: (NSIndexPath *) indexPath {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    
    if ( indexPath.section == 0 ) {
        cell.textLabel.text = [itemInfo objectForKey: @"title"];
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        if ( [@"manual" isEqualToString: [itemInfo objectForKey: @"name"]] ) {
            if ( appDelegate.watcherProfile.firstName.length )
                cell.detailTextLabel.text = [NSString stringWithFormat: @"%@ %@", 
                                             appDelegate.watcherProfile.firstName, appDelegate.watcherProfile.lastName];
            
            cell.imageView.image = [UIImage imageNamed: @"manualuser_icon"];
        }
        
        if ( [@"facebook" isEqualToString: [itemInfo objectForKey: @"name"]] ) {
            if ( appDelegate.watcherProfile.fbNickname.length )
                cell.detailTextLabel.text = appDelegate.watcherProfile.fbNickname;
            else
                cell.detailTextLabel.text = nil;
            
            cell.imageView.image = [UIImage imageNamed: @"facebook_icon"];
        }
        
        if ( [@"twitter" isEqualToString: [itemInfo objectForKey: @"name"]] ) {
            if ( appDelegate.watcherProfile.twNickname.length ) 
                cell.detailTextLabel.text = appDelegate.watcherProfile.twNickname;
            else
                cell.detailTextLabel.text = nil;
            
            cell.imageView.image = [UIImage imageNamed: @"twitter_icon"];
        }
    } else if ( indexPath.section == 1 ) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        if ( appDelegate.watcherProfile.userId.length == 0 ) {
            cell.textLabel.text = @"Регистрация на сервере";
            cell.accessoryType = UITableViewCellAccessoryNone;
            UIActivityIndicatorView *iv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
            cell.accessoryView = iv;
            [iv startAnimating];
            [iv release];
        } else {
            cell.textLabel.text = @"Зарегистрирован";
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.accessoryView = nil;
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
    } else if ( indexPath.section == 1 ) {
        if ( cell == nil )
            cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleValue1 reuseIdentifier: cellId] autorelease];
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
        
        if ( [@"twitter" isEqualToString: [itemInfo objectForKey: @"name"]] ) {
            ACAccountStore *store = [[ACAccountStore alloc] init];
            ACAccountType *twitterAccountType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

            _HUD = [[MBProgressHUD alloc] initWithWindow: [UIApplication sharedApplication].keyWindow];
            _HUD.delegate = self;
            [[UIApplication sharedApplication].keyWindow addSubview: _HUD];
            [_HUD show: YES];
            
            [store requestAccessToAccountsWithType: twitterAccountType 
                             withCompletionHandler: ^(BOOL granted, NSError *error) {
                                 if ( granted ) {
                                     
                                     WatcherTwitterSetupController *twitterSetupController = [[WatcherTwitterSetupController alloc] initWithNibName: @"WatcherTwitterSetupController" bundle: nil];
                                     twitterSetupController.delegate = self;
                                     
                                     UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController: twitterSetupController];
                                     nc.navigationBar.tintColor = [UIColor blackColor];
                                     [self presentViewController: nc animated: YES completion: ^(void){ [_HUD hide: YES]; }];
                                     [twitterSetupController release];
                                     [nc release];
                                 } else {
                                     NSLog(@"user rejected access to twitter accounts");
                                 }
                             }];
            [store release];
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

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    
    if ( [@"twitter" isEqualToString: [itemInfo objectForKey: @"name"]] || [@"facebook" isEqualToString: [itemInfo objectForKey: @"name"]] )
        return @"Выйти";
    else
        return nil;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
    NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    return [@"twitter" isEqualToString: [itemInfo objectForKey: @"name"]] || [@"facebook" isEqualToString: [itemInfo objectForKey: @"name"]];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( editingStyle == UITableViewCellEditingStyleDelete ) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        NSDictionary *sectionInfo = [self.settings objectForKey: settingsSections[indexPath.section]];
        NSDictionary *itemInfo = [[sectionInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
        
        if ( [@"twitter" isEqualToString: [itemInfo objectForKey: @"name"]] ) {
            appDelegate.watcherProfile.twNickname = nil;
            appDelegate.watcherProfile.twAccessExpires = nil;
            appDelegate.watcherProfile.twAccessToken = nil;
        }
        
        if ( [@"facebook" isEqualToString: [itemInfo objectForKey: @"name"]] ) {
            [appDelegate.facebook logout];
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

#pragma mark - Twitter setup delegate

-(void)watcherTwitterSetupController:(WatcherTwitterSetupController *)controller didSelectUsername:(NSString *)username {
    _HUD = [[MBProgressHUD alloc] initWithWindow: [UIApplication sharedApplication].keyWindow];
    _HUD.delegate = self;
    [[UIApplication sharedApplication].keyWindow addSubview: _HUD];
    [_HUD show: YES];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate setupTwitterAccountForUsername: username withCompletionHandler: ^(void){
        [self dismissModalViewControllerAnimated: YES];
        [_HUD hide: YES];
    }];
}

-(void)watcherTwitterSetupControllerDidCancel:(WatcherTwitterSetupController *)controller {
    [self dismissModalViewControllerAnimated: YES];
}

#pragma mark - Key/value observation 

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context {
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ( object == appDelegate.watcherProfile )
        [self.tableView reloadData];
}

#pragma mark - HUD

-(void)hudWasHidden {
    [_HUD release]; _HUD = nil;
}


@end
