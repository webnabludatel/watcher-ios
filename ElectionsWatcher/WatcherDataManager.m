//
//  WatcherDataManager.m
//  ElectionsWatcher
//
//  Created by xfire on 17.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherDataManager.h"
#import "AppDelegate.h"
#import "ChecklistItem.h"
#import "MediaItem.h"
#import "WatcherProfile.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NSString+SBJSON.h"
#import "NSObject+SBJSON.h"
#import <CommonCrypto/CommonDigest.h>
#import <AWSiOSSDK/S3/AmazonS3Client.h>

@implementation WatcherDataManager

@synthesize dataManagerThread = _dataManagerThread;
@synthesize uploadQueue = _uploadQueue;
@synthesize errors = _errors;
@synthesize active = _active;
@synthesize hasErrors = _hasErrors;

-(void)dealloc {
    [_dataManagerThread release];
    [_uploadQueue release];
    [_errors release];
    
    [super dealloc];
}

- (void) runDataManager {
    @autoreleasepool {
        _uploadQueue = [[NSOperationQueue alloc] init];
        _errors = [[NSMutableArray alloc] init];
        
        NSTimer *timer = [NSTimer timerWithTimeInterval: 10.0 target: self 
                                               selector: @selector(processUnsentData) 
                                               userInfo: nil 
                                                repeats: YES];
        
        [[NSRunLoop currentRunLoop] addTimer: timer forMode: NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void) registerCurrentDevice {
    NSString *UDID = [[UIDevice currentDevice] uniqueIdentifier];
    NSOperation *registerOperation = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                          selector: @selector(sendDeviceRegistration:) 
                                                                            object: UDID];
    
    [_uploadQueue addOperation: registerOperation];
    [registerOperation release];
}

- (NSString *) md5:(NSString *) input {
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

- (void) processUnsentData {
    if ( [[NSThread currentThread] isCancelled] )
        [NSThread exit];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
    
    NSArray *unsentItems = [appDelegate executeFetchRequest: @"findUnsentChecklistItems" 
                                                  forEntity: @"ChecklistItem" 
                                             withParameters: [NSDictionary dictionary]];

    
    if ( unsentItems.count ) {
        for ( ChecklistItem *checklistItem in unsentItems ) {
            if ( checklistItem.isInserted || checklistItem.isUpdated ) 
                continue;
            
            NSLog(@"processing checklist item [%@]", checklistItem.name);
            
            NSOperation *checklistItemSendOperation = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                                           selector: @selector(sendChecklistItem:) 
                                                                                             object: checklistItem];

            [self.uploadQueue addOperation: checklistItemSendOperation];

            for ( MediaItem *mediaItem in checklistItem.mediaItems ) {
                NSOperation *mediaItemSendOperation = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                                           selector: @selector(sendMediaItem:) 
                                                                                             object: mediaItem];
                
                [mediaItemSendOperation addDependency: checklistItemSendOperation];
                
                if ( ! mediaItem.serverUrl ) {
                    NSOperation *mediaItemUploadOperation = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                                                 selector: @selector(uploadMediaItem:) 
                                                                                                   object: mediaItem];
                    [mediaItemSendOperation addDependency: mediaItemUploadOperation];
                    [self.uploadQueue addOperation: mediaItemUploadOperation];
                    [mediaItemUploadOperation release];
                }
                
                [self.uploadQueue addOperation: mediaItemSendOperation];
                [mediaItemSendOperation release];
            }
            
            [checklistItemSendOperation release];
        }
    }
    
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
}

- (void) sendChecklistItem: (ChecklistItem *) checklistItem {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread: @selector(showNetworkActivity) withObject: nil waitUntilDone: NO];
    
    NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys: 
                             checklistItem.name, @"key", 
                             checklistItem.value, @"value",
                             checklistItem.lat, @"lat",
                             checklistItem.lng, @"lng",
                             [NSNumber numberWithDouble: [checklistItem.timestamp timeIntervalSince1970]], @"timestamp",
                             nil];
    
    NSString *deviceId = [[UIDevice currentDevice] uniqueIdentifier];
    NSString *digest = [self md5: [[deviceId stringByAppendingString: [payload JSONRepresentation]] 
                        stringByAppendingString: appDelegate.watcherProfile.serverSecret]];
    
    NSURL *url = [checklistItem.serverRecordId doubleValue] > 0 ? 
        [NSURL URLWithString: [NSString stringWithFormat: @"http://webnabludatel.org/api/v1/messages/%@.json?digest=%@", 
                               checklistItem.serverRecordId, digest]] :
        [NSURL URLWithString: [@"http://webnabludatel.org/api/v1/messages.json?digest=" stringByAppendingString: digest]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
    if ( [checklistItem.serverRecordId doubleValue] > 0 ) [request setRequestMethod: @"PUT"];
    [request setPostValue: deviceId forKey: @"device_id"];
    [request setPostValue: [payload JSONRepresentation] forKey: @"payload"];
    [request startSynchronous];
    
    NSError *error = [request error];
    
    if ( error ) {
        NSLog(@"error sending checklist item: %@", error);
        [_errors addObject: error];
    } else {
        if ( [request responseStatusCode] == 200 ) {
            NSString *response = [request responseString];
            NSDictionary *messageInfo = [response JSONValue];
            if ( [@"ok" isEqualToString: [messageInfo objectForKey: @"status"]] ) {
                NSDictionary *result = [messageInfo objectForKey: @"result"];
                checklistItem.serverRecordId = [result objectForKey: @"message_id"];
                checklistItem.synchronized = [NSNumber numberWithBool: YES];
                [appDelegate.managedObjectContext save: &error];
                
                NSLog(@"checklist item [%@] successfully synchronized", checklistItem.name);
            } else {
                // TODO: process server-side errors (check spec)
            }
        } else {
            NSLog(@"http request status: %d", [request responseStatusCode]);
        }
    }
    
    [appDelegate performSelectorOnMainThread: @selector(hideNetworkActivity) withObject: nil waitUntilDone: NO];
}

- (void) sendMediaItem: (MediaItem *) mediaItem {
}

- (void) uploadMediaItem: (MediaItem *) mediaItem {
}

- (void) sendDeviceRegistration: (NSString *) UDID {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread: @selector(showNetworkActivity) withObject: nil waitUntilDone: NO];
    
    NSURL *url = [NSURL URLWithString: @"http://webnabludatel.org/api/v1/authentications.json"];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
    [request setPostValue: UDID forKey: @"device_id"];
    [request startSynchronous];
    
    NSError *error = [request error];
    
    if ( error ) {
        NSLog(@"error sending devica registration: %@", error);
        [_errors addObject: error];
    } else {
        if ( [request responseStatusCode] == 200 ) {
            NSString *response = [request responseString];
            NSDictionary *registrationInfo = [response JSONValue];
            
            if ( [@"ok" isEqualToString: [registrationInfo objectForKey: @"status"]] ) {
                NSDictionary *result = [registrationInfo objectForKey: @"result"];
                NSDictionary *useridChecklistParams = [NSDictionary dictionaryWithObjectsAndKeys: @"user_id", @"ITEM_NAME", nil];
                WatcherProfile *watcherProfile = [[appDelegate executeFetchRequest: @"findProfile" 
                                                                         forEntity: @"WatcherProfile" 
                                                                    withParameters: [NSDictionary dictionary]] lastObject];
                
                ChecklistItem *useridChecklistItem = [[appDelegate executeFetchRequest: @"findItemByName" 
                                                                             forEntity: @"ChecklistItem" 
                                                                        withParameters: useridChecklistParams] lastObject];
                
                useridChecklistItem.value   = [NSString stringWithFormat: @"%@", [result objectForKey: @"user_id"]];
                watcherProfile.userId       = [NSString stringWithFormat: @"%@", [result objectForKey: @"user_id"]];
                watcherProfile.serverSecret = [result objectForKey: @"secret"];
                
                [appDelegate.managedObjectContext save: &error];
            } else {
                // TODO: process server-side errors (check spec)
            }
        }
    }
    
    [appDelegate performSelectorOnMainThread: @selector(hideNetworkActivity) withObject: nil waitUntilDone: NO];
}

- (void) startProcessing {
    _dataManagerThread = [[NSThread alloc] initWithTarget: self selector: @selector(runDataManager) object: nil];
    [_dataManagerThread start];
}

- (void) stopProcessing {
    [_dataManagerThread cancel];
    [_dataManagerThread release];
    _dataManagerThread = nil;
}

- (BOOL) active {
    NSLog(@"current operations in upload queue: %d", _uploadQueue.operationCount);
    return ( _uploadQueue.operationCount > 0 );
}

- (BOOL) hasErrors {
    return ( _errors.count > 0 );
}

@end
