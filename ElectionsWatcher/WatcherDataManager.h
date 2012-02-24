//
//  WatcherDataManager.h
//  ElectionsWatcher
//
//  Created by xfire on 17.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChecklistItem, MediaItem, Reachability;

@interface WatcherDataManager : NSObject

@property (nonatomic, retain) NSThread *dataManagerThread;
@property (nonatomic, retain) NSOperationQueue *uploadQueue;
@property (nonatomic, retain) NSMutableArray *errors;
@property (nonatomic, retain) NSMutableSet *objectsInProgress;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) Reachability *wifiReachability;

@property (nonatomic) BOOL active;
@property (nonatomic) BOOL hasErrors;

- (void) startProcessing;
- (void) stopProcessing;
- (void) registerCurrentDevice;
- (void) sendChecklistItem: (ChecklistItem *) checklistItem;
- (void) sendMediaItem: (MediaItem *) mediaItem;
- (void) uploadMediaItem: (MediaItem *) mediaItem;
- (void) processUnsentData;
- (void) saveManagedObjectContext;
- (void) processUnsentMediaItems;
- (void) enqueueMediaItem: (MediaItem *) mediaItem;

@end
