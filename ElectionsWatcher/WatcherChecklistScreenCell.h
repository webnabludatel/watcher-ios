//
//  WatcherChecklistScreenCell.h
//  ElectionsWatcher
//
//  Created by xfire on 22.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"

#define INPUT_TEXT          0
#define INPUT_NUMBER        1
#define INPUT_DROPDOWN      2
#define INPUT_SWITCH        3
#define INPUT_PHOTO         4
#define INPUT_VIDEO         5
#define INPUT_COMMENT       6
#define INPUT_CONSTANT      7
#define INPUT_EMAIL         8

@class ChecklistItem;

@interface WatcherChecklistScreenCell : UITableViewCell <UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, MWPhotoBrowserDelegate>

@property (nonatomic, assign) NSDictionary *itemInfo;
@property (nonatomic, assign) UIView *control;
@property (nonatomic, assign) UILabel *itemLabel;
@property (nonatomic, retain) ChecklistItem *checklistItem;
@property (nonatomic) NSInteger sectionIndex;
@property (nonatomic) NSInteger screenIndex;
@property (nonatomic, retain) NSMutableArray *mwBrowserItems;

- (id) initWithStyle: (UITableViewCellStyle) style reuseIdentifier: (NSString *) reuseIdentifier withItemInfo: (NSDictionary *) anItemInfo;

- (UIImage *) imageFromText: (NSString *) text;
- (void) loadItem;
- (void) saveItem;
- (NSArray *) mediaItemsOfType: (NSString *) mediaType;

@end
