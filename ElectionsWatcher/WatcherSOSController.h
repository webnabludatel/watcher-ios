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
#import "MBProgressHUD.h"

@interface WatcherSOSController : UITableViewController <WatcherSaveAttributeDelegate, WatcherChecklistScreenCellDelegate, MBProgressHUDDelegate>

@property (nonatomic, retain) NSDictionary *sosReport;
@property (nonatomic, retain) NSMutableSet *sosItems;
@property (nonatomic, assign) UIResponder *latestActiveResponder;
@property (nonatomic, assign) MBProgressHUD *HUD;

@end
