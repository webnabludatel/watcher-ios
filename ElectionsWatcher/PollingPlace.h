//
//  PollingPlace.h
//  ElectionsWatcher
//
//  Created by xfire on 21.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChecklistItem, MediaItem, WatcherProfile;

@interface PollingPlace : NSManagedObject

@property (nonatomic, retain) NSString * chairman;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lng;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSString * secretary;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * totalObservers;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *checklistItems;
@property (nonatomic, retain) NSSet *mediaItems;
@property (nonatomic, retain) WatcherProfile *watcherProfile;
@end

@interface PollingPlace (CoreDataGeneratedAccessors)

- (void)addChecklistItemsObject:(ChecklistItem *)value;
- (void)removeChecklistItemsObject:(ChecklistItem *)value;
- (void)addChecklistItems:(NSSet *)values;
- (void)removeChecklistItems:(NSSet *)values;
- (void)addMediaItemsObject:(MediaItem *)value;
- (void)removeMediaItemsObject:(MediaItem *)value;
- (void)addMediaItems:(NSSet *)values;
- (void)removeMediaItems:(NSSet *)values;
@end
