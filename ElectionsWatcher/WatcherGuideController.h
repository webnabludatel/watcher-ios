//
//  SecondViewController.h
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WatcherGuideController : UIViewController <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate>

@property (nonatomic, retain) IBOutlet UIWebView *watcherGuideView;
@property (nonatomic, retain) NSMutableArray *searchResults;

@end
