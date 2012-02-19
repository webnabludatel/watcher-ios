//
//  WatcherDataManager.h
//  ElectionsWatcher
//
//  Created by xfire on 17.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WatcherDataManager : NSObject

@property (nonatomic, retain) NSThread *dataManagerThread;
@property (nonatomic, retain) NSOperationQueue *uploadQueue;
@property (nonatomic) BOOL active;
@property (nonatomic) BOOL hasErrors;

- (void) startProcessing;
- (void) stopProcessing;

@end
