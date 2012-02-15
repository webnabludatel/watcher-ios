//
//  WatcherSettingsController.h
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WatcherSaveAttributeDelegate.h"

@class PollingPlace;

@interface WatcherSettingsController : UITableViewController <WatcherSaveAttributeDelegate>

@property (nonatomic, retain) PollingPlace *activePollingPlace;
@property (nonatomic, retain) NSDictionary *settings;

- (void) loadSettings;

@end
