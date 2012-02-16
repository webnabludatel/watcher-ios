//
//  WatcherPollingPlaceControllerDelegate.h
//  ElectionsWatcher
//
//  Created by xfire on 16.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WatcherPollingPlaceController;
@class PollingPlace;

@protocol WatcherPollingPlaceControllerDelegate <NSObject>

@required

- (void) watcherPollingPlaceController: (WatcherPollingPlaceController *) controller
                   didSavePollingPlace: (PollingPlace *) pollinngPlace;

- (void) watcherPollingPlaceControllerDidCancel:(WatcherPollingPlaceController *)controller;

@end
