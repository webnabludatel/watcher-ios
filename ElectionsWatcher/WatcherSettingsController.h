//
//  WatcherSettingsController.h
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WatcherSaveAttributeDelegate.h"
#import "WatcherPollingPlaceControllerDelegate.h"

@class PollingPlace;

@interface WatcherSettingsController : UITableViewController <WatcherSaveAttributeDelegate, WatcherPollingPlaceControllerDelegate>

@property (nonatomic, retain) NSDictionary *settings;

@end
