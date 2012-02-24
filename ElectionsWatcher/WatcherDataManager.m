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
#import <AWSiOSSDK/S3/AmazonS3Client.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "WatcherTools.h"
#import "Reachability.h"

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
        
        [[NSNotificationCenter defaultCenter] addObserver: self 
                                                 selector: @selector(processUnsentMediaItems) 
                                                     name: kReachabilityChangedNotification 
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self 
                                                 selector: @selector(mergeContextChanges:) 
                                                     name: NSManagedObjectContextDidSaveNotification 
                                                   object: self.managedObjectContext];
        
        NSTimer *timer = [NSTimer timerWithTimeInterval: 37.0 target: self 
                                               selector: @selector(processUnsentData) 
                                               userInfo: nil 
                                                repeats: YES];
        
        NSTimer *wifiCheck = [NSTimer timerWithTimeInterval: 43.0 target: self 
                                                   selector: @selector(processUnsentMediaItems) 
                                                   userInfo: nil 
                                                    repeats: YES];
        
        [[NSRunLoop currentRunLoop] addTimer: timer forMode: NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] addTimer: wifiCheck forMode: NSRunLoopCommonModes];
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

#pragma mark - Processing

- (void) processUnsentMediaItems {
    if ( [[NSThread currentThread] isCancelled] ) {
        [NSThread exit];
    }

    @autoreleasepool {
        if ( _wifiReachability.currentReachabilityStatus > 0 && ! _wifiReachability.connectionRequired ) {
            AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
            NSArray *unsentItems = [appDelegate executeFetchRequest: @"findUnsentMediaItems" 
                                                          forEntity: @"MediaItem" 
                                                        withContext: self.managedObjectContext
                                                     withParameters: [NSDictionary dictionary]];
            
            NSLog(@"enqueue %d unsent media items", unsentItems.count);
            
            for ( MediaItem *mediaItem in unsentItems ) {
                if ( [_objectsInProgress containsObject: mediaItem] )
                    continue;
                
                [self enqueueMediaItem: mediaItem];
            }
        }
    }
}

- (void) processUnsentData {
    if ( [[NSThread currentThread] isCancelled] ) {
        [NSThread exit];
    }
    
    @autoreleasepool {
        [_errors removeAllObjects];
        
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
                    
                    if ( [mediaItem.mediaType isEqualToString: (NSString *) kUTTypeMovie] ) {
                        if ( _wifiReachability.currentReachabilityStatus == 0 ) {
                            NSLog(@"media item [%@] will be uploaded only when WiFi becomes available", mediaItem.filePath);
                            continue;
                        }
                    }
                    
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
    [self performSelector: @selector(sendChecklistItem:) onThread: _dataManagerThread withObject: checklistItem waitUntilDone: YES];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
}

- (void) dequeueMediaItem: (MediaItem *) mediaItem {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
    [self performSelector: @selector(sendMediaItem:) onThread: _dataManagerThread withObject: mediaItem waitUntilDone: YES];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
}

- (void) dequeueMediaItemUpload: (MediaItem *) mediaItem {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
    [self performSelector: @selector(uploadMediaItem:) onThread: _dataManagerThread withObject: mediaItem waitUntilDone: YES];
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
                                 checklistItem.pollingPlace.nameOrNumber, @"polling_place_id",
                                 checklistItem.pollingPlace.region, @"polling_place_region",
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
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
        if ( [checklistItem.serverRecordId doubleValue] > 0 ) [request setRequestMethod: @"PUT"];
        [request setPostValue: deviceId forKey: @"device_id"];
        [request setPostValue: json forKey: @"payload"];
        [appDelegate performSelectorOnMainThread: @selector(showNetworkActivity) withObject: nil waitUntilDone: NO];
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
                    
                    if ( checklistItem.managedObjectContext == self.managedObjectContext ) {
                        [self.managedObjectContext refreshObject: checklistItem mergeChanges: YES];
                        [self saveManagedObjectContext];
                    } else {
                        [checklistItem.managedObjectContext save: &error];
                        if ( error )
                            NSLog(@"error saving checklist item: %@", error.description);
                    }
                } else {
                    // TODO: process server-side errors (check spec)
                }
            } else {
                NSLog(@"http request status: %d", [request responseStatusCode]);
            }
        }
        
        NSLog(@"checklist item [%@] successfully synchronized", checklistItem.name);
        
        [_objectsInProgress removeObject: checklistItem];
        [appDelegate performSelectorOnMainThread: @selector(hideNetworkActivity) withObject: nil waitUntilDone: NO];
    }
}

- (void) sendMediaItem: (MediaItem *) mediaItem {
    @autoreleasepool {
        NSLog(@"processing media item [%@]", mediaItem.filePath);
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        if ( mediaItem.serverUrl ) {
            
            NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys: 
                                     mediaItem.serverUrl, @"url", 
                                     mediaItem.mediaType, @"type",
                                     [NSNumber numberWithDouble: [mediaItem.timestamp timeIntervalSince1970]], @"timestamp",
                                     nil];
            
            NSString *json = [payload JSONRepresentation];
            NSString *deviceId = [[UIDevice currentDevice] uniqueIdentifier];
            NSString *digest = [WatcherTools md5: [[deviceId stringByAppendingString: json] stringByAppendingString: appDelegate.watcherProfile.serverSecret]];
            
            NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"http://webnabludatel.org/api/v1/messages/%@/media_items.json?digest=%@", 
                                                mediaItem.checklistItem.serverRecordId, digest]];
            ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
            [request setPostValue: deviceId forKey: @"device_id"];
            [request setPostValue: json forKey: @"payload"];
            [appDelegate performSelectorOnMainThread: @selector(showNetworkActivity) withObject: nil waitUntilDone: NO];
            [request startSynchronous];
            
            NSError *error = [request error];
            
            if ( error ) {
                NSLog(@"error sending media item: %@", error);
                [_errors addObject: error];
                
                [_objectsInProgress removeObject: mediaItem];
                NSLog(@"retrying media item [%@]", mediaItem.filePath);
                [self enqueueMediaItem: mediaItem];
            } else {
                if ( [request responseStatusCode] == 200 ) {
                    NSString *response = [request responseString];
                    NSDictionary *messageInfo = [response JSONValue];
                    if ( [@"ok" isEqualToString: [messageInfo objectForKey: @"status"]] ) {
                        NSDictionary *result = [messageInfo objectForKey: @"result"];
                        mediaItem.serverRecordId = [result objectForKey: @"media_item_id"];
                        mediaItem.synchronized = [NSNumber numberWithBool: YES];
                        
                        if ( mediaItem.managedObjectContext == self.managedObjectContext ) {
                            [self.managedObjectContext refreshObject: mediaItem mergeChanges: YES];
                            [self saveManagedObjectContext];
                        } else {
                            [mediaItem.managedObjectContext save: &error];
                            if ( error )
                                NSLog(@"error saving media item: %@", error.description);
                        }
                        
                        NSLog(@"media item [%@] successfully synchronized", mediaItem.filePath);
                    } else {
                        // TODO: process server-side errors (check spec)
                    }
                } else {
                    NSLog(@"http request status: %d", [request responseStatusCode]);
                }
            }
            
            [_objectsInProgress removeObject: mediaItem];
        } else {
            NSLog(@"looks like media item upload has failed, re-trying media item [%@]", mediaItem.filePath );
            [_objectsInProgress removeObject: mediaItem];
            [self enqueueMediaItem: mediaItem];
        }
        
        [appDelegate performSelectorOnMainThread: @selector(hideNetworkActivity) withObject: nil waitUntilDone: NO];
    }
}

- (void) uploadMediaItem: (MediaItem *) mediaItem {
    @autoreleasepool {
        NSLog(@"start uploading media item [%@]", mediaItem.filePath);
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        NSDictionary *amazonSettings = [appDelegate.privateSettings objectForKey: @"amazon"];
        
        AmazonS3Client *s3Client = [[AmazonS3Client alloc] initWithAccessKey: [amazonSettings objectForKey: @"access_key"]
                                                               withSecretKey: [amazonSettings objectForKey: @"secret_key"]];

        @try {
            NSData *fileData = [NSData dataWithContentsOfFile: mediaItem.filePath];
            
            if ( fileData.length > 10 * 1024 * 1024 ) {
                S3MultipartUpload *multipartUpload = [s3Client initiateMultipartUploadWithKey: [mediaItem.filePath lastPathComponent] 
                                                                                   withBucket: @"webnabludatel-media"];
                
                S3CompleteMultipartUploadRequest *completeUploadRequest = [[S3CompleteMultipartUploadRequest alloc] 
                                                                           initWithMultipartUpload: multipartUpload];
                static NSUInteger kBufferSize = 5 * 1024 * 1024; NSUInteger counter = 1;
                
                for ( NSUInteger pos = 0; pos < fileData.length; pos += kBufferSize ) {
                    NSLog(@"upload position=%d, part=%d", pos, counter);
                    NSUInteger length = pos + kBufferSize > fileData.length ? fileData.length - pos : kBufferSize;
                    NSData *fragmentData = [fileData subdataWithRange: NSMakeRange(pos, length)];
                    
                    S3UploadPartRequest *uploadPartRequest = [[S3UploadPartRequest alloc] initWithMultipartUpload: multipartUpload];
                    uploadPartRequest.partNumber = counter;
                    uploadPartRequest.data = fragmentData;
                    
                    [appDelegate performSelectorOnMainThread: @selector(showNetworkActivity) withObject: nil waitUntilDone: NO];
                    S3UploadPartResponse *partResponse = [s3Client uploadPart: uploadPartRequest];
                    NSLog(@"amazon response token to part upload: %@", partResponse.id2);
                    [uploadPartRequest release];
                    
                    [completeUploadRequest addPartWithPartNumber: counter withETag: partResponse.etag];
                    
                    counter++;
                }
                
                S3CompleteMultipartUploadResponse *completeUploadResponse = [s3Client completeMultipartUpload: completeUploadRequest];
                NSLog(@"amazon response token to complete upload: %@", completeUploadResponse.id2);
            } else {
                S3PutObjectRequest *putRequest = [[S3PutObjectRequest alloc] initWithKey: [mediaItem.filePath lastPathComponent] 
                                                                                inBucket: @"webnabludatel-media"];
                
                putRequest.contentType = [mediaItem.mediaType isEqualToString: (NSString *) kUTTypeImage] ? @"image/jpeg" : @"video/quicktime";
                putRequest.data = [NSData dataWithContentsOfFile: mediaItem.filePath];
                
                [appDelegate performSelectorOnMainThread: @selector(showNetworkActivity) withObject: nil waitUntilDone: NO];
                S3Response *response = [s3Client putObject: putRequest];
                NSLog(@"amazon response token: %@", response.id2);
            }
            
            mediaItem.serverUrl = [@"http://webnabludatel-media.s3.amazonaws.com/" stringByAppendingString: [mediaItem.filePath lastPathComponent]];
            NSLog(@"media item uploaded to server URL: %@", mediaItem.serverUrl);
            
            if ( mediaItem.managedObjectContext == self.managedObjectContext ) {
                [self.managedObjectContext refreshObject: mediaItem mergeChanges: YES];
                [self saveManagedObjectContext];
            } else {
                NSError *error = nil;
                [mediaItem.managedObjectContext save: &error];
                if ( error )
                    NSLog(@"error saving media item: %@", error.description);
            }
        }
        @catch ( AmazonClientException *e ) {
            NSLog(@"Amazon client error: %@", e.message);
            [_errors addObject: e];
        }
        
        [appDelegate performSelectorOnMainThread: @selector(hideNetworkActivity) withObject: nil waitUntilDone: NO];
    }
}

- (void) sendDeviceRegistration {
    @autoreleasepool {
        NSLog(@"sending device registration");
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        NSURL *url = [NSURL URLWithString: @"http://webnabludatel.org/api/v1/authentications.json"];
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL: url];
        [request setPostValue: [[UIDevice currentDevice] uniqueIdentifier] forKey: @"device_id"];
        [appDelegate performSelectorOnMainThread: @selector(showNetworkActivity) withObject: nil waitUntilDone: NO];
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
                    
                    if ( watcherProfile.managedObjectContext == self.managedObjectContext ) {
                        [self.managedObjectContext refreshObject: watcherProfile mergeChanges: YES];
                        [self saveManagedObjectContext];
                    } else {
                        [watcherProfile.managedObjectContext save: &error];
                        if ( error ) 
                            NSLog(@"error updating profile: %@", error.description);
                    }
                } else {
                    // TODO: process server-side errors (check spec)
                }
            }
        }
        
        [appDelegate performSelectorOnMainThread: @selector(hideNetworkActivity) withObject: nil waitUntilDone: NO];
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

@end
