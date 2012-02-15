//
//  WatcherSaveAttributeDelegate.h
//  ElectionsWatcher
//
//  Created by xfire on 15.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChecklistItem.h"

@protocol WatcherSaveAttributeDelegate <NSObject>

@required
- (void) didSaveAttributeItem: (ChecklistItem *) item;

@end
