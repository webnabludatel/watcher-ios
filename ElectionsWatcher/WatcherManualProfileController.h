//
//  WatcherManualProfileController.h
//  ElectionsWatcher
//
//  Created by xfire on 18.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WatcherManualProfileControllerDelegate.h"
#import "WatcherChecklistScreenCellDelegate.h"
#import "WatcherSaveAttributeDelegate.h"

@interface WatcherManualProfileController : UITableViewController <WatcherChecklistScreenCellDelegate, WatcherSaveAttributeDelegate>

@property (nonatomic, retain) NSDictionary *settings;
@property (nonatomic, assign) id<WatcherManualProfileControllerDelegate> profileControllerDelegate;
@property (nonatomic, assign) UIResponder *latestActiveResponder;
@property (nonatomic) BOOL isCancelling;

@end
