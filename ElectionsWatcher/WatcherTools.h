//
//  WatcherTools.h
//  ElectionsWatcher
//
//  Created by xfire on 22.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WatcherTools : NSObject

+ (NSString *) countOfMarksString: (NSInteger) count;
+ (NSString *) countOfConformances: (NSInteger) count;
+ (NSString *) countOfViolations: (NSInteger) count;

@end
