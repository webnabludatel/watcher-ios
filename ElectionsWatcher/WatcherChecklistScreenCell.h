//
//  WatcherChecklistScreenCell.h
//  ElectionsWatcher
//
//  Created by xfire on 22.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define INPUT_TEXT          0
#define INPUT_NUMBER        1
#define INPUT_DROPDOWN      2
#define INPUT_SWITCH        3
#define INPUT_PHOTO         4
#define INPUT_VIDEO         5
#define INPUT_COMMENT       6

@class ChecklistItem;

@interface WatcherChecklistScreenCell : UITableViewCell <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, assign) NSDictionary *itemInfo;
@property (nonatomic, assign) UIControl *control;
@property (nonatomic, assign) ChecklistItem *checklistItem;
@property (nonatomic) NSInteger sectionIndex;
@property (nonatomic) NSInteger screenIndex;

- (id) initWithStyle: (UITableViewCellStyle) style reuseIdentifier: (NSString *) reuseIdentifier withItemInfo: (NSDictionary *) anItemInfo;

- (UIImage *) imageFromText: (NSString *) text;
- (void) loadItem;
- (void) saveItem;

@end
