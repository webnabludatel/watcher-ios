//
//  MWMovieBrowser.h
//  ElectionsWatcher
//
//  Created by xfire on 14.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPhotoBrowser.h"
#import "MWZoomingScrollView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface MWMovieBrowser : MWPhotoBrowser

@property (nonatomic, retain) MPMoviePlayerViewController *mpv;

- (void)configurePage:(MWZoomingScrollView *)page forIndex:(NSUInteger)index;

@end
