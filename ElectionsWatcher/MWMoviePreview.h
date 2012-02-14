//
//  MWMoviePreview.h
//  ElectionsWatcher
//
//  Created by xfire on 14.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPhotoProtocol.h"
#import <MediaPlayer/MediaPlayer.h>

@interface MWMoviePreview : NSObject <MWPhoto>

@property (nonatomic, retain) NSString *moviePath;
@property (nonatomic, retain) UIImage *firstMovieFrame;
@property (nonatomic, retain) MPMoviePlayerController *mp;

+ (id) movieWithFilePath: (NSString *) moviePath;

@end
