//
//  AppDelegate.m
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "WatcherChecklistController.h"
#import "WatcherChecklistSectionController.h"
#import "WatcherGuideController.h"
#import "WatcherSettingsController.h"
#import "WatcherReportController.h"
#import "WatcherSOSController.h"
#import "WatcherDataManager.h"
#import "PollingPlace.h"
#import "WatcherProfile.h"
#import "NSObject+SBJSON.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize locationManager = _locationManager;
@synthesize currentLocation = _currentLocation;
@synthesize dataManager = _dataManager;
@synthesize facebook = _facebook;
@synthesize watcherProfile = _watcherProfile;

- (void)dealloc
{
    [_window release];
    [_tabBarController release];
    [_currentLocation release];
    [_dataManager release];
    [_facebook release];
    [_watcherProfile release];
    
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // TestFlight
    [TestFlight takeOff: @"3e01d5e6faba63f16c5fa20704571f7a_NjI1NTIyMDEyLTAyLTE0IDE1OjA5OjIxLjE3NzczMw"];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    // location manager
	_locationManager = [[CLLocationManager alloc] init];
	[_locationManager setDelegate: self];
	[_locationManager setDesiredAccuracy: kCLLocationAccuracyHundredMeters];
	[_locationManager setDistanceFilter: 1000];
    
    // UI Init
    UIViewController *checklistController   = [[[WatcherChecklistController alloc] initWithNibName:@"WatcherChecklistController" 
                                                                                            bundle:nil] autorelease];
    
    UIViewController *guideController       = [[[WatcherGuideController alloc] initWithNibName:@"WatcherGuideController" 
                                                                                        bundle:nil] autorelease];
    
    UIViewController *profileController     = [[[WatcherSettingsController alloc] initWithNibName: @"WatcherSettingsController" 
                                                                                           bundle: nil] autorelease];
    
    UIViewController *reportController      = [[[WatcherReportController alloc] initWithNibName: @"WatcherReportController" 
                                                                                         bundle: nil] autorelease];
    
    UIViewController *sosController         = [[[WatcherSOSController alloc] initWithNibName: @"WatcherSOSController" 
                                                                                      bundle: nil] autorelease];
    
    UINavigationController *navigationController1 = [[[UINavigationController alloc] initWithRootViewController: profileController] autorelease];
    UINavigationController *navigationController2 = [[[UINavigationController alloc] initWithRootViewController: checklistController] autorelease];
    UINavigationController *navigationController3 = [[[UINavigationController alloc] initWithRootViewController: reportController] autorelease];
    UINavigationController *navigationController4 = [[[UINavigationController alloc] initWithRootViewController: guideController] autorelease];
    UINavigationController *navigationController5 = [[[UINavigationController alloc] initWithRootViewController: sosController] autorelease];

    // reload summary data on navigation
    navigationController2.delegate = self;
    navigationController3.delegate = self;

    // setup bar styles
    navigationController1.navigationBar.barStyle = UIBarStyleBlackOpaque;
    navigationController2.navigationBar.barStyle = UIBarStyleBlackOpaque;
    navigationController3.navigationBar.barStyle = UIBarStyleBlackOpaque;
    navigationController4.navigationBar.barStyle = UIBarStyleBlackOpaque;
    navigationController5.navigationBar.barStyle = UIBarStyleBlackOpaque;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    
    // init tab bar controller
    self.tabBarController = [[[UITabBarController alloc] init] autorelease];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects: navigationController1, 
                                             navigationController2, navigationController3, 
                                             navigationController4, navigationController5, nil];
    
    
    // upload data manager
    _dataManager = [[WatcherDataManager alloc] init];
    
    // initialize profile
    NSArray *profileResults = [self executeFetchRequest: @"findProfile" 
                                              forEntity: @"WatcherProfile" 
                                         withParameters: [NSDictionary dictionary]];
    if ( profileResults.count ) {
        _watcherProfile = [[profileResults lastObject] retain];
    } else {
        _watcherProfile = [[NSEntityDescription insertNewObjectForEntityForName: @"WatcherProfile" 
                                                         inManagedObjectContext: self.managedObjectContext] retain];
        
        NSError *error = nil;
        [_managedObjectContext save: &error];
        if ( error ) 
            NSLog(@"error initializing profile: %@", error.description );
    }
    
    // facebook
    _facebook = [[Facebook alloc] initWithAppId: @"308722072498316" andDelegate:self];
    _facebook.accessToken = _watcherProfile.fbAccessToken;
    _facebook.expirationDate = _watcherProfile.fbAccessExpires;
    
    if ( [_facebook isSessionValid] )
        [_facebook requestWithGraphPath: @"me" andDelegate: self];
    
    // twitter
    
    // complete initialization
    self.tabBarController.delegate = self;
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    [TestFlight passCheckpoint: @"Application Init"];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    [self.dataManager stopProcessing];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    [self.locationManager startUpdatingLocation];
    [self.dataManager startProcessing];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

#pragma mark -
#pragma mark Tab bar controller delegate

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    
    [self updateSynchronizationStatus];
}

#pragma mark -
#pragma mark Navigation controller delegate

-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    [self updateSynchronizationStatus];
}

#pragma mark -
#pragma mark Synchronization status

-(void)updateSynchronizationStatus {
    UIViewController *viewController = self.tabBarController.selectedViewController;
    
    if ( [viewController isKindOfClass: [UINavigationController class]] ) {
        UINavigationController *navController = (UINavigationController *) viewController;
        
        if ( self.dataManager.active ) {
            if ( ! [navController.topViewController.navigationItem.rightBarButtonItem.customView isKindOfClass: [UIActivityIndicatorView class]] ) {
                UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
                UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView: activityIndicator];
                navController.topViewController.navigationItem.rightBarButtonItem = barButtonItem;
                [activityIndicator startAnimating];
                
                [activityIndicator release];
                [barButtonItem release];
            }
        } else {
            UIImage *image = nil;
            
            if ( self.dataManager.hasErrors )
                image = [UIImage imageNamed: @"sync_errors_icon"];
            else
                image = [UIImage imageNamed: @"sync_ok_icon"];
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage: image];
            UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView: imageView];
            
            navController.topViewController.navigationItem.rightBarButtonItem = barButtonItem;
            
            [imageView release];
            [barButtonItem release];
        }
    }
}

- (void) showNetworkActivity {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void) hideNetworkActivity {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark -
#pragma mark Location manager

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    self.currentLocation = newLocation;
    
    [manager stopUpdatingHeading];
    [manager stopUpdatingLocation];
}

#pragma mark -
#pragma mark Core Data stack

- (NSManagedObjectContext *) managedObjectContext {
    if ( _managedObjectContext != nil ) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if ( coordinator != nil ) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return _managedObjectContext;
}

- (NSManagedObjectModel *) managedObjectModel {
    if ( _managedObjectModel != nil ) {
        return _managedObjectModel;
    }
    
    _managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: nil] retain];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if ( _persistentStoreCoordinator != nil ) {
        return _persistentStoreCoordinator;
    }
    
    NSArray*  paths         = NSSearchPathForDirectoriesInDomains ( NSCachesDirectory, NSUserDomainMask, YES );
    NSString* cachePath     = [paths lastObject];
    NSURL* storeUrl         = [NSURL fileURLWithPath: [cachePath stringByAppendingPathComponent: @"ElectionsWatcher.sqlite"]];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    NSDictionary* storeOptions  = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                  [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if ( ![_persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
                                                   configuration: nil 
                                                             URL: storeUrl 
                                                         options: storeOptions 
                                                           error: &error] ) {
        
        /*Error for store creation should be handled in here*/
        NSLog ( @"Unresolved error %@, %@", error, [error userInfo] );
        exit ( -1 );
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Core Data helpers

- (NSArray *) executeFetchRequest: (NSString *) request forEntity: (NSString *) entity withParameters: (NSDictionary *) params {
    @synchronized ( self ) {
        NSManagedObjectContext *context = [self managedObjectContext];
        NSManagedObjectModel *model     = [self managedObjectModel];
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName: entity inManagedObjectContext: context];
        
        NSFetchRequest *fetchRequest    = [model fetchRequestFromTemplateWithName: request substitutionVariables: params];
        
        [fetchRequest setEntity: entityDesc];
        
        NSError *error   = nil;
        NSArray *results = [context executeFetchRequest: fetchRequest error: &error];
        
        if ( error )
            NSLog(@"Core Data Error: %@", error.description);

        return results;
    }
}

- (NSArray *) executeFetchRequest: (NSString *) request forEntity: (NSString *) entity withContext: (NSManagedObjectContext* ) context withParameters: (NSDictionary *) params {
    @synchronized ( self ) {
        NSManagedObjectModel *model     = [self managedObjectModel];
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName: entity inManagedObjectContext: context];
        NSFetchRequest *fetchRequest    = [model fetchRequestFromTemplateWithName: request substitutionVariables: params];
        
        [fetchRequest setEntity: entityDesc];
        
        NSError *error   = nil;
        NSArray *results = [context executeFetchRequest: fetchRequest error: &error];
        
        if ( error )
            NSLog(@"Core Data Error: %@", error.description);
        
        return results;
    }
}

#pragma mark -
#pragma mark Facebook support

// Pre 4.2 support
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [_facebook handleOpenURL:url]; 
}

// For 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [_facebook handleOpenURL:url]; 
}

-(void)fbDidLogin {
    _watcherProfile.fbAccessToken = _facebook.accessToken;
    _watcherProfile.fbAccessExpires = _facebook.expirationDate;
    
        [_facebook requestWithGraphPath: @"me" andDelegate: self];
    
    NSError *error = nil;
    [_managedObjectContext save: &error];
    if ( error )
        NSLog(@"Core Data Error: %@", error.description);
    
    
}

-(void)fbDidLogout {
    _watcherProfile.fbAccessToken = nil;
    _watcherProfile.fbAccessExpires = nil;
    
    NSError *error = nil;
    [_managedObjectContext save: &error];
    if ( error )
        NSLog(@"Core Data Error: %@", error.description);
}

-(void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
    _watcherProfile.fbAccessToken = accessToken;
    _watcherProfile.fbAccessExpires = expiresAt;
    
    NSError *error = nil;
    [_managedObjectContext save: &error];
    if ( error )
        NSLog(@"Core Data Error: %@", error.description);
}

-(void)fbDidNotLogin:(BOOL)cancelled {
    _watcherProfile.fbAccessToken = nil;
    _watcherProfile.fbAccessExpires = nil;
    
    NSError *error = nil;
    [_managedObjectContext save: &error];
    if ( error )
        NSLog(@"Core Data Error: %@", error.description);
}

-(void)fbSessionInvalidated {
    _watcherProfile.fbAccessToken = nil;
    _watcherProfile.fbAccessExpires = nil;
    
    NSError *error = nil;
    [_managedObjectContext save: &error];
    if ( error )
        NSLog(@"Core Data Error: %@", error.description);
}

-(void)request:(FBRequest *)request didLoad:(id)result {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    _watcherProfile.fbNickname = [result objectForKey: @"username"];

    if ( ! _watcherProfile.email.length )
        _watcherProfile.email = [result objectForKey: @"email"];
    
    if ( ! _watcherProfile.firstName.length )
        _watcherProfile.firstName = [result objectForKey: @"first_name"];
    
    if ( ! _watcherProfile.lastName.length )
        _watcherProfile.lastName = [result objectForKey: @"last_name"];
    
    NSError *error = nil;
    [_managedObjectContext save: &error];
    if ( error )
        NSLog(@"Core Data Error: %@", error.description);
    
    [TestFlight passCheckpoint: @"Facebook login"];

}

-(void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(void)requestLoading:(FBRequest *)request {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

#pragma mark - Twitter

- (void) setupTwitterAccountForUsername: (NSString *) username withCompletionHandler: (void (^)(void)) completionHandler {
    if ( username.length ) {
        ACAccountStore *store = [[ACAccountStore alloc] init];
        ACAccountType *twitterAccountType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        NSArray *twitterAccounts = [store accountsWithAccountType: twitterAccountType];
        ACAccount *twitterAccount = [[twitterAccounts filteredArrayUsingPredicate: 
                                      [NSPredicate predicateWithFormat: @"SELF.username LIKE %@", username]] lastObject];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        NSURL *url = [NSURL URLWithString: @"https://api.twitter.com/1/account/verify_credentials.json"];
        TWRequest *twRequest = [[TWRequest alloc] initWithURL: url parameters: nil requestMethod: TWRequestMethodGET];
        [twRequest setAccount: [[twitterAccount retain] autorelease]];
        [twRequest performRequestWithHandler: ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            if ( responseData ) {
                NSString *jsonString = [[NSString alloc] initWithData: responseData encoding: NSUTF8StringEncoding];
                NSDictionary *twProfile = [jsonString JSONValue];
                [jsonString release];
                
                _watcherProfile.twNickname = [twProfile objectForKey: @"screen_name"];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                completionHandler();
                
                NSError *error = nil;
                [_managedObjectContext save: &error];
                if ( error )
                    NSLog(@"Core Data Error: %@", error.description);
                
                [TestFlight passCheckpoint: @"Twitter login"];
            } else {
                NSLog(@"twitter request error: %@", error);
            }
        }];
        
        [twRequest release];
        [store release];
    } else {
        _watcherProfile.twNickname = nil;
        _watcherProfile.twAccessExpires = nil;
        _watcherProfile.twAccessToken = nil;
        
        NSError *error = nil;
        [_managedObjectContext save: &error];
        if ( error )
            NSLog(@"Core Data Error: %@", error.description);
        
        completionHandler();
    }
}


@end
