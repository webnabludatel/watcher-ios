//
//  Watcher3PosSwitch.m
//  ElectionsWatcher
//
//  Created by xfire on 23.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Watcher3PosSwitch.h"
#import "ChecklistItem.h"

@implementation Watcher3PosSwitch

@synthesize slider = _slider;
@synthesize backgroundImageView = _backgroundImageView;
@synthesize leftSideLabel = _leftSideLabel;
@synthesize rightSideLabel = _rightSideLabel;
@synthesize delegate = _delegate;
@synthesize switchOptions = _switchOptions;
@synthesize checklistItem = _checklistItem;

- (id) initWithFrame: (CGRect) frame 
        withDelegate: (id<Watcher3PosSwitchDelegate>) delegate
         withOptions: (NSDictionary *) options 
   withChecklistItem: (ChecklistItem *) checklistItem
{
    self = [super initWithFrame:frame];
    if (self) {
        _delegate = delegate;
        _switchOptions = options;
        _checklistItem = checklistItem;
        
        _slider = [[UISlider alloc] init];
        _backgroundImageView = [[UIImageView alloc] init]; 
        _leftSideLabel = [[UILabel alloc] init];
        _rightSideLabel = [[UILabel alloc] init];
        
        [self addSubview: _backgroundImageView];
        [self addSubview: _leftSideLabel];
        [self addSubview: _rightSideLabel];
        [self addSubview: _slider];
        
        _slider.minimumValue = -1;
        _slider.maximumValue = +1;
        _slider.continuous = NO;
        _slider.value = 0;
        
        [_slider setMinimumTrackImage: [UIImage imageNamed: @"transparent.gif"] forState: UIControlStateNormal];
        [_slider setMaximumTrackImage: [UIImage imageNamed: @"transparent.gif"] forState: UIControlStateNormal];
        [_slider setThumbImage: [UIImage imageNamed: @"slider_thumb"] forState: UIControlStateNormal];
        [_slider addTarget: self action: @selector(snapSliderToValue:) forControlEvents: UIControlEventValueChanged];
        
        _leftSideLabel.font = [UIFont boldSystemFontOfSize: 13];
        _leftSideLabel.backgroundColor = [UIColor clearColor];
        
        _rightSideLabel.font = [UIFont boldSystemFontOfSize: 13];
        _rightSideLabel.backgroundColor = [UIColor clearColor];
        
        _backgroundImageView.image = [UIImage imageNamed: @"slider_neutral"];
        
        [_backgroundImageView release];
        [_leftSideLabel release];
        [_rightSideLabel release];
        [_slider release];
    }

    return self;
}

- (void) layoutSubviews {
    NSString *loText = [_switchOptions objectForKey: @"lo_text"];
    NSString *hiText = [_switchOptions objectForKey: @"hi_text"];
    NSString *loValue = [_switchOptions objectForKey: @"lo_value"];
    NSString *hiValue = [_switchOptions objectForKey: @"hi_value"];

    UIImage *image = nil;
    
    if ( [_checklistItem.value isEqualToString: loValue] ) {
        _slider.value = +1;
        image = [UIImage imageNamed: @"slider_good"];
    } else if ( [_checklistItem.value isEqualToString: hiValue] ) {
        _slider.value = -1;
        image = [UIImage imageNamed: @"slider_bad"];
    }  else {
        _slider.value = 0;
        image = [UIImage imageNamed: @"slider_neutral"];
    }
        
        
    CGSize leftLabelSize = [hiText sizeWithFont: _leftSideLabel.font constrainedToSize: self.bounds.size];
    CGSize rightLabelSize = [loText sizeWithFont: _rightSideLabel.font constrainedToSize: self.bounds.size];
    
    _leftSideLabel.frame = CGRectMake(0, 0, leftLabelSize.width, image.size.height);
    _backgroundImageView.frame = CGRectMake(leftLabelSize.width+5, 0, image.size.width, image.size.height);
    _rightSideLabel.frame = CGRectMake(leftLabelSize.width+image.size.width+10, 0, rightLabelSize.width, image.size.height);
    _slider.frame = _backgroundImageView.frame;
    
    _backgroundImageView.image = image;
    _leftSideLabel.text = hiText;
    _rightSideLabel.text = loText;
}

- (void) snapSliderToValue: (id) sender {
    UISlider *slider = (UISlider *) sender;
    
    NSString *loValue = [_switchOptions objectForKey: @"lo_value"];
    NSString *hiValue = [_switchOptions objectForKey: @"hi_value"];
    
    if ( slider.value >= -1 && slider.value < -0.5 ) {
        slider.value = -1;
        [_delegate switchDidChangeValueTo: hiValue];
    }
    
    if ( slider.value >= -0.5 && slider.value < 0.5 ) {
        slider.value = 0;
        [_delegate switchDidChangeValueTo: nil];
    }
    
    if ( slider.value >= 0.5 && slider.value <= 1 ) {
        slider.value = 1;
        [_delegate switchDidChangeValueTo: loValue];
    }
    
    [self setNeedsLayout];
}


@end
