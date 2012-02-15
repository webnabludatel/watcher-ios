//
//  WatcherChecklistScreenController.h
//  ElectionsWatcher
//
//  Created by xfire on 22.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WatcherSaveAttributeDelegate.h"

@interface WatcherChecklistScreenController : UITableViewController <WatcherSaveAttributeDelegate>

@property (nonatomic, retain) NSDictionary *screenInfo;
@property (nonatomic) NSInteger screenIndex;
@property (nonatomic) NSInteger sectionIndex;

@end
