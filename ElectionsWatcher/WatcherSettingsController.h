//
//  WatcherSettingsController.h
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WatcherSaveAttributeDelegate.h"
#import "WatcherManualProfileControllerDelegate.h"
#import "WatcherTwitterSetupControllerDelegate.h"
#import "MBProgressHUD.h"

@class PollingPlace, MBProgressHUD;

@interface WatcherSettingsController : UITableViewController <WatcherSaveAttributeDelegate, WatcherManualProfileControllerDelegate, MBProgressHUDDelegate, WatcherTwitterSetupControllerDelegate>

@property (nonatomic, retain) NSDictionary *settings;
@property (nonatomic, assign) MBProgressHUD *HUD;

@end
