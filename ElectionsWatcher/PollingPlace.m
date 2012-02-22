//
//  PollingPlace.m
//  ElectionsWatcher
//
//  Created by xfire on 21.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PollingPlace.h"
#import "ChecklistItem.h"
#import "MediaItem.h"
#import "WatcherProfile.h"


@implementation PollingPlace

@dynamic chairman;
@dynamic lat;
@dynamic lng;
@dynamic nameOrNumber;
@dynamic secretary;
@dynamic timestamp;
@dynamic totalObservers;
@dynamic type;
@dynamic region;
@dynamic checklistItems;
@dynamic mediaItems;
@dynamic watcherProfile;

- (NSString *) typeString {
    if ( [self.type isEqualToString: @"uik"] )
        return @"УИК";
    
    if ( [self.type isEqualToString: @"tik"] )
        return @"ТИК";
    
    return nil;
}

- (NSString *) titleString {
    if ( [self.type isEqualToString: @"uik"] )
        return [@"УИК № " stringByAppendingString: self.nameOrNumber];
    
    if ( [self.type isEqualToString: @"tik"] )
        return [@"ТИК " stringByAppendingString: self.nameOrNumber];
    
    return self.nameOrNumber;
    
}

@end
