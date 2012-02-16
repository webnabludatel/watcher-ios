//
//  WatcherReportController.h
//  ElectionsWatcher
//
//  Created by xfire on 11.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WatcherReportController : UITableViewController

@property (nonatomic, retain) NSArray *goodItems;
@property (nonatomic, retain) NSArray *badItems;
@property (nonatomic, retain) NSDictionary *watcherChecklist;

@end
