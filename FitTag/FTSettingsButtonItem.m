//
//  FTSettingsButtonItem.m
//  FitTag
//
//  Created by Kevin Pimentel on 7/26/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#import "FTSettingsButtonItem.h"

@implementation FTSettingsButtonItem

#pragma mark - Initialization

- (id)initWithTarget:(id)target action:(SEL)action {
    
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self = [super initWithCustomView:settingsButton];
    if (self) {
        //        [settingsButton setBackgroundImage:[UIImage imageNamed:@"ButtonSettings.png"] forState:UIControlStateNormal];
        [settingsButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        [settingsButton setFrame:CGRectMake(0.0f, 0.0f, 35.0f, 32.0f)];
        [settingsButton setImage:[UIImage imageNamed:@"ButtonImageSettings.png"] forState:UIControlStateNormal];
        [settingsButton setImage:[UIImage imageNamed:@"ButtonImageSettingsSelected.png"] forState:UIControlStateHighlighted];
    }
    
    return self;
}

@end
