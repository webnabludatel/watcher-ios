//
//  WatcherTools.m
//  ElectionsWatcher
//
//  Created by xfire on 22.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherTools.h"
#import <CommonCrypto/CommonDigest.h>

@implementation WatcherTools

+ (NSString *) countOfMarksString: (NSInteger) count {
    if ( div(count,100).rem >= 10 && div(count,100).rem <= 20 ) {
        return [NSString stringWithFormat: @"Отмечено %d пунктов", count];
    } else {
        switch ( div(count, 10).rem ) {
            case 1:
                return [NSString stringWithFormat: @"Отмечен %d пункт", count];
            case 2: 
            case 3:
            case 4:
                return [NSString stringWithFormat: @"Отмечено %d пункта", count];
            default:
                return [NSString stringWithFormat: @"Отмечено %d пунктов", count];
        }
    }
}

+ (NSString *) countOfConformances: (NSInteger) count {
    if ( div(count,100).rem >= 10 && div(count,100).rem <= 20 ) {
        return [NSString stringWithFormat: @"Выполнено %d требований", count];
    } else {
        switch ( div(count, 10).rem ) {
            case 1:
                return [NSString stringWithFormat: @"Выполнено %d требование", count];
            case 2: 
            case 3:
            case 4:
                return [NSString stringWithFormat: @"Выполнено %d требования", count];
            default:
                return [NSString stringWithFormat: @"Выполнено %d требований", count];
        }
    }
    
}

+ (NSString *) countOfViolations: (NSInteger) count {
    if ( div(count,100).rem >= 10 && div(count,100).rem <= 20 ) {
        return [NSString stringWithFormat: @"%d нарушений", count];
    } else {
        switch ( div(count, 10).rem ) {
            case 1:
                return [NSString stringWithFormat: @"%d нарушение", count];
            case 2: 
            case 3:
            case 4:
                return [NSString stringWithFormat: @"%d нарушения", count];
            default:
                return [NSString stringWithFormat: @"%d нарушений", count];
        }
    }
    
}

+ (NSString *) md5:(NSString *) input {
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}


@end
