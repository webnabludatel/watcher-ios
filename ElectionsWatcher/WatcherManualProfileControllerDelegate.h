//
//  WatcherManualProfileControllerDelegate.h
//  ElectionsWatcher
//
//  Created by xfire on 18.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WatcherManualProfileController;
@class WatcherProfile;

@protocol WatcherManualProfileControllerDelegate <NSObject>

- (void) watcherManualProfileController: (WatcherManualProfileController *) controller
                         didSaveProfile: (WatcherProfile *) watcherProfile;

- (void) watcherManualProfileControllerDidCancel: (WatcherManualProfileController *) controller;

@end
