//
//  ViolationInfo.h
//  ElectionsWatcher
//
//  Created by xfire on 14.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ViolationInfo : NSManagedObject

@property (nonatomic, retain) NSString * code;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * comments;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSNumber * synchronized;

@end
