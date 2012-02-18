//
//  WatcherSOSController.h
//  ElectionsWatcher
//
//  Created by xfire on 11.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WatcherSaveAttributeDelegate.h"
#import "WatcherChecklistScreenCellDelegate.h"

@interface WatcherSOSController : UITableViewController <WatcherSaveAttributeDelegate, WatcherChecklistScreenCellDelegate>

@property (nonatomic, retain) NSDictionary *sosReport;
@property (nonatomic, assign) UIResponder *latestActiveResponder;

@end
