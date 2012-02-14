//
//  MWMovieBrowser.m
//  ElectionsWatcher
//
//  Created by xfire on 14.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MWMovieBrowser.h"
#import "MWMoviePreview.h"

@implementation MWMovieBrowser

@synthesize mpv;

// FIXME: spinner gets hidden under the button
- (void)configurePage:(MWZoomingScrollView *)page forIndex:(NSUInteger)index {
    [super configurePage: page forIndex: index];
    
    UIButton *playButton = [UIButton buttonWithType: UIButtonTypeCustom];
    UIImage *buttonImage = [UIImage imageNamed: @"play_button"];
    
    [playButton setTag: index];
    [playButton setImage: buttonImage forState: UIControlStateNormal];
    [playButton setBounds: CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height)];
    [playButton setCenter: CGPointMake(page.bounds.size.width/2, page.bounds.size.height/2)];
    [playButton addTarget: self action: @selector(startPlayingMovie:) forControlEvents: UIControlEventTouchUpInside];
    
    [page addSubview: playButton];
    
}

- (void) movieHasLoaded: (NSNotification *) notification {
}

- (void) startPlayingMovie: (id) sender {
    MWMoviePreview *moviePreview = [super photoAtIndex: [sender tag]];
    
    self.mpv = [[[MPMoviePlayerViewController alloc] initWithContentURL: [NSURL fileURLWithPath: moviePreview.moviePath]] autorelease];
    [self presentMoviePlayerViewControllerAnimated: self.mpv];
}

@end
