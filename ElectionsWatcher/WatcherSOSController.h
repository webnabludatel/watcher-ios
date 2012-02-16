//
//  WatcherSOSController.h
//  ElectionsWatcher
//
//  Created by xfire on 11.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WatcherSaveAttributeDelegate.h"

@interface WatcherSOSController : UITableViewController <WatcherSaveAttributeDelegate>

@property (nonatomic, retain) NSDictionary *sosReport;

@end
