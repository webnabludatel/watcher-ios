//
//  WatcherSettingsController.h
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WatcherSettingsController : UITableViewController

@property (nonatomic, retain) NSDictionary *settings;

- (void) saveSettings;
- (void) loadSettings;

@end
