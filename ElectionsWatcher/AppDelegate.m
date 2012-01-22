//
//  AppDelegate.m
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "WatcherChecklistController.h"
#import "WatcherGuideController.h"
#import "WatcherSettingsController.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;
@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;
@synthesize locationManager;

- (void)dealloc
{
    [_window release];
    [_tabBarController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    // location manager
	locationManager = [[CLLocationManager alloc] init];
	[locationManager setDelegate: self];
	[locationManager setDesiredAccuracy: kCLLocationAccuracyHundredMeters];
	[locationManager setDistanceFilter: 1000];
    
    
    // UI Init
    UIViewController *viewController1 = [[[WatcherChecklistController alloc] initWithNibName:@"WatcherChecklistController" bundle:nil] autorelease];
    UIViewController *viewController2 = [[[WatcherGuideController alloc] initWithNibName:@"WatcherGuideController" bundle:nil] autorelease];
    UIViewController *viewController3 = [[[WatcherSettingsController alloc] initWithNibName: @"WatcherSettingsController" bundle: nil] autorelease];
    
    UINavigationController *navigationController1 = [[[UINavigationController alloc] initWithRootViewController: viewController1] autorelease];
    UINavigationController *navigationController2 = [[[UINavigationController alloc] initWithRootViewController: viewController2] autorelease];
    
    self.tabBarController = [[[UITabBarController alloc] init] autorelease];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects: navigationController1, navigationController2, viewController3, nil];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

#pragma mark -
#pragma mark Core Data stack

- (NSManagedObjectContext *) managedObjectContext {
    if ( managedObjectContext != nil ) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if ( coordinator != nil ) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}

- (NSManagedObjectModel *) managedObjectModel {
    if ( managedObjectModel != nil ) {
        return managedObjectModel;
    }
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: nil] retain];
    
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if ( persistentStoreCoordinator != nil ) {
        return persistentStoreCoordinator;
    }
    
    NSArray*  paths         = NSSearchPathForDirectoriesInDomains ( NSCachesDirectory, NSUserDomainMask, YES );
    NSString* cachePath     = [paths lastObject];
    NSURL* storeUrl         = [NSURL fileURLWithPath: [cachePath stringByAppendingPathComponent: @"ElectionsWatcher.sqlite"]];
    
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    NSDictionary* storeOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                  [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if ( ![persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
                                                   configuration: nil 
                                                             URL: storeUrl 
                                                         options: storeOptions 
                                                           error: &error] ) {
        
        /*Error for store creation should be handled in here*/
        NSLog ( @"Unresolved error %@, %@", error, [error userInfo] );
        exit ( -1 );
    }
    
    return persistentStoreCoordinator;
}

@end
