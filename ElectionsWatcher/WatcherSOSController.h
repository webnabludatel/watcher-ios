//
//  WatcherSOSController.h
//  ElectionsWatcher
//
//  Created by xfire on 11.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WatcherSOSController : UITableViewController

@property (nonatomic, retain) NSDictionary *sosReport;

- (void) saveSettings;
- (void) loadSettings;

@end
