//
//  AppDelegate.h
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import "Facebook.h"

@class PollingPlace, WatcherDataManager, WatcherProfile;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, CLLocationManagerDelegate, UINavigationControllerDelegate, FBSessionDelegate, FBRequestDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *currentLocation;
@property (nonatomic, retain) WatcherDataManager *dataManager;
@property (nonatomic, retain) Facebook *facebook;
@property (nonatomic, readonly) WatcherProfile *watcherProfile;

- (NSArray *) executeFetchRequest: (NSString *) request forEntity: (NSString *) entity withParameters: (NSDictionary *) params;
- (void) setupTwitterAccountForUsername: (NSString *) username withCompletionHandler: (void (^)(void)) completionHandler;
- (void) updateSynchronizationStatus;

@end
