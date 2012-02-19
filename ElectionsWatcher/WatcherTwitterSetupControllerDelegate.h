//
//  WatcherTwitterSetupControllerDelegate.h
//  ElectionsWatcher
//
//  Created by xfire on 19.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WatcherTwitterSetupController;

@protocol WatcherTwitterSetupControllerDelegate <NSObject>

- (void) watcherTwitterSetupController: (WatcherTwitterSetupController *) controller didSelectUsername: (NSString *) username;
- (void) watcherTwitterSetupControllerDidCancel: (WatcherTwitterSetupController *) controller;

@end
