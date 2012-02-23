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
#import <AWSiOSSDK/S3/AmazonS3Client.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "WatcherTools.h"

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
        
        [[NSNotificationCenter defaultCenter] addObserver: self 
                                                 selector: @selector(mergeContextChanges:) 
                                                     name: NSManagedObjectContextDidSaveNotification 
                                                   object: self.managedObjectContext];
        
        NSTimer *timer = [NSTimer timerWithTimeInterval: 30.0 target: self 
                                               selector: @selector(processUnsentData) 
                                               userInfo: nil 
                                                repeats: YES];
        
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

#pragma mark - Processing

- (void) processItemsSynchronously: (NSSet *) items {
    for ( id item in items ) 
        [_objectsInProgress addObject: item];
    
    for ( id item in items ) 
        if ( [item isKindOfClass: [ChecklistItem class]] )
            [self sendChecklistItem: (ChecklistItem *) item];
}

- (void) processUnsentData {
    if ( [[NSThread currentThread] isCancelled] ) {
        [NSThread exit];
    }
    
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
            
            NSLog(@"processing checklist item [%@]", checklistItem.name);
            
            NSOperation *checklistItemSendOperation = [[NSInvocationOperation alloc] initWithTarget: self 
                                                                                           selector: @selector(dequeueChecklistItem:) 
                                                                                             object: checklistItem];

            [self.uploadQueue addOperation: checklistItemSendOperation];
            [checklistItemSendOperation release];
        }
    }
    
    NSLog(@"completed processing cycle with %d items in progress", _objectsInProgress.count);
    
    [TestFlight passCheckpoint: @"Scan for modified checklist items"];
}

- (void) dequeueChecklistItem: (ChecklistItem *) checklistItem {
    [self performSelector: @selector(sendChecklistItem:) onThread: _dataManagerThread withObject: checklistItem waitUntilDone: YES];
}

#pragma mark - Send operations

- (void) registerCurrentDevice {
    [self performSelector: @selector(sendDeviceRegistration) onThread: _dataManagerThread withObject: nil waitUntilDone: NO];
}

- (void) sendChecklistItem: (ChecklistItem *) checklistItem {
    [_objectsInProgress addObject: checklistItem];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
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
    NSString *digest = [WatcherTools md5: [[deviceId stringByAppendingString: json] stringByAppendingString: appDelegate.watcherProfile.serverSecret]];
    
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
    
    for ( MediaItem *mediaItem in checklistItem.mediaItems )
        [self sendMediaItem: mediaItem];
    
    NSLog(@"checklist item [%@] successfully synchronized", checklistItem.name);
    
    [_objectsInProgress removeObject: checklistItem];
    [appDelegate performSelectorOnMainThread: @selector(hideNetworkActivity) withObject: nil waitUntilDone: NO];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
}

- (void) sendMediaItem: (MediaItem *) mediaItem {
    [_objectsInProgress addObject: mediaItem];
    
    if ( ! mediaItem.serverUrl ) 
        [self uploadMediaItem: mediaItem];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
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
}

- (void) uploadMediaItem: (MediaItem *) mediaItem {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSDictionary *amazonSettings = [appDelegate.privateSettings objectForKey: @"amazon"];
    
    AmazonS3Client *s3Client = [[AmazonS3Client alloc] initWithAccessKey: [amazonSettings objectForKey: @"access_key"]
                                                           withSecretKey: [amazonSettings objectForKey: @"secret_key"]];

    @try {
        S3PutObjectRequest *putRequest = [[S3PutObjectRequest alloc] initWithKey: [mediaItem.filePath lastPathComponent] 
                                                                        inBucket: @"webnabludatel-media"];
        
        putRequest.contentType = [mediaItem.mediaType isEqualToString: (NSString *) kUTTypeImage] ? @"image/jpeg" : @"video/quicktime";
        putRequest.data = [NSData dataWithContentsOfFile: mediaItem.filePath];
        
        S3Response *response = [s3Client putObject: putRequest];
        NSLog(@"Amazon response token: %@", response.id2);
        mediaItem.serverUrl = [@"http://webnabludatel-media.s3.amazonaws.com/" stringByAppendingString: [mediaItem.filePath lastPathComponent]];
        NSLog(@"media item saved to server URL: %@", mediaItem.serverUrl);
        
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
}

- (void) sendDeviceRegistration {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread: @selector(showNetworkActivity) withObject: nil waitUntilDone: NO];
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
    
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
    [appDelegate performSelectorOnMainThread: @selector(updateSynchronizationStatus) withObject: nil waitUntilDone: NO];
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
