//
//  MediaItem.m
//  ElectionsWatcher
//
//  Created by xfire on 21.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MediaItem.h"
#import "ChecklistItem.h"
#import "PollingPlace.h"
#import "WatcherTools.h"


@implementation MediaItem

@dynamic filePath;
@dynamic mediaType;
@dynamic serverUrl;
@dynamic timestamp;
@dynamic synchronized;
@dynamic serverRecordId;
@dynamic checklistItem;
@dynamic pollingPlace;

- (NSString *) amazonS3FilePath {
    return [NSString stringWithFormat: @"%@/%@/%@", 
            self.checklistItem.name, [WatcherTools md5: self.objectID.URIRepresentation.absoluteString], self.filePath.lastPathComponent];
}

@end
