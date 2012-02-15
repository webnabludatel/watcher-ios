//
//  WatcherPollingPlaceController.h
//  ElectionsWatcher
//
//  Created by xfire on 15.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WatcherSaveAttributeDelegate.h"

@class PollingPlace;

@interface WatcherPollingPlaceController : UITableViewController <WatcherSaveAttributeDelegate>

@property (nonatomic, assign) id saveDelegate;
@property (nonatomic, assign) PollingPlace *pollingPlace;
@property (nonatomic, retain) NSDictionary *settings;

- (void) loadSettings;

@end
