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
#import "NSObject+SBJSON.h"
#import <CommonCrypto/CommonDigest.h>
#import <AWSiOSSDK/S3/AmazonS3Client.h>
#import <MobileCoreServices/UTCoreTypes.h>

@implementation WatcherDataManager

@synthesize dataManagerThread = _dataManagerThread;
@synthesize uploadQueue = _uploadQueue;
@synthesize objectsInProgress = _objectsInProgress;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize errors = _errors;
@synthesize active = _active;
@synthesize hasErrors = _hasErrors;

-(void)dealloc {
    [_dataManagerThread release];
    [_uploadQueue release];
    [_errors release];
    [_objectsInProgress release];
    [_managedObjectContext release];
    
    [super dealloc];
}

- (void) runDataManager {
    @autoreleasepool {
        _uploadQueue = [[NSOperationQueue alloc] init];
        _errors = [[NSMutableArray alloc] init];
        _objectsInProgress = [[NSMutableSet alloc] init];
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        [_managedObjectContext setPersistentStoreCoordinator: appDelegate.persistentStoreCoordinator];
        
        [[NSNotificationCenter defaultCenter] addObserver: self 
                                                 selector: @selector(mergeContextChanges:) 
                                                     name: NSManagedObjectContextDidSaveNotification 
                                                   object: self.managedObjectContext];
        
        NSTimer *timer = [NSTimer timerWithTimeInterval: 30.0 target: self 
                                               selector: @selector(processUnsentData) 
                                               userInfo: nil 
                                                repeats: YES];
        
        [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
        [[NSRunLoop currentRunLoop] addTimer: timer forMode: NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void) saveManagedObjectContext {
    @synchronized ( self.managedObjectContext ) {
        NSError *error = nil;
        [self.managedObjectContext save: &error];
        if ( error )
            NSLog(@"error saving data manager context: %@", error.description);
    }
}

- (void) mergeContextChanges: (NSNotification *) notification {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.managedObjectContext performSelectorOnMainThread: @selector(mergeChangesFromContextDidSaveNotification:) 
                                                       withObject: notification 
                                                    waitUntilDone: YES];
}

- (void) registerCurrentDevice {
    NSOperation *registerOperation = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                          selector: @selector(dequeueDeviceRegistration) 
                                                                            object: nil];
    
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
                                                withContext: self.managedObjectContext
                                             withParameters: [NSDictionary dictionary]];
    
    NSLog(@"start processing cycle with %d unsent items and %d items in progress", unsentItems.count, _objectsInProgress.count);
    
    if ( unsentItems.count ) {
        for ( ChecklistItem *checklistItem in unsentItems ) {
            if ( checklistItem.isInserted || checklistItem.isUpdated ) 
                continue;
            
            if ( [_objectsInProgress containsObject: checklistItem] )
                continue;
            
            [_objectsInProgress addObject: checklistItem];
            
            NSLog(@"processing checklist item [%@]", checklistItem.name);
            
            NSOperation *checklistItemSendOperation = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                                           selector: @selector(dequeueChecklistItem:) 
                                                                                             object: checklistItem];

            [self.uploadQueue addOperation: checklistItemSendOperation];

            for ( MediaItem *mediaItem in checklistItem.mediaItems ) {
                if ( [_objectsInProgress containsObject: mediaItem] )
                    continue;
                
                [_objectsInProgress addObject: mediaItem];
                
                NSLog(@"processing media item [%@]", mediaItem.filePath);
                
                NSOperation *mediaItemSendOperation = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                                           selector: @selector(dequeueMediaItem:) 
                                                                                             object: mediaItem];
                
                [mediaItemSendOperation addDependency: checklistItemSendOperation];
                
                if ( ! mediaItem.serverUrl ) {
                    NSOperation *mediaItemUploadOperation = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                                                 selector: @selector(dequeueMediaItemUpload:) 
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
    
    NSLog(@"completed processing cycle with %d items in progress", _objectsInProgress.count);
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
    
    [TestFlight passCheckpoint: @"Scan for modified checklist items"];
}

/* threading: all core data operations should be performed on the same thread with managedObjectContext */

- (void) dequeueChecklistItem: (ChecklistItem *) checklistItem {
    [self performSelector: @selector(sendChecklistItem:) onThread: _dataManagerThread withObject: checklistItem waitUntilDone: YES];
}

- (void) dequeueMediaItem: (MediaItem *) mediaItem {
    [self performSelector: @selector(sendMediaItem:) onThread: _dataManagerThread withObject: mediaItem waitUntilDone: YES];
}

- (void) dequeueMediaItemUpload: (MediaItem *) mediaItem {
    [self performSelector: @selector(uploadMediaItem:) onThread: _dataManagerThread withObject: mediaItem waitUntilDone: YES];
}

- (void) dequeueDeviceRegistration {
    [self performSelector: @selector(sendDeviceRegistration) onThread: _dataManagerThread withObject: nil waitUntilDone: YES];
}

/* threading: end this */

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
    
    NSString *json = [payload JSONRepresentation];
    NSString *deviceId = [[UIDevice currentDevice] uniqueIdentifier];
    NSString *digest = [self md5: [[deviceId stringByAppendingString: json] stringByAppendingString: appDelegate.watcherProfile.serverSecret]];
    
    NSLog(@"server secret: %@, digest: %@",appDelegate.watcherProfile.serverSecret, digest);
    
    NSURL *url = [checklistItem.serverRecordId doubleValue] > 0 ? 
        [NSURL URLWithString: [NSString stringWithFormat: @"http://webnabludatel.org/api/v1/messages/%@.json?digest=%@", 
                               checklistItem.serverRecordId, digest]] :
        [NSURL URLWithString: [@"http://webnabludatel.org/api/v1/messages.json?digest=" stringByAppendingString: digest]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
    if ( [checklistItem.serverRecordId doubleValue] > 0 ) [request setRequestMethod: @"PUT"];
    [request setPostValue: deviceId forKey: @"device_id"];
    [request setPostValue: json forKey: @"payload"];
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
                [self.managedObjectContext refreshObject: checklistItem mergeChanges: YES];
                [self saveManagedObjectContext];
                
                NSLog(@"checklist item [%@] successfully synchronized", checklistItem.name);
            } else {
                // TODO: process server-side errors (check spec)
            }
        } else {
            NSLog(@"http request status: %d", [request responseStatusCode]);
        }
    }
    
    [_objectsInProgress removeObject: checklistItem];
    [appDelegate performSelectorOnMainThread: @selector(hideNetworkActivity) withObject: nil waitUntilDone: NO];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
}

- (void) sendMediaItem: (MediaItem *) mediaItem {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread: @selector(showNetworkActivity) withObject: nil waitUntilDone: NO];
    
    NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys: 
                             mediaItem.serverUrl, @"url", 
                             mediaItem.mediaType, @"type",
                             [NSNumber numberWithDouble: [mediaItem.timestamp timeIntervalSince1970]], @"timestamp",
                             nil];
    
    NSString *json = [payload JSONRepresentation];
    NSString *deviceId = [[UIDevice currentDevice] uniqueIdentifier];
    NSString *digest = [self md5: [[deviceId stringByAppendingString: json] stringByAppendingString: appDelegate.watcherProfile.serverSecret]];
    
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"http://webnabludatel.org/api/v1/messages/%@/media_items.json?digest=%@", 
                                        mediaItem.checklistItem.serverRecordId, digest]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
    [request setPostValue: deviceId forKey: @"device_id"];
    [request setPostValue: json forKey: @"payload"];
    [request startSynchronous];
    
    NSError *error = [request error];
    
    if ( error ) {
        NSLog(@"error sending media item: %@", error);
        [_errors addObject: error];
    } else {
        if ( [request responseStatusCode] == 200 ) {
            NSString *response = [request responseString];
            NSDictionary *messageInfo = [response JSONValue];
            if ( [@"ok" isEqualToString: [messageInfo objectForKey: @"status"]] ) {
                NSDictionary *result = [messageInfo objectForKey: @"result"];
                mediaItem.serverRecordId = [result objectForKey: @"media_item_id"];
                mediaItem.synchronized = [NSNumber numberWithBool: YES];
                [self.managedObjectContext refreshObject: mediaItem mergeChanges: YES];
                [self saveManagedObjectContext];
                
                NSLog(@"media item [%@] successfully synchronized", mediaItem.filePath);
            } else {
                // TODO: process server-side errors (check spec)
            }
        } else {
            NSLog(@"http request status: %d", [request responseStatusCode]);
        }
    }    
    
    [_objectsInProgress removeObject: mediaItem];
    [appDelegate performSelectorOnMainThread: @selector(hideNetworkActivity) withObject: nil waitUntilDone: NO];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
}

- (void) uploadMediaItem: (MediaItem *) mediaItem {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread: @selector(showNetworkActivity) withObject: nil waitUntilDone: NO];
    
    AmazonS3Client *s3Client = [[AmazonS3Client alloc] initWithAccessKey: @"AKIAIX6IT3CLX62LPWPA" 
                                                           withSecretKey: @"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"];

    @try {
        S3PutObjectRequest *putRequest = [[S3PutObjectRequest alloc] initWithKey: [mediaItem.filePath lastPathComponent] 
                                                                        inBucket: @"webnabludatel-media"];
        
        putRequest.contentType = [mediaItem.mediaType isEqualToString: (NSString *) kUTTypeImage] ? @"image/jpeg" : @"video/quicktime";
        putRequest.data = [NSData dataWithContentsOfFile: mediaItem.filePath];
        
        S3Response *response = [s3Client putObject: putRequest];
        NSLog(@"Amazon response token: %@", response.id2);
        mediaItem.serverUrl = [@"http://webnabludatel-media.s3.amazonaws.com/" stringByAppendingString: [mediaItem.filePath lastPathComponent]];
        NSLog(@"media item saved to server URL: %@", mediaItem.serverUrl);
        
        [self.managedObjectContext refreshObject: mediaItem mergeChanges: YES];
        [self saveManagedObjectContext];
    }
    @catch ( AmazonClientException *e ) {
        NSLog(@"Amazon client error: %@", e.message);
    }
    
    [appDelegate performSelectorOnMainThread: @selector(hideNetworkActivity) withObject: nil waitUntilDone: NO];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
}

- (void) sendDeviceRegistration {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread: @selector(showNetworkActivity) withObject: nil waitUntilDone: NO];
    
    NSURL *url = [NSURL URLWithString: @"http://webnabludatel.org/api/v1/authentications.json"];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
    [request setPostValue: [[UIDevice currentDevice] uniqueIdentifier] forKey: @"device_id"];
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
//                NSDictionary *useridChecklistParams = [NSDictionary dictionaryWithObjectsAndKeys: @"user_id", @"ITEM_NAME", nil];
                WatcherProfile *watcherProfile = [[appDelegate executeFetchRequest: @"findProfile" 
                                                                         forEntity: @"WatcherProfile" 
                                                                       withContext: self.managedObjectContext
                                                                    withParameters: [NSDictionary dictionary]] lastObject];

                /*
                ChecklistItem *useridChecklistItem = [[appDelegate executeFetchRequest: @"findItemByName" 
                                                                             forEntity: @"ChecklistItem" 
                                                                           withContext: self.managedObjectContext
                                                                        withParameters: useridChecklistParams] lastObject];
                
                useridChecklistItem.value   = [NSString stringWithFormat: @"%@", [result objectForKey: @"user_id"]];
                 */
                watcherProfile.userId       = [NSString stringWithFormat: @"%@", [result objectForKey: @"user_id"]];
                watcherProfile.serverSecret = [result objectForKey: @"secret"];
                
                [self.managedObjectContext refreshObject: watcherProfile mergeChanges: YES];
                [self saveManagedObjectContext];
            } else {
                // TODO: process server-side errors (check spec)
            }
        }
    }
    
    [appDelegate performSelectorOnMainThread: @selector(hideNetworkActivity) withObject: nil waitUntilDone: NO];
//    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
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
    return ( _objectsInProgress.count > 0 );
}

- (BOOL) hasErrors {
    return ( _errors.count > 0 );
}

@end
