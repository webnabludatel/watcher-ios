//
//  ChecklistItem.h
//  ElectionsWatcher
//
//  Created by xfire on 05.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MediaItem;

@interface ChecklistItem : NSManagedObject

@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lng;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * synchronized;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSSet *mediaItems;
@end

@interface ChecklistItem (CoreDataGeneratedAccessors)

- (void)addMediaItemsObject:(MediaItem *)value;
- (void)removeMediaItemsObject:(MediaItem *)value;
- (void)addMediaItems:(NSSet *)values;
- (void)removeMediaItems:(NSSet *)values;
@end
