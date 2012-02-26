//
//  WatcherInfoHeaderView.m
//  ElectionsWatcher
//
//  Created by xfire on 26.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherInfoHeaderView.h"

@implementation WatcherInfoHeaderView

@synthesize textLabel = _textLabel;
@synthesize infoButton = _infoButton;

- (id)initWithFrame:(CGRect)frame withTitle: (NSString *) title
{
    self = [super initWithFrame:frame];

    if (self) {
        _textLabel = [[UILabel alloc] initWithFrame: CGRectZero];
        _infoButton = [UIButton buttonWithType: UIButtonTypeInfoDark];
        
        _textLabel.text = title;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textColor = [UIColor colorWithRed:0.265 green:0.294 blue:0.367 alpha:1.000];
        _textLabel.shadowColor = [UIColor colorWithWhite: 1 alpha: 1];
        _textLabel.shadowOffset = CGSizeMake(0, 1);
        _textLabel.font = [UIFont boldSystemFontOfSize: 17];
        _textLabel.numberOfLines = 1;
        _textLabel.textAlignment = UITextAlignmentLeft;
        
        self.backgroundColor = [UIColor clearColor];
        
        [self addSubview: _textLabel];
        [self addSubview: _infoButton];
        
        [_textLabel release];
    }
    
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    _textLabel.frame    = CGRectMake(20, 0, self.bounds.size.width-self.bounds.size.height-20, self.bounds.size.height);
    _infoButton.frame   = CGRectMake(self.bounds.size.width-self.bounds.size.height-10, 0, self.bounds.size.height, self.bounds.size.height);
}

@end
