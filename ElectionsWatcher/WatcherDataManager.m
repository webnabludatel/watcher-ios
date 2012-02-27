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
#import "PollingPlace.h"
#import "WatcherProfile.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NSObject+SBJSON.h"
//#import <AWSiOSSDK/S3/AmazonS3Client.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "WatcherTools.h"
#import "Reachability.h"
#import "ASIS3Request.h"
#import "ASIS3ObjectRequest.h"

@implementation WatcherDataManager

@synthesize dataManagerThread = _dataManagerThread;
@synthesize uploadQueue = _uploadQueue;
@synthesize objectsInProgress = _objectsInProgress;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize errors = _errors;
@synthesize active = _active;
@synthesize hasErrors = _hasErrors;
@synthesize wifiReachability = _wifiReachability;

-(void)dealloc {
    [_dataManagerThread release];
    [_uploadQueue release];
    [_errors release];
    [_objectsInProgress release];
    [_managedObjectContext release];
    [_wifiReachability release];
    
    [super dealloc];
}

#pragma mark - Thread & context management

- (void) runDataManager {
    @autoreleasepool {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        if ( _uploadQueue == nil ) 
            _uploadQueue = [[NSOperationQueue alloc] init];
        
        if ( _errors == nil )
            _errors = [[NSMutableArray alloc] init];
        
        if ( _objectsInProgress == nil ) 
            _objectsInProgress = [[NSMutableSet alloc] init];
        
        if ( _managedObjectContext == nil ) {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            [_managedObjectContext setPersistentStoreCoordinator: appDelegate.persistentStoreCoordinator];
        }
        
        if ( _wifiReachability == nil ) 
            _wifiReachability = [[Reachability reachabilityForLocalWiFi] retain];
        
        [_wifiReachability startNotifier];
        
        if ( ! _wifiReachability.currentReachabilityStatus ) 
            _uploadQueue.maxConcurrentOperationCount = 3;
        
        [[NSNotificationCenter defaultCenter] addObserver: self 
                                                 selector: @selector(handleReachabilityChange:) 
                                                     name: kReachabilityChangedNotification 
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self 
                                                 selector: @selector(mergeContextChanges:) 
                                                     name: NSManagedObjectContextDidSaveNotification 
                                                   object: self.managedObjectContext];
        
        NSTimer *checklistItemsTimer = [NSTimer timerWithTimeInterval: 37.0 target: self 
                                                             selector: @selector(processUnsentData) 
                                                             userInfo: nil 
                                                              repeats: YES];
        
        
        NSTimer *mediaItemsTimer = [NSTimer timerWithTimeInterval: 71.0f target: self 
                                                         selector: @selector(processUnsentMediaItems) 
                                                         userInfo: nil 
                                                          repeats: YES];
        
        [[NSRunLoop currentRunLoop] addTimer: checklistItemsTimer forMode: NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] addTimer: mediaItemsTimer forMode: NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void) saveManagedObject: (NSManagedObject *) managedObject {
    if ( [NSThread currentThread] != _dataManagerThread )
        @throw [NSException exceptionWithName: NSInternalInconsistencyException 
                                       reason: @"this method should be called only on data manager thread" 
                                     userInfo: nil];
    
    @synchronized ( _managedObjectContext ) {
        NSError *error = nil;
        if ( ! managedObject.isDeleted )
            [_managedObjectContext refreshObject: managedObject mergeChanges: YES];
        
        [_managedObjectContext save: &error];
        
        if ( error )
            NSLog(@"error saving managed object %@: %@", managedObject.objectID, error.description);
    }
}

- (void) mergeContextChanges: (NSNotification *) notification {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.managedObjectContext performSelectorOnMainThread: @selector(mergeChangesFromContextDidSaveNotification:) 
                                                       withObject: notification 
                                                    waitUntilDone: YES];
}

- (void) handleReachabilityChange: (NSNotification *) notification {
    if ( _wifiReachability.currentReachabilityStatus > 0 )
        _uploadQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    else
        _uploadQueue.maxConcurrentOperationCount = 3;
    
    NSLog(@"network reachability changed, queue concurrent operations count set to %d", _uploadQueue.maxConcurrentOperationCount);
}

#pragma mark - Processing

- (void) processUnsentMediaItems {
    if ( [[NSThread currentThread] isCancelled] ) {
        [NSThread exit];
    }

    @autoreleasepool {
        NSLog(@"checking for unsynchronized media items that are not currently in progress");
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        NSArray *unsentItems = [appDelegate executeFetchRequest: @"findUnsentMediaItems" 
                                                      forEntity: @"MediaItem" 
                                                    withContext: self.managedObjectContext
                                                 withParameters: [NSDictionary dictionary]];
        
        NSLog(@"found %d unsent media items", unsentItems.count);
        
        for ( MediaItem *mediaItem in unsentItems ) {
            if ( [_objectsInProgress containsObject: mediaItem] )
                continue;
            
            if ( ! mediaItem.isReadyToSync )
                continue;
            
            [self enqueueMediaItem: mediaItem];
        }
    }
}

- (void) processUnsentData {
    if ( [[NSThread currentThread] isCancelled] ) {
        [NSThread exit];
    }
    
    @autoreleasepool {
        [_errors removeAllObjects];
        
        NSLog(@"queue concurrent operations count = %d", _uploadQueue.maxConcurrentOperationCount);
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
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
                
                NSOperation *checklistItemSendOperation = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                                               selector: @selector(dequeueChecklistItem:) 
                                                                                                 object: checklistItem];

                [_objectsInProgress addObject: checklistItem];
                [self.uploadQueue addOperation: checklistItemSendOperation];
                
                for ( MediaItem *mediaItem in checklistItem.mediaItems ) {
                    if ( [_objectsInProgress containsObject: mediaItem] )
                        continue;
                    
                    if ( [mediaItem.synchronized boolValue] )
                        continue;
                    
//                    if ( [mediaItem.mediaType isEqualToString: (NSString *) kUTTypeMovie] ) {
//                        if ( _wifiReachability.currentReachabilityStatus == 0 ) {
//                            NSLog(@"media item [%@] will be uploaded only when WiFi becomes available", mediaItem.filePath);
//                            continue;
//                        }
//                    }
                    
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

                    [_objectsInProgress addObject: mediaItem];
                    [self.uploadQueue addOperation: mediaItemSendOperation];
                    [mediaItemSendOperation release];
                }
                
                [checklistItemSendOperation release];
            }
        }
        
        NSLog(@"completed processing cycle with %d items in progress", _objectsInProgress.count);
        
//        [TestFlight passCheckpoint: @"Scan for modified checklist items"];
    }
}

- (void) enqueueMediaItem: (MediaItem *) mediaItem {
    if ( ! [_objectsInProgress containsObject: mediaItem] ) {
        NSOperation *mediaItemSendOperation = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                                   selector: @selector(dequeueMediaItem:) 
                                                                                     object: mediaItem];
        
        if ( ! mediaItem.serverUrl ) {
            NSOperation *mediaItemUploadOperation = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                                         selector: @selector(dequeueMediaItemUpload:) 
                                                                                           object: mediaItem];
            [mediaItemSendOperation addDependency: mediaItemUploadOperation];
            [self.uploadQueue addOperation: mediaItemUploadOperation];
            [mediaItemUploadOperation release];
        }
        
        [_objectsInProgress addObject: mediaItem];
        [self.uploadQueue addOperation: mediaItemSendOperation];
        [mediaItemSendOperation release];
    }
}

- (void) dequeueChecklistItem: (ChecklistItem *) checklistItem {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
    [self sendChecklistItem: checklistItem];
//    [self performSelector: @selector(sendChecklistItem:) onThread: _dataManagerThread withObject: checklistItem waitUntilDone: YES];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
}

- (void) dequeueMediaItem: (MediaItem *) mediaItem {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
    [self sendMediaItem: mediaItem];
//    [self performSelector: @selector(sendMediaItem:) onThread: _dataManagerThread withObject: mediaItem waitUntilDone: YES];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
}

- (void) dequeueMediaItemUpload: (MediaItem *) mediaItem {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
    [self uploadMediaItem: mediaItem];
//    [self performSelector: @selector(uploadMediaItem:) onThread: _dataManagerThread withObject: mediaItem waitUntilDone: YES];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
}

#pragma mark - Send operations

- (void) registerCurrentDevice {
    [self performSelector: @selector(sendDeviceRegistration) onThread: _dataManagerThread withObject: nil waitUntilDone: NO];
}

- (void) sendChecklistItem: (ChecklistItem *) checklistItem {
    @autoreleasepool {
        NSLog(@"processing checklist item [%@]", checklistItem.name);
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys: 
                                 checklistItem.name, @"key", 
                                 checklistItem.value, @"value",
                                 checklistItem.lat, @"lat",
                                 checklistItem.lng, @"lng",
                                 checklistItem.objectID.URIRepresentation.absoluteString, @"internal_id",
                                 checklistItem.pollingPlace.objectID.URIRepresentation.absoluteString, @"polling_place_internal_id",
                                 [NSNumber numberWithDouble: [checklistItem.timestamp timeIntervalSince1970]], @"timestamp",
                                 nil];
        
        NSString *json = [payload JSONRepresentation];
        NSString *deviceId = [[UIDevice currentDevice] uniqueIdentifier];
        NSString *digest = [WatcherTools md5: [[deviceId stringByAppendingString: json] 
                                               stringByAppendingString: appDelegate.watcherProfile.serverSecret]];
        
        NSURL *url = [checklistItem.serverRecordId doubleValue] > 0 ? 
            [NSURL URLWithString: [NSString stringWithFormat: @"http://webnabludatel.org/api/v1/messages/%@.json?digest=%@", 
                                   checklistItem.serverRecordId, digest]] :
            [NSURL URLWithString: [@"http://webnabludatel.org/api/v1/messages.json?digest=" stringByAppendingString: digest]];

        [ASIFormDataRequest setShouldThrottleBandwidthForWWAN: YES];
        [ASIFormDataRequest throttleBandwidthForWWANUsingLimit: 21600];
        
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
        if ( [checklistItem.serverRecordId doubleValue] > 0 ) [request setRequestMethod: @"PUT"];
        [request setShouldCompressRequestBody: NO];
        [request setTimeOutSeconds: 60];
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
                    
                    [self performSelector: @selector(saveManagedObject:) 
                                 onThread: _dataManagerThread 
                               withObject: checklistItem 
                            waitUntilDone: NO];
                    
                    NSLog(@"checklist item [%@] successfully synchronized", checklistItem.name);
                } else {
                    // TODO: process server-side errors (check spec)
                }
            } else {
                NSLog(@"request to %@ returned error code %d", request.url, request.responseStatusCode);
                [_errors addObject: [request responseStatusMessage]];
            }
        }
        
        [_objectsInProgress removeObject: checklistItem];
    }
}

- (void) sendMediaItem: (MediaItem *) mediaItem {
    @autoreleasepool {
        NSLog(@"processing media item [%@]", mediaItem.filePath);
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        if ( mediaItem.checklistItem ) {
            // process media item update/insert
            if ( mediaItem.serverUrl ) {
                
                NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys: 
                                         mediaItem.objectID.URIRepresentation.absoluteString, @"internal_id",
                                         mediaItem.checklistItem.objectID.URIRepresentation.absoluteString, @"checklist_item_internal_id",
                                         mediaItem.serverUrl, @"url", 
                                         mediaItem.mediaType, @"type",
                                         [NSNumber numberWithDouble: [mediaItem.timestamp timeIntervalSince1970]], @"timestamp",
                                         nil];
                
                NSString *json = [payload JSONRepresentation];
                NSString *deviceId = [[UIDevice currentDevice] uniqueIdentifier];
                NSString *digest = [WatcherTools md5: [[deviceId stringByAppendingString: json] stringByAppendingString: appDelegate.watcherProfile.serverSecret]];
                
                NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: 
                                                    @"http://webnabludatel.org/api/v1/messages/%@/media_items.json?digest=%@", 
                                                    mediaItem.checklistItem.serverRecordId, digest]];

                [ASIFormDataRequest setShouldThrottleBandwidthForWWAN: YES];
                [ASIFormDataRequest throttleBandwidthForWWANUsingLimit: 21600];

                ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
                [request setShouldCompressRequestBody: NO];
                [request setTimeOutSeconds: 60];
                [request setPostValue: deviceId forKey: @"device_id"];
                [request setPostValue: json forKey: @"payload"];
                [request startSynchronous];
                
                NSError *error = [request error];
                
                if ( error ) {
                    NSLog(@"error sending media item: %@, will retry", error);
                    [_errors addObject: error];
                    [_objectsInProgress removeObject: mediaItem];
//                    [self performSelector: @selector(enqueueMediaItem:) withObject: mediaItem afterDelay: 31];
                } else {
                    if ( [request responseStatusCode] == 200 ) {
                        NSString *response = [request responseString];
                        NSDictionary *messageInfo = [response JSONValue];
                        if ( [@"ok" isEqualToString: [messageInfo objectForKey: @"status"]] ) {
                            NSDictionary *result = [messageInfo objectForKey: @"result"];
                            mediaItem.serverRecordId = [result objectForKey: @"media_item_id"];
                            mediaItem.synchronized = [NSNumber numberWithBool: YES];
                            
                            [self performSelector: @selector(saveManagedObject:) 
                                         onThread: _dataManagerThread 
                                       withObject: mediaItem 
                                    waitUntilDone: NO];
                            
                            NSLog(@"media item [%@] successfully synchronized", mediaItem.filePath);
                        } else {
                            // TODO: process server-side errors (check spec)
                        }
                    } else {
                        NSLog(@"request to %@ returned error code %d", request.url, request.responseStatusCode);
                        [_errors addObject: [request responseStatusMessage]];
                    }
                }
                
                [_objectsInProgress removeObject: mediaItem];
            } else {
                NSLog(@"looks like media item upload has failed, media item [%@] will retry automatically", mediaItem.filePath );
                [_objectsInProgress removeObject: mediaItem];
//                [self performSelector: @selector(enqueueMediaItem:) withObject: mediaItem afterDelay: 31];
            }
        } else {
            // process media item removal
            NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys: 
                                     @"true", @"delete",
                                     mediaItem.objectID.URIRepresentation.absoluteString, @"internal_id",
                                     [NSNumber numberWithDouble: [mediaItem.timestamp timeIntervalSince1970]], @"timestamp",
                                     nil];
            
            NSString *json = [payload JSONRepresentation];
            NSString *deviceId = [[UIDevice currentDevice] uniqueIdentifier];
            NSString *digest = [WatcherTools md5: [[deviceId stringByAppendingString: json] stringByAppendingString: appDelegate.watcherProfile.serverSecret]];
            
            NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"http://webnabludatel.org/api/v1/media_items/%@.json?digest=%@",
                                                mediaItem.serverRecordId, digest]];
            
            [ASIFormDataRequest setShouldThrottleBandwidthForWWAN: YES];
            [ASIFormDataRequest throttleBandwidthForWWANUsingLimit: 21600];
            
            ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
            [request setRequestMethod: @"PUT"];
            [request setShouldCompressRequestBody: NO];
            [request setTimeOutSeconds: 60];
            [request setPostValue: deviceId forKey: @"device_id"];
            [request setPostValue: json forKey: @"payload"];
            [request startSynchronous];
            
            NSError *error = [request error];
            
            if ( error ) {
                NSLog(@"error removing media item from server: %@, will retry", error);
                [_errors addObject: error];
                [_objectsInProgress removeObject: mediaItem];
//                [self performSelector: @selector(enqueueMediaItem:) withObject: mediaItem afterDelay: 31];
            } else {
                if ( [request responseStatusCode] == 200 ) {
                    NSString *response = [request responseString];
                    NSDictionary *messageInfo = [response JSONValue];
                    if ( [@"ok" isEqualToString: [messageInfo objectForKey: @"status"]] ) {
                        NSDictionary *result = [messageInfo objectForKey: @"result"];
                        NSNumber *removedServerRecordId = [result objectForKey: @"media_item_id"];

                        if ( [removedServerRecordId isEqualToNumber: mediaItem.serverRecordId] ) {
                            if ( ! [[NSFileManager defaultManager] removeItemAtPath: mediaItem.filePath error: &error] )
                                NSLog(@"error removing physical file on device: %@", error.description);
                            
                            [mediaItem.managedObjectContext deleteObject: mediaItem];
                            [self performSelector: @selector(saveManagedObject:) 
                                         onThread: _dataManagerThread 
                                       withObject: mediaItem 
                                    waitUntilDone: YES];
                            
                            NSLog(@"media item [server_id=%@] was successfully removed from server and internal database", removedServerRecordId);
                        } else {
                            NSLog(@"removed server record ID %@ doesn't match stored record ID %@!!!", 
                                  removedServerRecordId, mediaItem.serverRecordId);
                        }
                        
                    } else {
                        // TODO: process server-side errors (check spec)
                    }
                } else {
                    NSLog(@"request to %@ returned error code %d", request.url, request.responseStatusCode);
                    [_errors addObject: [request responseStatusMessage]];
                }
            }
            
            [_objectsInProgress removeObject: mediaItem];
            
        }
    }
}

- (void) uploadMediaItem: (MediaItem *) mediaItem {
    @autoreleasepool {
        NSLog(@"start uploading media item [%@]", mediaItem.filePath);
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        NSDictionary *amazonSettings = [appDelegate.privateSettings objectForKey: @"amazon"];

        [ASIS3Request setSharedSecretAccessKey:[amazonSettings objectForKey: @"secret_key"]];
        [ASIS3Request setSharedAccessKey: [amazonSettings objectForKey: @"access_key"]];
        [ASIS3Request setShouldThrottleBandwidthForWWAN: YES];
        [ASIS3Request throttleBandwidthForWWANUsingLimit: 21600];
        
        ASIS3ObjectRequest *request = 
        [ASIS3ObjectRequest PUTRequestForFile: mediaItem.filePath 
                                   withBucket: @"webnabludatel-media" 
                                          key: mediaItem.amazonS3FilePath];
        
        request.mimeType        = [mediaItem.mediaType isEqualToString: (NSString *) kUTTypeImage] ? @"image/jpeg" : @"video/quicktime";
        request.timeOutSeconds  = 60;
        request.uploadProgressDelegate = self;
        
        NSLog(@"ASIS3Request upload file size: %dK", [[NSData dataWithContentsOfFile: mediaItem.filePath] length]/1024);
        
        [request startSynchronous];
        
        NSLog(@"ASIS3Request response status: %@", request.responseStatusMessage);
        
        if ([request error]) {
            NSLog(@"ASIS3Request error: %@, %@", [request error], [[request error] localizedDescription]);
            [_errors addObject: [request error]];
        } else {
            mediaItem.serverUrl = [@"http://webnabludatel-media.s3.amazonaws.com/" stringByAppendingString: mediaItem.amazonS3FilePath];
            NSLog(@"media item uploaded to server URL: %@", mediaItem.serverUrl);

            [self performSelector: @selector(saveManagedObject:) 
                         onThread: _dataManagerThread 
                       withObject: mediaItem 
                    waitUntilDone: NO];
        }
    }
}

- (void) sendDeviceRegistration {
    @autoreleasepool {
        NSLog(@"sending device registration");
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
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
                    WatcherProfile *watcherProfile = [[appDelegate executeFetchRequest: @"findProfile" 
                                                                             forEntity: @"WatcherProfile" 
                                                                           withContext: self.managedObjectContext
                                                                        withParameters: [NSDictionary dictionary]] lastObject];

                    watcherProfile.userId       = [NSString stringWithFormat: @"%@", [result objectForKey: @"user_id"]];
                    watcherProfile.serverSecret = [result objectForKey: @"secret"];
                    
                    NSLog(@"device registration completed");
                    
                    [self performSelector: @selector(saveManagedObject:) 
                                 onThread: _dataManagerThread 
                               withObject: watcherProfile 
                            waitUntilDone: NO];
                } else {
                    // TODO: process server-side errors (check spec)
                }
            }
        }
    }
}

#pragma mark - Data manager start/stop

- (void) startProcessing {
    _dataManagerThread = [[NSThread alloc] initWithTarget: self selector: @selector(runDataManager) object: nil];
    [_dataManagerThread start];
}

- (void) stopProcessing {
    [_dataManagerThread cancel];
    [_dataManagerThread release];
    _dataManagerThread = nil;
}

#pragma mark - Data manager status

- (BOOL) active {
    return ( _objectsInProgress.count > 0 );
}

- (BOOL) hasErrors {
    return ( _errors.count > 0 );
}

#pragma mark - Progress delegate

-(void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes {
//    NSLog(@"just sent %qu bytes", bytes);
}

@end
