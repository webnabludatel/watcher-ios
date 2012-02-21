//
//  WatcherChecklistScreenController.h
//  ElectionsWatcher
//
//  Created by xfire on 22.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WatcherSaveAttributeDelegate.h"
#import "WatcherChecklistScreenCellDelegate.h"

@interface WatcherChecklistScreenController : UITableViewController <WatcherSaveAttributeDelegate, WatcherChecklistScreenCellDelegate>

@property (nonatomic, retain) NSDictionary *screenInfo;
@property (nonatomic) NSInteger screenIndex;
@property (nonatomic, retain) NSString *sectionName;
@property (nonatomic) BOOL isCancelling;
@property (nonatomic, assign) UIResponder *latestActiveResponder;

@end
