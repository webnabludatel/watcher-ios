//
//  WatcherProfile.h
//  ElectionsWatcher
//
//  Created by xfire on 20.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChecklistItem, PollingPlace;

@interface WatcherProfile : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * fbAccessToken;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * twAccessToken;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSDate * fbAccessExpires;
@property (nonatomic, retain) NSDate * twAccessExpires;
@property (nonatomic, retain) NSString * fbNickname;
@property (nonatomic, retain) NSString * twNickname;
@property (nonatomic, retain) NSString * serverSecret;
@property (nonatomic, retain) PollingPlace *currentPollingPlace;
@property (nonatomic, retain) NSSet *profileChecklistItems;
@end

@interface WatcherProfile (CoreDataGeneratedAccessors)

- (void)addProfileChecklistItemsObject:(ChecklistItem *)value;
- (void)removeProfileChecklistItemsObject:(ChecklistItem *)value;
- (void)addProfileChecklistItems:(NSSet *)values;
- (void)removeProfileChecklistItems:(NSSet *)values;
@end
