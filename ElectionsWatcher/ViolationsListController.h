//
//  FirstViewController.h
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViolationsListController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableView *violationsTableView;

@end
