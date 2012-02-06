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

@implementation WatcherChecklistScreenCell

@synthesize itemInfo;
@synthesize control;
@synthesize checklistItem;
@synthesize sectionIndex;
@synthesize screenIndex;

#pragma mark -
#pragma mark Cell implementation

- (id) initWithStyle: (UITableViewCellStyle) style reuseIdentifier: (NSString *) reuseIdentifier withItemInfo: (NSDictionary *) anItemInfo {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if ( self ) {
        self.itemInfo = anItemInfo;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.textLabel.font = [UIFont systemFontOfSize: 12];
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = UILineBreakModeTailTruncation;

        switch ( [[self.itemInfo objectForKey: @"control"] intValue] ) {
            case INPUT_TEXT: {
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
                
//                [textField addTarget: self action: @selector(popupPicker:) forControlEvents: UIControlEventTouchDown];
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
                
                [slider addTarget: self 
                           action: @selector(snapSliderToValue:) 
                 forControlEvents: UIControlEventValueChanged];
            }
                break;
                
            case INPUT_PHOTO: {
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
                self.control = [[[UITextField alloc] init] autorelease];
            }
                break;
                
            default:
                @throw [NSException exceptionWithName: NSInvalidArgumentException 
                                               reason: @"invalid control type in plist" 
                                             userInfo: nil]; 
                break;
        }
        
        [self.contentView addSubview: self.control];
    }
    
    return self;
}


- (void) layoutSubviews {
    [super layoutSubviews];
    
    if ( self.itemInfo ) {
        CGRect labelFrame, controlFrame;
        CGRectDivide(self.contentView.bounds, &labelFrame, &controlFrame, self.bounds.size.width/2.0f, CGRectMinXEdge);
        
        self.textLabel.frame = CGRectInset(labelFrame,   10, 10);
        self.control.frame   = CGRectInset(controlFrame, 10, 10);
        
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
                if ( [[switchOptions objectForKey: @"lo_value"] isEqualToString: self.checklistItem.value] )
                    slider.value = -1;
                else if ( [[switchOptions objectForKey: @"hi_value"] isEqualToString: self.checklistItem.value] )
                    slider.value = +1;
                else
                    slider.value = 0;
            }
                break;
                
            case INPUT_PHOTO: {
                UIButton *button = (UIButton *) self.control;
                [button setTitle: [NSString stringWithFormat: @"Фото (%d)", [self.checklistItem.mediaItems count]] 
                        forState: UIControlStateNormal];
                
            }
                break;
                
            case INPUT_VIDEO: {
                UIButton *button = (UIButton *) self.control;
                [button setTitle: [NSString stringWithFormat: @"Видео (%d)", [self.checklistItem.mediaItems count]] 
                        forState: UIControlStateNormal];
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
     
        self.checklistItem.name = [itemInfo objectForKey: @"name"];
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
    
}

#pragma mark -
#pragma mark Using iPhone camera

- (void) takePhoto: (id) sender {
    UIActionSheet *photoActionSheet = [[UIActionSheet alloc] initWithTitle: @"Фото" 
                                                                  delegate: self 
                                                         cancelButtonTitle: @"Отменить" 
                                                    destructiveButtonTitle: nil 
                                                         otherButtonTitles: @"Снять фото", @"Посмотреть фото", nil];
    
    UIViewController *parentViewController = [self firstAvailableUIViewController];
    [photoActionSheet showFromTabBar: parentViewController.tabBarController.tabBar];
    [photoActionSheet release];
}

- (void) takeVideo: (id) sender {
    UIActionSheet *videoActionSheet = [[UIActionSheet alloc] initWithTitle: @"Видео" 
                                                                  delegate: self 
                                                         cancelButtonTitle: @"Отменить" 
                                                    destructiveButtonTitle: nil 
                                                         otherButtonTitles: @"Снять видео", @"Посмотреть видео", nil];
    UIViewController *parentViewController = [self firstAvailableUIViewController];
    [videoActionSheet showFromTabBar: parentViewController.tabBarController.tabBar];
    [videoActionSheet release];
}

- (void) imagePickerController: (UIImagePickerController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info {
    NSLog(@"media info: %@", info);
    
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
    
    NSError *error = nil;
    
    if ( ! [[appDelegate managedObjectContext] save: &error] )
        NSLog(@"error saving data: %@", error);
    
    UIViewController *parentController = [self firstAvailableUIViewController];
    [parentController dismissModalViewControllerAnimated: YES];
    [picker release];
}

- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    
    UIViewController *parentController = [self firstAvailableUIViewController];
    [parentController dismissModalViewControllerAnimated: YES];
    [picker release];
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

#pragma mark -
#pragma mark Text field events

- (void) textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
    [self saveItem];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    if ( [self.itemInfo objectForKey: @"possible_values"] == nil ) {
        return YES;
    } else {
        [self popupPicker: textField];
        return NO;
    }
}


- (void) pickerCancelled: (id) sender {
}

#pragma mark -
#pragma mark Slider events

- (void) snapSliderToValue: (id) sender {
    UISlider *slider = (UISlider *) sender;
    
    if ( slider.value >= -1 && slider.value < -0.5 )
        slider.value = -1;
    
    if ( slider.value >= -0.5 && slider.value < 0.5 )
        slider.value = 0;
    
    if ( slider.value >= 0.5 && slider.value <= 1 )
        slider.value = 1;
    
    [self saveItem];
}

@end
