//
//  WatcherTwitterSetupController.h
//  ElectionsWatcher
//
//  Created by xfire on 19.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import "WatcherTwitterSetupControllerDelegate.h"

@interface WatcherTwitterSetupController : UITableViewController

@property (nonatomic, retain) NSMutableArray *twitterAccounts;
@property (nonatomic, retain) NSString *selectedUsername;
@property (nonatomic, assign) id<WatcherTwitterSetupControllerDelegate> delegate;

@end
