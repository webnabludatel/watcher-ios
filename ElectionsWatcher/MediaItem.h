//
//  MediaItem.h
//  ElectionsWatcher
//
//  Created by xfire on 05.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChecklistItem;

@interface MediaItem : NSManagedObject

@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) NSString * mediaType;
@property (nonatomic, retain) NSString * serverUrl;
@property (nonatomic, retain) ChecklistItem *checklistItem;

@end
