//
//  WatcherChecklistScreenCell.m
//  ElectionsWatcher
//
//  Created by xfire on 22.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherChecklistScreenCell.h"
#import "ActionSheetPicker.h"
#include <objc/runtime.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "traverseresponderchain.m"
#import "AppDelegate.h"
#import "ChecklistItem.h"
#import "MediaItem.h"
#import "MWPhotoBrowser.h"
#import "MWMoviePreview.h"
#import "MWMovieBrowser.h"

@implementation WatcherChecklistScreenCell

@synthesize itemInfo;
@synthesize control;
@synthesize itemLabel;
@synthesize checklistItem;
@synthesize sectionIndex;
@synthesize screenIndex;
@synthesize mwBrowserItems;
@synthesize saveDelegate;
@synthesize checklistCellDelegate;
@synthesize HUD;

#pragma mark -
#pragma mark Cell implementation

- (id) initWithStyle: (UITableViewCellStyle) style reuseIdentifier: (NSString *) reuseIdentifier withItemInfo: (NSDictionary *) anItemInfo {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if ( self ) {
        self.itemInfo = anItemInfo;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.itemLabel = [[[UILabel alloc] init] autorelease];
        self.itemLabel.font = [UIFont boldSystemFontOfSize: 13];
        self.itemLabel.numberOfLines = 0;
        self.itemLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.itemLabel.backgroundColor = [UIColor clearColor];
        self.itemLabel.textColor = [UIColor darkTextColor];
        self.itemLabel.text = [[self.itemInfo objectForKey: @"required"] boolValue] ?
            [[self.itemInfo objectForKey: @"title"] stringByAppendingString: @" (*)"] :
            [self.itemInfo objectForKey: @"title"] ;
        
        self.sectionIndex   = -1;
        self.screenIndex    = -1;
        
        int controlType = [[self.itemInfo objectForKey: @"control"] intValue];

        switch ( controlType ) {
            
            case INPUT_TEXT: 
            case INPUT_EMAIL:
            case INPUT_CONSTANT:
            {
                self.control = [[[UITextField alloc] init] autorelease];
                
                UITextField *textField = (UITextField *) self.control;
                textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                textField.keyboardType = ( controlType == INPUT_EMAIL ) ? UIKeyboardTypeEmailAddress : UIKeyboardTypeDefault;
                textField.returnKeyType = UIReturnKeyDone;
                textField.placeholder = [self.itemInfo objectForKey: @"hint"];
                textField.delegate = self;
                textField.font = [UIFont systemFontOfSize: 14];
                
                if ( controlType == INPUT_CONSTANT ) 
                    textField.userInteractionEnabled = NO;
            }
                break;
                
            case INPUT_NUMBER: {
                self.control = [[[UITextField alloc] init] autorelease];
                
                UITextField *textField = (UITextField *) self.control;
                textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                textField.returnKeyType = UIReturnKeyDone;
                textField.placeholder = [self.itemInfo objectForKey: @"hint"];
                textField.delegate = self;
                textField.font = [UIFont systemFontOfSize: 14];
                
            }
                break;

            case INPUT_DROPDOWN: {
                self.control = [[[UITextField alloc] init] autorelease];
                
                UITextField *textField = (UITextField *) self.control;
                textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                textField.keyboardType = UIKeyboardTypeDefault;
                textField.returnKeyType = UIReturnKeyDone;
                textField.placeholder = [self.itemInfo objectForKey: @"hint"];
                textField.delegate = self;
                textField.font = [UIFont systemFontOfSize: 14];
            }
                break;
                
            case INPUT_SWITCH: {
                self.control = [[[UISlider alloc] init] autorelease];
                
                UISlider *slider = (UISlider *) self.control;
                slider.minimumValue = -1;
                slider.maximumValue = +1;
                slider.continuous = NO;
                slider.value = 0;
                
                NSDictionary *switchOptions = [self.itemInfo objectForKey: @"switch_options"];
                slider.minimumValueImage = [self imageFromText: [switchOptions objectForKey: @"lo_text"]];
                slider.maximumValueImage = [self imageFromText: [switchOptions objectForKey: @"hi_text"]];
                
                [slider setMinimumTrackImage: [[UIImage imageNamed: @"slider_neutral"] stretchableImageWithLeftCapWidth: 52 topCapHeight: 0]
                                    forState: UIControlStateNormal];
                
                [slider setMaximumTrackImage: [[UIImage imageNamed: @"slider_neutral"] stretchableImageWithLeftCapWidth: 62 topCapHeight: 0]
                                    forState: UIControlStateNormal];
                
                [slider setThumbImage: [UIImage imageNamed: @"slider_thumb"] forState: UIControlStateNormal];
                
                [slider addTarget: self 
                           action: @selector(snapSliderToValue:) 
                 forControlEvents: UIControlEventValueChanged];
            }
                break;
                
            case INPUT_PHOTO: {
                // TODO: use hint attribute
                self.control = [UIButton buttonWithType: UIButtonTypeRoundedRect];
                
                UIButton *button = (UIButton *) self.control;
                [button setTitle: [self.itemInfo objectForKey: @"hint"] forState: UIControlStateNormal];
                [button addTarget: self action: @selector(takePhoto:) forControlEvents: UIControlEventTouchUpInside];
            }
                break;
                
            case INPUT_VIDEO: {
                self.control = [UIButton buttonWithType: UIButtonTypeRoundedRect];
                
                UIButton *button = (UIButton *) self.control;
                [button setTitle: [self.itemInfo objectForKey: @"hint"] forState: UIControlStateNormal];
                [button addTarget: self action: @selector(takeVideo:) forControlEvents: UIControlEventTouchUpInside];
            }
                break;
                
            case INPUT_COMMENT: {
                self.control = [[[UITextView alloc] init] autorelease];
                
                UITextView *textView = (UITextView *) self.control;
                textView.keyboardType = UIKeyboardTypeDefault;
                textView.backgroundColor = [UIColor clearColor];
                textView.delegate = self;
                
                UIToolbar *saveTextToolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0, 0, self.frame.size.width, 50)];
                
                UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel 
                                                                                            target: self 
                                                                                            action: @selector(cancelTextView)];
                
                UIBarButtonItem *updateItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone 
                                                                                            target: self 
                                                                                            action: @selector(saveTextView)];
                
                UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace 
                                                                                        target: nil
                                                                                        action: nil];
                
                [saveTextToolbar setTintColor: [UIColor blackColor]];
                [saveTextToolbar setItems: [NSArray arrayWithObjects: cancelItem, spacer, updateItem, nil]];
                
                textView.inputAccessoryView = saveTextToolbar;
                
                [spacer release];
                [cancelItem release];
                [updateItem release];
                [saveTextToolbar release];
            }
                break;
                
            default:
                @throw [NSException exceptionWithName: NSInvalidArgumentException 
                                               reason: @"invalid control type in plist" 
                                             userInfo: nil]; 
                break;
        }
        
        [self.contentView addSubview: self.itemLabel];
        [self.contentView addSubview: self.control];
    }
    
    return self;
}


- (void) layoutSubviews {
    [super layoutSubviews];
    
    if ( self.itemInfo ) {
        CGRect labelFrame, controlArea, controlFrame, timestampFrame;
        NSString *itemTitle = [self.itemInfo objectForKey: @"title"];
        
        if ( itemTitle.length ) {
            CGSize labelSize = [itemTitle sizeWithFont: [UIFont boldSystemFontOfSize: 13] 
                                     constrainedToSize: CGSizeMake(280, 120) 
                                         lineBreakMode: UILineBreakModeWordWrap];
            CGRectDivide(CGRectInset(self.contentView.bounds, 10, 10), &labelFrame, &controlArea, labelSize.height, CGRectMinYEdge);
            CGRectDivide(controlArea, &timestampFrame, &controlFrame, controlArea.size.width/3.0f, CGRectMinXEdge);
            
            self.itemLabel.frame = labelFrame;
            self.control.frame   = ( [[self.itemInfo objectForKey: @"control"] intValue] == INPUT_SWITCH ) ?
                CGRectMake(controlFrame.origin.x, controlFrame.origin.y+10, controlFrame.size.width, controlFrame.size.height-10) :
                CGRectMake(controlArea.origin.x, controlArea.origin.y+10, controlArea.size.width, controlArea.size.height-10);
        } else {
            self.control.frame = CGRectInset(self.contentView.bounds, 10, 10);
        }
        
        
        [self loadItem];
    }
}

#pragma mark -
#pragma mark Handling item save/restore

- (void) loadItem {
    switch ( [[self.itemInfo objectForKey: @"control"] intValue] ) {
        case INPUT_TEXT:
        case INPUT_EMAIL:
        case INPUT_NUMBER:
        case INPUT_CONSTANT:
        case INPUT_DROPDOWN: {
            UITextField *textField = (UITextField *) self.control;
            textField.text = self.checklistItem.value;
            
            if ( [[self.itemInfo objectForKey: @"control"] intValue] == INPUT_CONSTANT )
                [self saveItem];
        }
            break;
            
        case INPUT_SWITCH: {
            UISlider *slider = (UISlider *) self.control;
            NSDictionary *switchOptions = [self.itemInfo objectForKey: @"switch_options"];
            if ( [[switchOptions objectForKey: @"lo_value"] isEqualToString: self.checklistItem.value] ) {
                slider.value = -1;
                
                [slider setMinimumTrackImage: [[UIImage imageNamed: @"slider_bad"] stretchableImageWithLeftCapWidth: 52 topCapHeight: 0]
                                    forState: UIControlStateNormal];
                [slider setMaximumTrackImage: [[UIImage imageNamed: @"slider_good"] stretchableImageWithLeftCapWidth: 62 topCapHeight: 0]
                                    forState: UIControlStateNormal];
            } else if ( [[switchOptions objectForKey: @"hi_value"] isEqualToString: self.checklistItem.value] ) {
                slider.value = +1;
                
                [slider setMinimumTrackImage: [[UIImage imageNamed: @"slider_bad"] stretchableImageWithLeftCapWidth: 52 topCapHeight: 0]
                                    forState: UIControlStateNormal];
                [slider setMaximumTrackImage: [[UIImage imageNamed: @"slider_good"] stretchableImageWithLeftCapWidth: 62 topCapHeight: 0]
                                    forState: UIControlStateNormal];
            } else {
                slider.value = 0;
                
                [slider setMinimumTrackImage: [[UIImage imageNamed: @"slider_neutral"] stretchableImageWithLeftCapWidth: 52 topCapHeight: 0]
                                    forState: UIControlStateNormal];
                [slider setMaximumTrackImage: [[UIImage imageNamed: @"slider_neutral"] stretchableImageWithLeftCapWidth: 62 topCapHeight: 0]
                                    forState: UIControlStateNormal];
            }
        }
            break;
            
        case INPUT_PHOTO: {
            UIButton *button = (UIButton *) self.control;
            if ( [[self mediaItemsOfType: (NSString *) kUTTypeImage] count] ) {
                [button setTitle: [NSString stringWithFormat: @"%@ (%d)", [self.itemInfo objectForKey: @"hint"], 
                                   [[self mediaItemsOfType: (NSString *) kUTTypeImage] count]] 
                        forState: UIControlStateNormal];
            } else {
                [button setTitle: [self.itemInfo objectForKey: @"hint"] forState: UIControlStateNormal];
            }
            
        }
            break;
            
        case INPUT_VIDEO: {
            UIButton *button = (UIButton *) self.control;
            if ( [[self mediaItemsOfType: (NSString *) kUTTypeMovie] count] ) {
                [button setTitle: [NSString stringWithFormat: @"%@ (%d)", [self.itemInfo objectForKey: @"hint"], 
                                   [[self mediaItemsOfType: (NSString *) kUTTypeMovie] count]] 
                        forState: UIControlStateNormal];
            } else {
                [button setTitle: [self.itemInfo objectForKey: @"hint"] forState: UIControlStateNormal];
            }
        }
            break;
            
        case INPUT_COMMENT: {
            UITextView *textView = (UITextView *) self.control;
            textView.text = self.checklistItem.value;
            
        }
            break;
    }
}

- (void) saveItem {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    self.checklistItem.name = [self.itemInfo objectForKey: @"name"];
    self.checklistItem.sectionIndex = [NSNumber numberWithInt: self.sectionIndex];
    self.checklistItem.screenIndex = [NSNumber numberWithInt: self.screenIndex];
    
    self.checklistItem.lat = [NSNumber numberWithDouble: appDelegate.currentLocation.coordinate.latitude];
    self.checklistItem.lng = [NSNumber numberWithDouble: appDelegate.currentLocation.coordinate.longitude];
    self.checklistItem.timestamp = [NSDate date];
    self.checklistItem.synchronized = [NSNumber numberWithBool: NO];
    
    switch ( [[self.itemInfo objectForKey: @"control"] intValue] ) {
        case INPUT_CONSTANT:
            self.checklistItem.synchronized = [NSNumber numberWithBool: YES]; // never synchronize constant items
            break;
        case INPUT_TEXT:
        case INPUT_EMAIL:
        case INPUT_NUMBER:
        case INPUT_DROPDOWN: {
            UITextField *textField = (UITextField *) self.control;
            self.checklistItem.value = textField.text;
            self.checklistItem.violationFlag = nil;
        }
            break;
        case INPUT_SWITCH: {
            UISlider *slider = (UISlider *) self.control;
            NSDictionary *switchOptions = [self.itemInfo objectForKey: @"switch_options"];
            switch ( (int) slider.value ) {
                case -1:
                    self.checklistItem.value = [switchOptions objectForKey: @"lo_value"];
                    self.checklistItem.violationFlag = [NSNumber numberWithInt: 0];
                    break;
                case 0:
                    self.checklistItem.value = nil;
                    self.checklistItem.violationFlag = nil;
                    break;
                case +1:
                    self.checklistItem.value = [switchOptions objectForKey: @"hi_value"];
                    self.checklistItem.violationFlag = [NSNumber numberWithInt: 1];
                    break;
            }
        }
            break;
        case INPUT_PHOTO:
        case INPUT_VIDEO:
            self.checklistItem.value = [NSString stringWithFormat: @"%d", self.checklistItem.mediaItems.count];
            self.checklistItem.violationFlag = nil;
            break;
        case INPUT_COMMENT: {
            UITextView *textView = (UITextView *) self.control;
            self.checklistItem.value = textView.text;
            self.checklistItem.violationFlag = nil;
            break;
        }
    }

    [self.saveDelegate didSaveAttributeItem: self.checklistItem];
}

#pragma mark -
#pragma mark Helper methods

- (UIImage *) imageFromText: (NSString *) text {
    // set the font type and size
    UIFont *font = [UIFont boldSystemFontOfSize: 13.0];  
    CGSize size  = [text sizeWithFont:font];
    
    // check if UIGraphicsBeginImageContextWithOptions is available (iOS is 4.0+)
    if ( UIGraphicsBeginImageContextWithOptions != NULL )
        UIGraphicsBeginImageContextWithOptions ( size, NO, 0.0 );
    else
        // iOS is < 4.0 
        UIGraphicsBeginImageContext(size);
    
    // optional: add a shadow, to avoid clipping the shadow you should make the context size bigger 
    //
    // CGContextRef ctx = UIGraphicsGetCurrentContext();
    // CGContextSetShadowWithColor(ctx, CGSizeMake(1.0, 1.0), 5.0, [[UIColor grayColor] CGColor]);
    
    // draw in context, you can use also drawInRect:withFont:
    [text drawAtPoint:CGPointMake(0.0, 0.0) withFont:font];
    
    // transfer image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();    
    
    return image;
}

- (NSArray *) mediaItemsOfType: (NSString *) mediaType {
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"SELF.mediaType LIKE %@", mediaType];
    return [[self.checklistItem.mediaItems allObjects] filteredArrayUsingPredicate: predicate];
}
                                                        

#pragma mark -
#pragma mark Action sheet

- (void) actionSheet: (UIActionSheet *) actionSheet clickedButtonAtIndex: (NSInteger) buttonIndex {
    if ( buttonIndex == 0 ) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.allowsEditing = NO;
        imagePicker.delegate = self;
        imagePicker.mediaTypes = [[self.itemInfo objectForKey: @"control"] intValue] == INPUT_PHOTO ?
            [NSArray arrayWithObjects: (NSString *) kUTTypeImage, nil] :
            [NSArray arrayWithObjects: (NSString *) kUTTypeMovie, nil] ;
        
        UIViewController *parentController = [self firstAvailableUIViewController];
        [parentController presentModalViewController: imagePicker animated: YES];
    }
    
    if ( buttonIndex == 1 ) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.allowsEditing = NO;
        imagePicker.delegate = self;
        imagePicker.mediaTypes = [[self.itemInfo objectForKey: @"control"] intValue] == INPUT_PHOTO ?
            [NSArray arrayWithObjects: (NSString *) kUTTypeImage, nil] :
            [NSArray arrayWithObjects: (NSString *) kUTTypeMovie, nil] ;
        
        UIViewController *parentController = [self firstAvailableUIViewController];
        [parentController presentModalViewController: imagePicker animated: YES];
    }
    
    if ( ( buttonIndex == 2 ) && ( buttonIndex != actionSheet.cancelButtonIndex ) ) {
        int controlType = [[self.itemInfo objectForKey: @"control"] intValue];
        
        NSArray *mediaItems = 
            controlType == INPUT_PHOTO ?
                [self mediaItemsOfType: (NSString *) kUTTypeImage] : 
            controlType == INPUT_VIDEO ?
                [self mediaItemsOfType: (NSString *) kUTTypeMovie] : nil;
        
        if ( mediaItems ) {
            self.mwBrowserItems = [NSMutableArray array];
            for ( MediaItem *mediaItem in mediaItems ) {
                if ( controlType == INPUT_PHOTO )
                    [self.mwBrowserItems addObject: [MWPhoto photoWithFilePath: mediaItem.filePath]];
                
                if ( controlType == INPUT_VIDEO ) 
                    [self.mwBrowserItems addObject: [MWMoviePreview movieWithFilePath: mediaItem.filePath]];
            }
            
            MWPhotoBrowser *browser = nil;
            
            if ( controlType == INPUT_PHOTO )
                browser = [[MWPhotoBrowser alloc] initWithDelegate: self];
            
            if ( controlType == INPUT_VIDEO ) 
                browser = [[MWMovieBrowser alloc] initWithDelegate: self];
            
            browser.displayActionButton = YES;
            browser.title = [self.itemInfo objectForKey: @"hint"];
            browser.displayActionButton = NO;
            browser.displayRemoveButton = YES;

            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController: browser];
            nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            UIViewController *parentViewController = [self firstAvailableUIViewController];
            [parentViewController presentModalViewController: nc animated: YES];
            [nc release];
            [browser release];
        }
    }
}

#pragma mark -
#pragma mark MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.mwBrowserItems.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.mwBrowserItems.count )
        return [self.mwBrowserItems objectAtIndex: index];
    return nil;
}

- (void) photoBrowser: (MWPhotoBrowser *) photoBrowser pressedRemoveButtonAtIndex: (NSUInteger) index {
    int controlType = [[self.itemInfo objectForKey: @"control"] intValue];
    
    NSArray *mediaItems = 
        controlType == INPUT_PHOTO ?
            [self mediaItemsOfType: (NSString *) kUTTypeImage] : 
        controlType == INPUT_VIDEO ?
            [self mediaItemsOfType: (NSString *) kUTTypeMovie] : nil;

    NSError *error = nil;
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.managedObjectContext deleteObject: [mediaItems objectAtIndex: index]];
    [appDelegate.managedObjectContext save: &error];
    
    NSArray *mediaItemsAfterRemoval = 
        controlType == INPUT_PHOTO ?
            [self mediaItemsOfType: (NSString *) kUTTypeImage] : 
        controlType == INPUT_VIDEO ?
            [self mediaItemsOfType: (NSString *) kUTTypeMovie] : nil;
    
    if ( error ) 
        NSLog(@"error removing media item: %@", error);

    [self.mwBrowserItems removeAllObjects];
    
    if ( mediaItemsAfterRemoval.count ) {
        for ( MediaItem *mediaItem in mediaItemsAfterRemoval ) {
            if ( controlType == INPUT_PHOTO )
                [self.mwBrowserItems addObject: [MWPhoto photoWithFilePath: mediaItem.filePath]];
            
            if ( controlType == INPUT_VIDEO ) 
                [self.mwBrowserItems addObject: [MWMoviePreview movieWithFilePath: mediaItem.filePath]];
        }
    }
    
    photoBrowser.title = [self.itemInfo objectForKey: @"hint"];
    
    [self loadItem];
}

#pragma mark -
#pragma mark Using iPhone camera

- (void) takePhoto: (id) sender {
    [[self.checklistCellDelegate latestActiveResponder] resignFirstResponder];
    // TODO: check camera availability and media types
    
    NSArray *mediaItems = [self mediaItemsOfType: (NSString *) kUTTypeImage];
    
    UIActionSheet *photoActionSheet = nil;
    
    if ( mediaItems.count ) {   
        photoActionSheet = [[UIActionSheet alloc] initWithTitle: [self.itemInfo objectForKey: @"hint"] 
                                                       delegate: self 
                                              cancelButtonTitle: @"Отменить" 
                                         destructiveButtonTitle: nil 
                                              otherButtonTitles: @"Снять фото", @"Выбрать в альбомах", @"Посмотреть фото", nil];
        
    } else {
        photoActionSheet = [[UIActionSheet alloc] initWithTitle: [self.itemInfo objectForKey: @"hint"]
                                                       delegate: self 
                                              cancelButtonTitle: @"Отменить" 
                                         destructiveButtonTitle: nil 
                                              otherButtonTitles: @"Снять фото", @"Выбрать в альбомах", nil];
    }
    
    
    UIViewController *parentViewController = [self firstAvailableUIViewController];
    if ( parentViewController.tabBarController )
        [photoActionSheet showFromTabBar: parentViewController.tabBarController.tabBar];
    else
        [photoActionSheet showInView: self.superview];
    
    [photoActionSheet release];
}

- (void) takeVideo: (id) sender {
    [[self.checklistCellDelegate latestActiveResponder] resignFirstResponder];
    // TODO: check camera availability and media types
    
    NSArray *mediaItems = [self mediaItemsOfType: (NSString *) kUTTypeMovie];
    
    UIActionSheet *videoActionSheet = nil;
    
    if ( mediaItems.count ) {
        videoActionSheet = [[UIActionSheet alloc] initWithTitle: [self.itemInfo objectForKey: @"hint"]
                                                       delegate: self 
                                              cancelButtonTitle: @"Отменить" 
                                         destructiveButtonTitle: nil 
                                              otherButtonTitles: @"Снять видео", @"Выбрать в альбомах", @"Посмотреть видео", nil];
        
    } else {
        videoActionSheet = [[UIActionSheet alloc] initWithTitle: [self.itemInfo objectForKey: @"hint"]
                                                       delegate: self 
                                              cancelButtonTitle: @"Отменить" 
                                         destructiveButtonTitle: nil 
                                              otherButtonTitles: @"Снять видео", @"Выбрать в альбомах", nil];
    }
    
    UIViewController *parentViewController = [self firstAvailableUIViewController];
    [videoActionSheet showFromTabBar: parentViewController.tabBarController.tabBar];
    [videoActionSheet release];
}

- (void) processImagePickerData: (NSDictionary *) data {
    BOOL saveMediaToLibrary = [[data objectForKey: @"saveMediaToLibrary"] boolValue];
    NSDictionary *info = [data objectForKey: @"info"];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSFileManager *fm = [NSFileManager defaultManager];
    MediaItem *mediaItem = [NSEntityDescription insertNewObjectForEntityForName: @"MediaItem" 
                                                         inManagedObjectContext: [appDelegate managedObjectContext]];
    
    NSString *docsDirectory = [NSSearchPathForDirectoriesInDomains ( NSDocumentDirectory, NSUserDomainMask, YES ) lastObject];
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    // Handle a still image capture
    if ( CFStringCompare ( (CFStringRef) mediaType, kUTTypeImage, 0 ) == kCFCompareEqualTo ) {
        UIImage *originalImage = (UIImage *) [info objectForKey: UIImagePickerControllerOriginalImage];
        NSString *photosDirectory = [docsDirectory stringByAppendingPathComponent: @"Photos"];
        NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *imageFilename = [NSString stringWithFormat: @"%qx.png", fabs(currentTimestamp) * 1000]; 
        NSString *imageFilepath = [photosDirectory stringByAppendingPathComponent: imageFilename];
        
        if ( saveMediaToLibrary )
            UIImageWriteToSavedPhotosAlbum (originalImage, nil, nil , nil);
        
        if ( ! [fm fileExistsAtPath: photosDirectory] )
            [fm createDirectoryAtPath: photosDirectory withIntermediateDirectories: YES 
                           attributes: nil 
                                error: nil];
        
        [UIImagePNGRepresentation(originalImage) writeToFile: imageFilepath atomically: YES];
        
        mediaItem.mediaType = mediaType;
        mediaItem.filePath = imageFilepath;
    }   
    
    // Handle a movie capture
    if ( CFStringCompare ( (CFStringRef) mediaType, kUTTypeMovie, 0 ) == kCFCompareEqualTo ) {
        NSString *moviePath = [[info objectForKey: UIImagePickerControllerMediaURL] path];
        NSString *videosDirectory = [docsDirectory stringByAppendingPathComponent: @"Videos"];
        NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *videoFilename = [NSString stringWithFormat: @"%qx.mov", fabs(currentTimestamp) * 1000];
        NSString *videoFilepath = [videosDirectory stringByAppendingPathComponent: videoFilename];
        
        if ( ! [fm fileExistsAtPath: videosDirectory] )
            [fm createDirectoryAtPath: videosDirectory withIntermediateDirectories: YES 
                           attributes: nil 
                                error: nil];
        
        if ( UIVideoAtPathIsCompatibleWithSavedPhotosAlbum ( moviePath ) && saveMediaToLibrary )
            UISaveVideoAtPathToSavedPhotosAlbum ( moviePath, nil, nil, nil );
        
        [fm copyItemAtPath: moviePath toPath: videoFilepath error: nil];
        
        mediaItem.mediaType = mediaType;
        mediaItem.filePath = videoFilepath;
    }
    
    mediaItem.timestamp = [NSDate date];
    
    [self.checklistItem addMediaItemsObject: mediaItem];
    [self saveItem];
    
    [self setNeedsLayout];
}

- (void) imagePickerController: (UIImagePickerController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info {
    BOOL saveMediaToLibrary = ( picker.sourceType == UIImagePickerControllerSourceTypeCamera );
    UIViewController *parentController = [self firstAvailableUIViewController];
    [parentController dismissModalViewControllerAnimated: YES];
    [picker release];
    
    HUD = [[MBProgressHUD alloc] initWithView: [UIApplication sharedApplication].keyWindow];
	[[UIApplication sharedApplication].keyWindow addSubview: HUD];
    
    HUD.delegate = self;
    HUD.labelText = @"Сохранение";
    
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys: 
                          info, @"info", 
                          [NSNumber numberWithBool: saveMediaToLibrary], @"saveMediaToLibrary", 
                          nil];
    
    [HUD showWhileExecuting: @selector(processImagePickerData:) onTarget: self withObject: data animated: YES];
}

- (void) hudWasHidden {
    [HUD release];
}

- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    
    UIViewController *parentController = [self firstAvailableUIViewController];
    [parentController dismissModalViewControllerAnimated: YES];
    [picker release];
    
    [self setNeedsLayout];
}

#pragma mark -
#pragma mark Popup picker events

- (void) popupPicker: (id) sender {
    NSArray *possibleValues = [self.itemInfo objectForKey: @"possible_values"];
    NSMutableArray *strings = [NSMutableArray array];
    
    for ( NSDictionary *valueInfo in possibleValues )
        [strings addObject: [valueInfo objectForKey: @"title"]];
    
    [ActionSheetStringPicker showPickerWithTitle: [self.itemInfo objectForKey: @"title"] 
                                            rows: strings 
                                initialSelection: 0 
                                          target: self 
                                    sucessAction: @selector(pickerSelected:element:) 
                                    cancelAction: @selector(pickerCancelled:) 
                                          origin: sender];
}

- (void) pickerSelected: (NSNumber *) selectedIndex element: (id) sender {
    UITextField *field = (UITextField *) self.control;
    NSArray *possibleValues = [self.itemInfo objectForKey: @"possible_values"];
    NSDictionary *selectedValue = [possibleValues objectAtIndex: [selectedIndex intValue]];
    
    field.text = [selectedValue objectForKey: @"title"];
    [field resignFirstResponder];
    [self saveItem];
}


- (void) pickerCancelled: (id) sender {
}

#pragma mark -
#pragma mark UITextField events

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if ( [self.saveDelegate isCancelling] )
        return YES;
    
    if ( [[self.itemInfo objectForKey: @"required"] boolValue] ) {
        if ( textField.text.length ) {
            return YES;
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Ошибка" 
                                                                message: @"Не заполнено обязательное поле" 
                                                               delegate: nil 
                                                      cancelButtonTitle: @"OK" 
                                                      otherButtonTitles: nil];
            
            [alertView show];
            [alertView release];
            return NO;
        }
    } else {
        return YES;
    }
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if ( textField.text.length )
        [self saveItem];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    [[self.checklistCellDelegate latestActiveResponder] resignFirstResponder];
    [self.checklistCellDelegate setLatestActiveResponder: textField];
    if ( [self.itemInfo objectForKey: @"possible_values"] == nil ) {
        return YES;
    } else {
        [self popupPicker: textField];
        return NO;
    }
}

#pragma mark -
#pragma mark UITextView events

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [[self.checklistCellDelegate latestActiveResponder] resignFirstResponder];
    [self.checklistCellDelegate setLatestActiveResponder: textView];
    return YES;
}

/*
-(BOOL)textViewShouldEndEditing:(UITextView *)textView {
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
    if ( textView.text.length )
        [self saveItem];
}*/

-(void) cancelTextView {
    UITextView *textView = (UITextView *) self.control;
    [textView resignFirstResponder];
    [self loadItem];
}

-(void) saveTextView {
    UITextView *textView = (UITextView *) self.control;
    if ( textView.text.length )
        [self saveItem];
    [textView resignFirstResponder];
}

#pragma mark -
#pragma mark Slider events

- (void) snapSliderToValue: (id) sender {
    UISlider *slider = (UISlider *) sender;
    
    if ( slider.value >= -1 && slider.value < -0.5 ) {
        slider.value = -1;
        [slider setMinimumTrackImage: [[UIImage imageNamed: @"slider_bad"] stretchableImageWithLeftCapWidth: 52 topCapHeight: 0]
                            forState: UIControlStateNormal];
        [slider setMaximumTrackImage: [[UIImage imageNamed: @"slider_good"] stretchableImageWithLeftCapWidth: 62 topCapHeight: 0]
                            forState: UIControlStateNormal];
    }
    
    if ( slider.value >= -0.5 && slider.value < 0.5 ) {
        slider.value = 0;
        [slider setMinimumTrackImage: [[UIImage imageNamed: @"slider_neutral"] stretchableImageWithLeftCapWidth: 52 topCapHeight: 0]
                            forState: UIControlStateNormal];
        [slider setMaximumTrackImage: [[UIImage imageNamed: @"slider_neutral"] stretchableImageWithLeftCapWidth: 62 topCapHeight: 0]
                            forState: UIControlStateNormal];
    }
    
    if ( slider.value >= 0.5 && slider.value <= 1 ) {
        slider.value = 1;
        [slider setMinimumTrackImage: [[UIImage imageNamed: @"slider_bad"] stretchableImageWithLeftCapWidth: 52 topCapHeight: 0]
                            forState: UIControlStateNormal];
        [slider setMaximumTrackImage: [[UIImage imageNamed: @"slider_good"] stretchableImageWithLeftCapWidth: 62 topCapHeight: 0]
                            forState: UIControlStateNormal];
    }
    
    if ( slider.value != 0 )
        [self saveItem];
}

@end
