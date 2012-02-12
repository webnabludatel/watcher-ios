//
//  WatcherSettingsCell.m
//  ElectionsWatcher
//
//  Created by xfire on 11.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <MobileCoreServices/UTCoreTypes.h>
#import "WatcherSettingsCell.h"
#import "traverseresponderchain.m"

@implementation WatcherSettingsCell

@synthesize itemInfo;

- (void) saveItem {
    switch ( [[self.itemInfo objectForKey: @"control"] intValue] ) {
        case INPUT_TEXT:
        case INPUT_NUMBER:
        case INPUT_EMAIL:
        case INPUT_CONSTANT:
        case INPUT_DROPDOWN: {
            UITextField *textField = (UITextField *) self.control;
            [self.itemInfo setObject: textField.text forKey: @"value"];
        }
            break;
        case INPUT_SWITCH: {
            UISlider *slider = (UISlider *) self.control;
            NSDictionary *switchOptions = [self.itemInfo objectForKey: @"switch_options"];
            switch ( (int) slider.value ) {
                case -1:
                    [self.itemInfo setObject: [switchOptions objectForKey: @"lo_value"] forKey: @"value"];
                    break;
                case 0:
                    [self.itemInfo setObject: nil forKey: @"value"];
                    break;
                case +1:
                    [self.itemInfo setObject: [switchOptions objectForKey: @"hi_value"] forKey: @"value"];
                    break;
            }
        }
            break;
        case INPUT_PHOTO:
        case INPUT_VIDEO:
        case INPUT_COMMENT:
            break;
    }
    
    UIViewController *parentController = [self firstAvailableUIViewController];
    if ( [parentController respondsToSelector: @selector(saveSettings)] )
        [parentController performSelector: @selector(saveSettings)];
}

- (void) loadItem {
    switch ( [[self.itemInfo objectForKey: @"control"] intValue] ) {
        case INPUT_TEXT:
        case INPUT_EMAIL:
        case INPUT_CONSTANT:
        case INPUT_NUMBER:
        case INPUT_DROPDOWN: {
            UITextField *textField = (UITextField *) self.control;
            textField.text = [self.itemInfo objectForKey: @"value"];
        }
            break;
            
        case INPUT_SWITCH: {
            UISlider *slider = (UISlider *) self.control;
            NSDictionary *switchOptions = [self.itemInfo objectForKey: @"switch_options"];
            if ( [[switchOptions objectForKey: @"lo_value"] isEqualToString: [self.itemInfo objectForKey: @"value"]] )
                slider.value = -1;
            else if ( [[switchOptions objectForKey: @"hi_value"] isEqualToString: [self.itemInfo objectForKey: @"value"]] )
                slider.value = +1;
            else
                slider.value = 0;
        }
            break;
            
        case INPUT_PHOTO: {
            if ( [[self mediaItemsOfType: (NSString *) kUTTypeImage] count] ) {
                UIButton *button = (UIButton *) self.control;
                [button setTitle: [NSString stringWithFormat: @"Фото (%d)", [[self mediaItemsOfType: (NSString *) kUTTypeImage] count]] 
                        forState: UIControlStateNormal];
            }
            
        }
            break;
            
        case INPUT_VIDEO: {
            if ( [[self mediaItemsOfType: (NSString *) kUTTypeMovie] count] ) {
                UIButton *button = (UIButton *) self.control;
                [button setTitle: [NSString stringWithFormat: @"Видео (%d)", [[self mediaItemsOfType: (NSString *) kUTTypeMovie] count]] 
                        forState: UIControlStateNormal];
            }
        }
            break;
            
        case INPUT_COMMENT:
            break;
    }
}

- (NSArray *) mediaItemsOfType: (NSString *) mediaType {
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"SELF.mediaType LIKE %@", mediaType];
    return [[self.itemInfo objectForKey: @"media_items"] filteredArrayUsingPredicate: predicate];
}

- (void) imagePickerController: (UIImagePickerController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info {
    // save checklist item before adding media, otherwise it doesn't work
    [self saveItem];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *docsDirectory = [NSSearchPathForDirectoriesInDomains ( NSDocumentDirectory, NSUserDomainMask, YES ) lastObject];
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    NSMutableDictionary *mediaItem = [NSMutableDictionary dictionary];
    
    // Handle a still image capture
    if ( CFStringCompare ( (CFStringRef) mediaType, kUTTypeImage, 0 ) == kCFCompareEqualTo ) {
        UIImage *originalImage = (UIImage *) [info objectForKey: UIImagePickerControllerOriginalImage];
        NSString *photosDirectory = [docsDirectory stringByAppendingPathComponent: @"Photos"];
        NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *imageFilename = [NSString stringWithFormat: @"%d.png", fabs(currentTimestamp) * 1000]; 
        NSString *imageFilepath = [photosDirectory stringByAppendingPathComponent: imageFilename];
        
        UIImageWriteToSavedPhotosAlbum (originalImage, nil, nil , nil);
        
        if ( ! [fm fileExistsAtPath: photosDirectory] )
            [fm createDirectoryAtPath: photosDirectory withIntermediateDirectories: YES 
                           attributes: nil 
                                error: nil];
        
        [UIImagePNGRepresentation(originalImage) writeToFile: imageFilepath atomically: YES];
        
        [mediaItem setObject: mediaType forKey: @"mediaType"];
        [mediaItem setObject: imageFilepath forKey: @"fileName"];
    }   
    
    // Handle a movie capture
    if ( CFStringCompare ( (CFStringRef) mediaType, kUTTypeMovie, 0 ) == kCFCompareEqualTo ) {
        NSString *moviePath = [[info objectForKey: UIImagePickerControllerMediaURL] path];
        NSString *videosDirectory = [docsDirectory stringByAppendingPathComponent: @"Videos"];
        NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *videoFilename = [NSString stringWithFormat: @"%d.mov", fabs(currentTimestamp) * 1000];
        NSString *videoFilepath = [videosDirectory stringByAppendingPathComponent: videoFilename];
        
        if ( ! [fm fileExistsAtPath: videosDirectory] )
            [fm createDirectoryAtPath: videosDirectory withIntermediateDirectories: YES 
                           attributes: nil 
                                error: nil];
        
        if ( UIVideoAtPathIsCompatibleWithSavedPhotosAlbum ( moviePath ) ) {
            UISaveVideoAtPathToSavedPhotosAlbum ( moviePath, nil, nil, nil );
        }
        
        [fm copyItemAtPath: moviePath toPath: videoFilepath error: nil];
        
        [mediaItem setObject: mediaType forKey: @"mediaType"];
        [mediaItem setObject: videoFilepath forKey: @"fileName"];
    }

    NSMutableArray *mediaItems = nil;
    
    if ( [self.itemInfo objectForKey: @"media_items"] ) {
        mediaItems = [self.itemInfo objectForKey: @"media_items"];
    } else {
        mediaItems = [NSMutableArray array];
        [self.itemInfo setObject: mediaItems forKey: @"media_items"];
    }
    
    [mediaItems addObject: mediaItem];
    [self saveItem];
    
    UIViewController *parentController = [self firstAvailableUIViewController];
    [parentController dismissModalViewControllerAnimated: YES];
    [picker release];
    
    [self setNeedsLayout];
}
@end
