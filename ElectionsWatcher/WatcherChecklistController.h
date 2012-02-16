//
//  FirstViewController.h
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WatcherPollingPlaceControllerDelegate.h"

@interface WatcherChecklistController : UITableViewController <WatcherPollingPlaceControllerDelegate>

@property (nonatomic, retain) NSDictionary *watcherChecklist;

@end
