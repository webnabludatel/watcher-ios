//
//  WatcherInfoHeaderView.h
//  ElectionsWatcher
//
//  Created by xfire on 26.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WatcherInfoHeaderView : UIView

@property (nonatomic, readonly) UILabel *textLabel;
@property (nonatomic, readonly) UIButton *infoButton;

- (id)initWithFrame:(CGRect)frame withTitle: (NSString *) title;

@end
