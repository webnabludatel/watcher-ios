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
#import <QuartzCore/QuartzCore.h>

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
@synthesize privateSettings = _privateSettings;
@synthesize sharedImagePicker = _sharedImagePicker;

- (void)dealloc
{
    [_window release];
    [_tabBarController release];
    [_currentLocation release];
    [_dataManager release];
    [_facebook release];
    [_watcherProfile release];
    [_privateSettings release];
    [_sharedImagePicker release];
    
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // AirBrake
    [ABNotifier startNotifierWithAPIKey: @"3c7330bf96978ade3a481e6473b06399"
	                    environmentName: ABNotifierAutomaticEnvironment
	                             useSSL: YES
	                           delegate: self];    
    
    // private settings and access keys
    _privateSettings = [[NSDictionary alloc] initWithContentsOfFile: 
                        [[NSBundle mainBundle] pathForResource: @"PrivateSettings" ofType: @"plist"]];
    
    // TestFlight
//    [TestFlight takeOff: [[_privateSettings objectForKey: @"testflight"] objectForKey: @"team_token"]];
    
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
    [UIApplication sharedApplication].statusBarHidden = NO;
    
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
    
    [self.dataManager startProcessing];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
//    [self.dataManager stopProcessing];
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [_sharedImagePicker release]; _sharedImagePicker = nil;
}

#pragma mark -
#pragma mark Tab bar controller delegate

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {

    if ( _dataManager.active )
        [self updateSynchronizationStatus];
    else
        [self removeSynchronizationStatus];
        
}

#pragma mark -
#pragma mark Navigation controller delegate

-(void)navigationController:(UINavigationController *)navigationController 
      didShowViewController:(UIViewController *)viewController 
                   animated:(BOOL)animated {
    
    if ( _dataManager.active )
        [self updateSynchronizationStatus];
    else
        [self removeSynchronizationStatus];
}

#pragma mark -
#pragma mark Synchronization status

-(void)removeSynchronizationStatus {
    UIViewController *viewController = self.tabBarController.selectedViewController;
    
    if ( [viewController isKindOfClass: [UINavigationController class]] ) {
        UINavigationController *navController = (UINavigationController *) viewController;
        navController.topViewController.navigationItem.rightBarButtonItem = nil;
    }
    
}
-(void)updateSynchronizationStatus {
    @synchronized ( self ) {
        UIViewController *viewController = self.tabBarController.selectedViewController;
        
        if ( [viewController isKindOfClass: [UINavigationController class]] ) {
            UINavigationController *navController = (UINavigationController *) viewController;
            
            if ( self.dataManager.active ) {
                if ( navController.topViewController.navigationItem.rightBarButtonItem.customView.tag != 666 ) {
                    UIImageView *imageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"sync_refresh"]];
                    imageView.tag = 666;

                    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView: imageView];
                    navController.topViewController.navigationItem.rightBarButtonItem = barButtonItem;

                    [barButtonItem release];
                    [imageView release];
                }
                
                UIView *barButtonItemView = navController.topViewController.navigationItem.rightBarButtonItem.customView;
                
                if ( ! [barButtonItemView.layer animationForKey: @"transform"] ) {
                    CAKeyframeAnimation *rotation = [CAKeyframeAnimation animation];
                    rotation.duration = 1.5f;
                    rotation.repeatCount = HUGE_VALF;
                    rotation.values = [NSArray arrayWithObjects:
                                       [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0f, 0.0f, 0.0f, 1.0f)],
                                       [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI/2, 0.0f, 0.0f, 1.0f)],
                                       [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f)],
                                       [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI*3/2, 0.0f, 0.0f, 1.0f)],
                                       [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI*2, 0.0f, 0.0f, 1.0f)], 
                                       nil];
                    
                    [barButtonItemView.layer addAnimation:rotation forKey:@"transform"];
                }
            } else {
                UIImage *image = nil;
                UIImageView *imageView = nil;
                
                if ( self.dataManager.hasErrors ) {
                    if ( navController.topViewController.navigationItem.rightBarButtonItem.customView.tag != 888 ) {
                        image = [UIImage imageNamed: @"sync_alert"];
                        imageView = [[UIImageView alloc] initWithImage: image];
                        imageView.tag = 888;
                    }
                } else {
                    if ( navController.topViewController.navigationItem.rightBarButtonItem.customView.tag != 999 ) {
                        image = [UIImage imageNamed: @"sync_success"];
                        imageView = [[UIImageView alloc] initWithImage: image];
                        imageView.tag = 999;
                    }
                }

                if ( navController.topViewController.navigationItem.rightBarButtonItem.customView.tag != imageView.tag ) {
                    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView: imageView];
                    navController.topViewController.navigationItem.rightBarButtonItem = barButtonItem;
                    [barButtonItem release];
                    
                    [self performSelector: @selector(fadeStatusIndicator:) withObject: imageView afterDelay: 1];
                }
                
                [imageView release];
            }
        }
    }
}

- (void) fadeStatusIndicator: (UIView *) indicatorView {
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionFade;
    transition.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut];
    transition.duration = 2.0f;
    
    [indicatorView.layer addAnimation: transition forKey: @"hidden"];
    [indicatorView setHidden: YES];
}


#pragma mark -
#pragma mark Location manager

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    self.currentLocation = newLocation;
    
    [manager stopUpdatingHeading];
    [manager stopUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    UINavigationController *currentNc = (UINavigationController *) self.tabBarController.selectedViewController;
    
    if ( [currentNc.visibleViewController isKindOfClass: [WatcherSettingsController class]] )
        [[(WatcherSettingsController *) currentNc.visibleViewController tableView] reloadData];
}

#pragma mark -
#pragma mark Core Data stack

- (void) mergeContextChanges: (NSNotification *) notification {
    [_dataManager.managedObjectContext performSelector: @selector(mergeChangesFromContextDidSaveNotification:) 
                                              onThread: _dataManager.dataManagerThread 
                                            withObject: notification 
                                         waitUntilDone: NO];
}

- (void) saveManagedObject: (NSManagedObject *) managedObject {
    if ( [NSThread currentThread] != [NSThread mainThread] )
        @throw [NSException exceptionWithName: NSInternalInconsistencyException 
                                       reason: @"this method should be called only on main thread" 
                                     userInfo: nil];
    
    @synchronized ( _managedObjectContext ) {
        NSError *error = nil;
        //        if ( ! managedObject.isDeleted )
        [_managedObjectContext refreshObject: managedObject mergeChanges: YES];
        [_managedObjectContext save: &error];
        
        if ( error )
            NSLog(@"error saving managed object %@: %@", managedObject.objectID, error.description);
    }
}

- (NSManagedObjectContext *) managedObjectContext {
    if ( _managedObjectContext != nil ) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if ( coordinator != nil ) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];

        [[NSNotificationCenter defaultCenter] addObserver: self 
                                                 selector: @selector(mergeContextChanges:) 
                                                     name: NSManagedObjectContextDidSaveNotification 
                                                   object: _managedObjectContext];

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
    _watcherProfile.fbNickname = nil;
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
    _watcherProfile.fbNickname = nil;
    _watcherProfile.fbAccessToken = nil;
    _watcherProfile.fbAccessExpires = nil;
    
    NSError *error = nil;
    [_managedObjectContext save: &error];
    if ( error )
        NSLog(@"Core Data Error: %@", error.description);
}

-(void)fbSessionInvalidated {
    _watcherProfile.fbNickname = nil;
    _watcherProfile.fbAccessToken = nil;
    _watcherProfile.fbAccessExpires = nil;
    
    NSError *error = nil;
    [_managedObjectContext save: &error];
    if ( error )
        NSLog(@"Core Data Error: %@", error.description);
}

-(void)request:(FBRequest *)request didLoad:(id)result {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ( [[request.url lastPathComponent] isEqualToString: @"me"] ) {
    
        if ( [result objectForKey: @"username"] ) 
            _watcherProfile.fbNickname = [result objectForKey: @"username"];
        else
            _watcherProfile.fbNickname = [result objectForKey: @"id"];

        if ( ! _watcherProfile.email.length )
            _watcherProfile.email = [result objectForKey: @"email"];
        
        if ( ! _watcherProfile.firstName.length )
            _watcherProfile.firstName = [result objectForKey: @"first_name"];
        
        if ( ! _watcherProfile.lastName.length )
            _watcherProfile.lastName = [result objectForKey: @"last_name"];
        
        
        NSPredicate *firstNamePredicate = [NSPredicate predicateWithFormat: @"SELF.name LIKE %@", @"first_name"];
        NSPredicate *lastNamePredicate = [NSPredicate predicateWithFormat: @"SELF.name LIKE %@", @"last_name"];
        NSPredicate *emailPredicate = [NSPredicate predicateWithFormat: @"SELF.name LIKE %@", @"email"];
        
        ChecklistItem *firstNameItem = [[[_watcherProfile.profileChecklistItems allObjects] filteredArrayUsingPredicate: firstNamePredicate] lastObject];
        ChecklistItem *lastNameItem = [[[_watcherProfile.profileChecklistItems allObjects] filteredArrayUsingPredicate: lastNamePredicate] lastObject];
        ChecklistItem *emailItem = [[[_watcherProfile.profileChecklistItems allObjects] filteredArrayUsingPredicate: emailPredicate] lastObject];

        if ( firstNameItem == nil ) {
            firstNameItem = [NSEntityDescription insertNewObjectForEntityForName: @"ChecklistItem" 
                                                          inManagedObjectContext: self.managedObjectContext];
            [_watcherProfile addProfileChecklistItemsObject: firstNameItem];
        }
        
        if ( lastNameItem == nil ) {
            lastNameItem = [NSEntityDescription insertNewObjectForEntityForName: @"ChecklistItem" 
                                                         inManagedObjectContext: self.managedObjectContext];
            [_watcherProfile addProfileChecklistItemsObject: lastNameItem];
        }
        
        if ( emailItem == nil ) {
            emailItem = [NSEntityDescription insertNewObjectForEntityForName: @"ChecklistItem" 
                                                      inManagedObjectContext: self.managedObjectContext];
            [_watcherProfile addProfileChecklistItemsObject: emailItem];
        }
        
        if ( ! [_watcherProfile.firstName isEqualToString: firstNameItem.value] ) {
            firstNameItem.name = @"first_name";
            firstNameItem.value = _watcherProfile.firstName;
            firstNameItem.lat = [NSNumber numberWithDouble: _currentLocation.coordinate.latitude];
            firstNameItem.lng = [NSNumber numberWithDouble: _currentLocation.coordinate.longitude];
            firstNameItem.timestamp = [NSDate date];
            firstNameItem.synchronized = [NSNumber numberWithBool: NO];
        }

        if ( ! [_watcherProfile.lastName isEqualToString: lastNameItem.value] ) {
            lastNameItem.name = @"last_name";
            lastNameItem.value = _watcherProfile.lastName;
            lastNameItem.lat = [NSNumber numberWithDouble: _currentLocation.coordinate.latitude];
            lastNameItem.lng = [NSNumber numberWithDouble: _currentLocation.coordinate.longitude];
            lastNameItem.timestamp = [NSDate date];
            lastNameItem.synchronized = [NSNumber numberWithBool: NO];
        }

        if ( ! [_watcherProfile.email isEqualToString: emailItem.value] ) {
            emailItem.name = @"email";
            emailItem.value = _watcherProfile.email;
            emailItem.lat = [NSNumber numberWithDouble: _currentLocation.coordinate.latitude];
            emailItem.lng = [NSNumber numberWithDouble: _currentLocation.coordinate.longitude];
            emailItem.timestamp = [NSDate date];
            emailItem.synchronized = [NSNumber numberWithBool: NO];
        }
        
        NSError *error = nil;
        [_managedObjectContext save: &error];
        if ( error )
            NSLog(@"Core Data Error: %@", error.description);
    }
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
        
        NSURL *profileInfoUrl = [NSURL URLWithString: @"https://api.twitter.com/1/account/verify_credentials.json"];
        TWRequest *twRequest = [[TWRequest alloc] initWithURL: profileInfoUrl parameters: nil requestMethod: TWRequestMethodGET];
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
                
//                [TestFlight passCheckpoint: @"Twitter login"];
            } else {
                NSLog(@"twitter request error: %@", error);
            }
        }];
        
        /*
        CFUUIDRef uuidRef = CFUUIDCreate(NULL);
        CFStringRef uuidString = CFUUIDCreateString(NULL, uuidRef);
        
        NSDictionary *step1Params = [NSDictionary dictionaryWithObjectsAndKeys: 
                                     @"", @"oauth_consumer_key", 
                                     (NSString *) uuidString, @"oauth_nonce", 
                                     @"HMAC-SHA1", @"oauth_signature_method", 
                                     [NSString stringWithFormat: @"%d", [[NSDate date] timeIntervalSince1970]], @"oauth_timestamp", 
                                     @"1.0", @"oauth_version", 
                                     @"reverse_auth", @"x_auth_mode", 
                                     nil];
        
        CFRelease(uuidString);
        CFRelease(uuidRef);
        
        TWRequest *reverseAuthStep1 = [[TWRequest alloc] initWithURL: [NSURL URLWithString: @"https://api.twitter.com/oauth/request_token"] 
                                                          parameters: step1Params 
                                                       requestMethod: TWRequestMethodPOST];
        [reverseAuthStep1 setAccount: [[twitterAccount retain] autorelease]];
        [reverseAuthStep1 performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            NSString *response1 = [[[NSString alloc] initWithData: responseData encoding: NSUTF8StringEncoding] autorelease];
            NSLog(@"step 1 response: %@", response1);
            NSDictionary *step2Params = [NSDictionary dictionaryWithObjectsAndKeys: 
                                         @"", @"x_reverse_auth_target", 
                                         response1, @"x_reverse_auth_parameters", 
                                         nil];
            TWRequest *reverseAuthStep2 = [[TWRequest alloc] initWithURL: [NSURL URLWithString: @"https://api.twitter.com/oauth/access_token"] 
                                                              parameters: step2Params 
                                                           requestMethod: TWRequestMethodPOST];
            [reverseAuthStep2 performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                NSString *response2 = [[[NSString alloc] initWithData: responseData encoding: NSUTF8StringEncoding] autorelease];
                NSLog(@"step 2 response: %@", response2);
            }];
            
            [reverseAuthStep2 release];
        }];
        
        [reverseAuthStep1 release];
         */
        
        
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

#pragma mark - Shared image picker instance

- (UIImagePickerController *) sharedImagePicker {
    if ( _sharedImagePicker == nil ) {
        _sharedImagePicker = [[UIImagePickerController alloc] init];
    }
    
    return _sharedImagePicker;
}


@end
