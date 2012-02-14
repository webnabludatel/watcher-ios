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

static UIView *currentlySelectedInputView = nil;

@synthesize itemInfo;
@synthesize control;
@synthesize itemLabel;
@synthesize checklistItem;
@synthesize sectionIndex;
@synthesize screenIndex;
@synthesize mwBrowserItems;

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
        self.itemLabel.text = [self.itemInfo objectForKey: @"title"];
        
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
                [button setTitle: @"Фото" forState: UIControlStateNormal];
                [button addTarget: self action: @selector(takePhoto:) forControlEvents: UIControlEventTouchUpInside];
            }
                break;
                
            case INPUT_VIDEO: {
                self.control = [UIButton buttonWithType: UIButtonTypeRoundedRect];
                
                UIButton *button = (UIButton *) self.control;
                [button setTitle: @"Видео" forState: UIControlStateNormal];
                [button addTarget: self action: @selector(takeVideo:) forControlEvents: UIControlEventTouchUpInside];
            }
                break;
                
            case INPUT_COMMENT: {
                self.control = [[[UITextView alloc] init] autorelease];
                
                UITextView *textView = (UITextView *) self.control;
                textView.keyboardType = UIKeyboardTypeDefault;
                textView.backgroundColor = [UIColor clearColor];
                textView.delegate = self;
                
                UIView *saveTextToolbar = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.frame.size.width, 50)];
                UIButton *saveTextButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
                [saveTextButton setFrame: CGRectInset(saveTextToolbar.bounds, 10, 10)];
                [saveTextButton setTitle: @"Сохранить" forState: UIControlStateNormal];
                [saveTextButton addTarget: textView action: @selector(resignFirstResponder) forControlEvents: UIControlEventTouchUpInside];
                
                [saveTextToolbar addSubview: saveTextButton];
                [saveTextToolbar setBackgroundColor: [UIColor groupTableViewBackgroundColor]];
                
                textView.inputAccessoryView = saveTextToolbar;
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
        NSString *itemTitle = [self.itemInfo objectForKey: @"title"];
        CGSize labelSize = [itemTitle sizeWithFont: [UIFont boldSystemFontOfSize: 13] 
                                 constrainedToSize: CGSizeMake(280, 120) 
                                     lineBreakMode: UILineBreakModeWordWrap];
        
        CGRect labelFrame, controlArea, controlFrame, timestampFrame;
        CGRectDivide(CGRectInset(self.contentView.bounds, 10, 10), &labelFrame, &controlArea, labelSize.height, CGRectMinYEdge);
        CGRectDivide(controlArea, &timestampFrame, &controlFrame, controlArea.size.width/3.0f, CGRectMinXEdge);
        
        self.itemLabel.frame = labelFrame;
        self.control.frame   = ( [[self.itemInfo objectForKey: @"control"] intValue] == INPUT_SWITCH ) ?
            CGRectMake(controlFrame.origin.x, controlFrame.origin.y+10, controlFrame.size.width, controlFrame.size.height-10) :
            CGRectMake(controlArea.origin.x, controlArea.origin.y+10, controlArea.size.width, controlArea.size.height-10);
        
        [self loadItem];
    }
}

#pragma mark -
#pragma mark Handling item save/restore

- (void) loadItem {
    NSString *itemName = [self.itemInfo objectForKey: @"name"];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSDictionary *bindParams = [NSDictionary dictionaryWithObjectsAndKeys: itemName, @"ITEM_NAME", nil];
    NSArray *results = [appDelegate executeFetchRequest: @"findItemByName" forEntity: @"ChecklistItem" withParameters: bindParams];
    
    if ( [results count] ) {
        self.checklistItem = [results lastObject];
        
        switch ( [[self.itemInfo objectForKey: @"control"] intValue] ) {
            case INPUT_TEXT:
            case INPUT_NUMBER:
            case INPUT_DROPDOWN: {
                UITextField *textField = (UITextField *) self.control;
                textField.text = self.checklistItem.value;
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
}

- (void) saveItem {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ( self.checklistItem == nil ) {
        self.checklistItem = [NSEntityDescription insertNewObjectForEntityForName: @"ChecklistItem" 
                                                            inManagedObjectContext: [appDelegate managedObjectContext]];
     
        self.checklistItem.name = [self.itemInfo objectForKey: @"name"];
        self.checklistItem.sectionIndex = [NSNumber numberWithInt: self.sectionIndex];
        self.checklistItem.screenIndex = [NSNumber numberWithInt: self.screenIndex];
    }
    
    self.checklistItem.lat = [NSNumber numberWithDouble: appDelegate.currentLocation.coordinate.latitude];
    self.checklistItem.lng = [NSNumber numberWithDouble: appDelegate.currentLocation.coordinate.longitude];
    self.checklistItem.timestamp = [NSDate date];
    self.checklistItem.synchronized = [NSNumber numberWithBool: NO];
    
    switch ( [[self.itemInfo objectForKey: @"control"] intValue] ) {
        case INPUT_TEXT:
        case INPUT_NUMBER:
        case INPUT_DROPDOWN: {
            UITextField *textField = (UITextField *) self.control;
            self.checklistItem.value = textField.text;
        }
            break;
        case INPUT_SWITCH: {
            UISlider *slider = (UISlider *) self.control;
            NSDictionary *switchOptions = [self.itemInfo objectForKey: @"switch_options"];
            switch ( (int) slider.value ) {
                case -1:
                    self.checklistItem.value = [switchOptions objectForKey: @"lo_value"];
                    break;
                case 0:
                    self.checklistItem.value = nil;
                    break;
                case +1:
                    self.checklistItem.value = [switchOptions objectForKey: @"hi_value"];
                    break;
            }
        }
            break;
        case INPUT_PHOTO:
        case INPUT_VIDEO:
            self.checklistItem.value = @"check attached media files";
            break;
        case INPUT_COMMENT:
            break;
    }

    NSError *error = nil;
    
    if ( ! [[appDelegate managedObjectContext] save: &error] )
        NSLog(@"error saving data: %@", error);

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
            [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil] :
            [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil] ;
        
        UIViewController *parentController = [self firstAvailableUIViewController];
        [parentController presentModalViewController: imagePicker animated: YES];
    }
    
    if ( buttonIndex == 1 ) {
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

#pragma mark -
#pragma mark Using iPhone camera

- (void) takePhoto: (id) sender {
    // TODO: check camera availability and media types
    if ( currentlySelectedInputView != sender ) {
        [currentlySelectedInputView resignFirstResponder];
        currentlySelectedInputView = sender;
    }
    
    NSArray *mediaItems = [self mediaItemsOfType: (NSString *) kUTTypeImage];
    
    UIActionSheet *photoActionSheet = nil;
    
    if ( mediaItems.count ) {   
        photoActionSheet = [[UIActionSheet alloc] initWithTitle: @"Фото" 
                                                       delegate: self 
                                              cancelButtonTitle: @"Отменить" 
                                         destructiveButtonTitle: nil 
                                              otherButtonTitles: @"Снять фото", @"Посмотреть фото", nil];
        
    } else {
        photoActionSheet = [[UIActionSheet alloc] initWithTitle: @"Фото" 
                                                       delegate: self 
                                              cancelButtonTitle: @"Отменить" 
                                         destructiveButtonTitle: nil 
                                              otherButtonTitles: @"Снять фото", nil];
    }
    
    
    UIViewController *parentViewController = [self firstAvailableUIViewController];
    [photoActionSheet showFromTabBar: parentViewController.tabBarController.tabBar];
    [photoActionSheet release];
}

- (void) takeVideo: (id) sender {
    // TODO: check camera availability and media types
    if ( currentlySelectedInputView != sender ) {
        [currentlySelectedInputView resignFirstResponder];
        currentlySelectedInputView = sender;
    }
    
    NSArray *mediaItems = [self mediaItemsOfType: (NSString *) kUTTypeMovie];
    
    UIActionSheet *videoActionSheet = nil;
    
    if ( mediaItems.count ) {
        videoActionSheet = [[UIActionSheet alloc] initWithTitle: @"Видео" 
                                                        delegate: self 
                                               cancelButtonTitle: @"Отменить" 
                                          destructiveButtonTitle: nil 
                                               otherButtonTitles: @"Снять видео", @"Посмотреть видео", nil];
        
    } else {
        videoActionSheet = [[UIActionSheet alloc] initWithTitle: @"Видео" 
                                                       delegate: self 
                                              cancelButtonTitle: @"Отменить" 
                                         destructiveButtonTitle: nil 
                                              otherButtonTitles: @"Снять видео", nil];
    }
    
    UIViewController *parentViewController = [self firstAvailableUIViewController];
    [videoActionSheet showFromTabBar: parentViewController.tabBarController.tabBar];
    [videoActionSheet release];
}

- (void) imagePickerController: (UIImagePickerController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info {
    // save checklist item before adding media, otherwise it doesn't work
    [self saveItem];
    
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
        NSString *imageFilename = [NSString stringWithFormat: @"%d.png", fabs(currentTimestamp) * 1000]; 
        NSString *imageFilepath = [photosDirectory stringByAppendingPathComponent: imageFilename];
        
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
        
        mediaItem.mediaType = mediaType;
        mediaItem.filePath = videoFilepath;
    }
    
    [self.checklistItem addMediaItemsObject: mediaItem];
    [self saveItem];
    
    UIViewController *parentController = [self firstAvailableUIViewController];
    [parentController dismissModalViewControllerAnimated: YES];
    [picker release];
    
    [self setNeedsLayout];
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
    
    [self saveItem];
}


- (void) pickerCancelled: (id) sender {
}

#pragma mark -
#pragma mark UITextField events

- (void) textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
    [self saveItem];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    if ( currentlySelectedInputView != textField ) {
        [currentlySelectedInputView resignFirstResponder];
        currentlySelectedInputView = textField;
    }
    
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
    return YES;
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if ( currentlySelectedInputView != textView ) {
        [currentlySelectedInputView resignFirstResponder];
        currentlySelectedInputView = textView;
    }
    
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
    [self saveItem];
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
    
    [self saveItem];
}

@end
