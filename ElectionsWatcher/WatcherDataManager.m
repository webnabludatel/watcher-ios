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

@implementation WatcherDataManager

@synthesize dataManagerThread = _dataManagerThread;
@synthesize uploadQueue = _uploadQueue;

-(void)dealloc {
    [_dataManagerThread release];
    [_uploadQueue release];
    
    [super dealloc];
}

- (void) runDataManager {
    @autoreleasepool {
        NSTimer *timer = [NSTimer timerWithTimeInterval: 10.0 target: self 
                                               selector: @selector(checkForUnsentData) 
                                               userInfo: nil 
                                                repeats: YES];
        
        [[NSRunLoop currentRunLoop] addTimer: timer forMode: NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void) checkForUnsentData {
    if ( [[NSThread currentThread] isCancelled] )
        [NSThread exit];
    
    NSLog(@"start checking for non-synchronized items");
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    NSArray *unsentItems = [appDelegate executeFetchRequest: @"findUnsentChecklistItems" 
                                                  forEntity: @"ChecklistItem" 
                                             withParameters: [NSDictionary dictionary]];
    
    if ( unsentItems.count ) {
        [_uploadQueue release]; _uploadQueue = nil;
        _uploadQueue = [[NSOperationQueue alloc] init];
        
        for ( ChecklistItem *checklistItem in unsentItems ) {
            if ( checklistItem.isInserted || checklistItem.isUpdated ) 
                continue;
            
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
        
        [self.uploadQueue waitUntilAllOperationsAreFinished];
    }
}

- (void) sendChecklistItem: (ChecklistItem *) checklistItem {
    NSLog(@"sending checklist item [%@]", checklistItem.name);
}

- (void) sendMediaItem: (MediaItem *) mediaItem {
    NSLog(@"sending checklist item [%@] media: %@", mediaItem.checklistItem.name, mediaItem.filePath);
}

- (void) uploadMediaItem: (MediaItem *) mediaItem {
    NSLog(@"uploadn checklist item [%@] media: %@", mediaItem.checklistItem.name, mediaItem.filePath);
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

@end
