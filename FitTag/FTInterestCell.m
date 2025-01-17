//
//  DataCellCollectionView.m
//  FitTag
//
//  Created by Kevin Pimentel on 7/1/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#import "FTInterestCell.h"

@interface FTInterestCell () {
    BOOL isSelected;
}
@end

@implementation FTInterestCell
@synthesize interestLabel;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        isSelected = NO;
        
        UIView *lineViewGray = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 1)];
        lineViewGray.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:lineViewGray];
        
        UIView *lineViewWhite = [[UIView alloc] initWithFrame:CGRectMake(0, 1, frame.size.width, 1)];
        lineViewWhite.backgroundColor = [UIColor whiteColor];
        [self addSubview:lineViewWhite];
        
        self.interestLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160, 42)];
        self.interestLabel.textAlignment = NSTextAlignmentCenter;
        self.interestLabel.textColor = [UIColor grayColor];
        self.interestLabel.backgroundColor = [UIColor clearColor];
        //[self.contentView.layer setBorderWidth:1.0f];
        //[self.contentView.layer setBorderColor:[UIColor grayColor].CGColor];
        [self addSubview:self.interestLabel];
    }
    return self;
}

- (void)setCellSelection {
    self.interestLabel.textColor = FT_RED;
    isSelected = YES;
}

- (void)clearCellSelected {
    self.interestLabel.textColor = FT_RED;
    isSelected = NO;
}

- (BOOL)isSelectedToggle {
    if (!isSelected) {
        self.interestLabel.textColor = FT_RED;
    } else {
        self.interestLabel.textColor = [UIColor grayColor];
    }
    
    isSelected = !isSelected;
    return isSelected;
}
@end
