//
//  Watcher3PosSwitch.h
//  ElectionsWatcher
//
//  Created by xfire on 23.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChecklistItem;

@protocol Watcher3PosSwitchDelegate <NSObject>

- (void) switchDidChangeValueTo: (NSString *) value;

@end

@interface Watcher3PosSwitch : UIView

@property (nonatomic, readonly) UILabel *leftSideLabel;
@property (nonatomic, readonly) UILabel *rightSideLabel;
@property (nonatomic, readonly) UIImageView *backgroundImageView;
@property (nonatomic, readonly) UISlider *slider;
@property (nonatomic, readonly) id <Watcher3PosSwitchDelegate> delegate;
@property (nonatomic, assign) NSDictionary *switchOptions;
@property (nonatomic, assign) ChecklistItem *checklistItem;

- (id) initWithFrame: (CGRect) frame 
        withDelegate: (id<Watcher3PosSwitchDelegate>) delegate
         withOptions: (NSDictionary *) options 
   withChecklistItem: (ChecklistItem *) checklistItem;

@end
