//
//  WatcherChecklistScreenCell.h
//  ElectionsWatcher
//
//  Created by xfire on 22.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"
#import "WatcherSaveAttributeDelegate.h"
#import "WatcherChecklistScreenCellDelegate.h"
#import "MBProgressHUD.h"

#define INPUT_TEXT          0
#define INPUT_NUMBER        1
#define INPUT_DROPDOWN      2
#define INPUT_SWITCH        3
#define INPUT_PHOTO         4
#define INPUT_VIDEO         5
#define INPUT_COMMENT       6
#define INPUT_CONSTANT      7
#define INPUT_EMAIL         8
#define INPUT_PHONE         9

@class ChecklistItem;
@class MBProgressHUD;

@interface WatcherChecklistScreenCell : UITableViewCell <UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, MWPhotoBrowserDelegate, MBProgressHUDDelegate>

@property (nonatomic, assign) NSDictionary *itemInfo;
@property (nonatomic, assign) UIView *control;
@property (nonatomic, assign) UILabel *itemLabel;
@property (nonatomic, retain) ChecklistItem *checklistItem;
@property (nonatomic, retain) NSString *sectionName;
@property (nonatomic, retain) NSString *pickerSelectedValue;
@property (nonatomic) NSInteger screenIndex;
@property (nonatomic, retain) NSMutableArray *mwBrowserItems;
@property (nonatomic, assign) id<WatcherSaveAttributeDelegate> saveDelegate;
@property (nonatomic, assign) id<WatcherChecklistScreenCellDelegate> checklistCellDelegate;
@property (nonatomic, assign) MBProgressHUD *HUD;


- (id) initWithStyle: (UITableViewCellStyle) style reuseIdentifier: (NSString *) reuseIdentifier withItemInfo: (NSDictionary *) anItemInfo;

- (UIImage *) imageFromText: (NSString *) text;
- (void) loadItem;
- (void) saveItem;
- (NSArray *) mediaItemsOfType: (NSString *) mediaType;
- (NSString *) valueListTitleFromValue: (NSString *) value;

@end
