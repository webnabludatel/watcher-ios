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

@implementation AppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize locationManager = _locationManager;
@synthesize currentLocation = _currentLocation;
@synthesize currentPollingPlace = _currentPollingPlace;
@synthesize dataManager = _dataManager;

- (void)dealloc
{
    [_window release];
    [_tabBarController release];
    [_currentLocation release];
    [_dataManager release];
    
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    // location manager
	_locationManager = [[CLLocationManager alloc] init];
	[_locationManager setDelegate: self];
	[_locationManager setDesiredAccuracy: kCLLocationAccuracyHundredMeters];
	[_locationManager setDistanceFilter: 1000];
    
    // last active polling place
    NSArray *paths    = NSSearchPathForDirectoriesInDomains ( NSCachesDirectory, NSUserDomainMask, YES );
    NSString *path    = [[paths lastObject] stringByAppendingPathComponent: @"current_number.txt"];
    NSString *number  = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: nil];
    if ( number ) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: number, @"NUMBER", nil];
        NSArray *results  = [self executeFetchRequest: @"findPollingPlace" forEntity: @"PollingPlace" withParameters: params];
        _currentPollingPlace = [[results lastObject] retain];
    }
    
    
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
    
    
    // complete initialization
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    // TestFlight
    [TestFlight takeOff: @"3e01d5e6faba63f16c5fa20704571f7a_NjI1NTIyMDEyLTAyLTE0IDE1OjA5OjIxLjE3NzczMw"];
    
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
#pragma mark Polling place accessor override

-(PollingPlace *)currentPollingPlace {
    return _currentPollingPlace;
}

-(void)setCurrentPollingPlace:(PollingPlace *) aCurrentPollingPlace {
    [_currentPollingPlace release]; _currentPollingPlace = nil;
    _currentPollingPlace = [aCurrentPollingPlace retain];
    
    NSError *error    = nil;
    NSArray *paths    = NSSearchPathForDirectoriesInDomains ( NSCachesDirectory, NSUserDomainMask, YES );
    NSString *path    = [[paths lastObject] stringByAppendingPathComponent: @"current_number.txt"];
    [[NSString stringWithFormat: @"%@", _currentPollingPlace.number] writeToFile: path
                                                                     atomically: YES 
                                                                       encoding: NSUTF8StringEncoding 
                                                                          error: &error];
    
    if ( error ) 
        NSLog(@"error saving current polling place: %@", error.description);
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

@end
