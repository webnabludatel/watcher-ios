//
//  MWMoviePreview.m
//  ElectionsWatcher
//
//  Created by xfire on 14.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MWMoviePreview.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation MWMoviePreview

@synthesize moviePath;
@synthesize firstMovieFrame;
@synthesize mp;

+ (id) movieWithFilePath: (NSString *) aMoviePath {
    MWMoviePreview *moviePreview = [[[MWMoviePreview alloc] init] autorelease];
    moviePreview.moviePath = aMoviePath;
    
    return moviePreview;
}

-(void) dealloc {
    [moviePath release];
    [firstMovieFrame release];
    [mp release];
    
    [super dealloc];
}

- (UIImage *) underlyingImage {
    return firstMovieFrame;
}

- (void) movieHasLoaded: (NSNotification *) notification {
    if ( self.firstMovieFrame == nil ) {
        self.firstMovieFrame = [self.mp thumbnailImageAtTime:0.0 timeOption: MPMovieTimeOptionNearestKeyFrame];
        [self.mp stop];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: MWPHOTO_LOADING_DID_END_NOTIFICATION
                                                            object: self];
    }
}

- (void) loadUnderlyingImageAndNotify {
    
    self.mp = [[[MPMoviePlayerController alloc] initWithContentURL: [NSURL fileURLWithPath: self.moviePath]] autorelease];
    
    [[NSNotificationCenter defaultCenter] addObserver: self 
                                             selector: @selector(movieHasLoaded:) 
                                                 name: MPMoviePlayerLoadStateDidChangeNotification 
                                               object: mp];
    [mp prepareToPlay];
}

- (void)unloadUnderlyingImage {
    self.firstMovieFrame = nil;
}


@end
