//
//  FTPhotoPostDetailsFooterView.m
//  FitTag
//
//  Created by Kevin Pimentel on 8/25/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#import "FTPostDetailsFooterView.h"
#import "FTUtility.h"

//#define BUTTON_Y 105
#define BUTTON_Y 90
#define BUTTON_W 71
#define BUTTON_H 80

@interface FTPostDetailsFooterView ()
@property (nonatomic, strong) UIView *mainView;
@end

@implementation FTPostDetailsFooterView

@synthesize commentView;
@synthesize mainView;
@synthesize hideDropShadow;
@synthesize hashtagTextField;
//@synthesize locationTextField;
@synthesize submitButton;
@synthesize facebookButton;
@synthesize twitterButton;
@synthesize shareLocationSwitch;
@synthesize delegate;
@synthesize shareLocationLabel;

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        
        CGSize frameSize = self.frame.size;
        
        mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameSize.width, 185)];
        mainView.backgroundColor = FT_GRAY;
        [self addSubview:mainView];
        
        UIImageView *commentBox = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frameSize.width, 185)];
        [mainView addSubview:commentBox];
        
        commentView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, frameSize.width, 45)];
        commentView.font = [UIFont systemFontOfSize:12.0f];
        commentView.returnKeyType = UIReturnKeyDefault;
        commentView.text = CAPTION_TEXT;
        commentView.textColor = [UIColor lightGrayColor];
        commentView.backgroundColor = [UIColor whiteColor];
        [mainView addSubview:commentView];
        
        CGRect commentRect = commentView.frame;
        commentRect.origin.y += commentRect.size.height;
        commentRect.size.height = 40;
        
        UIView *shareLocationView = [[UIView alloc] initWithFrame:commentRect];
        [shareLocationView setBackgroundColor:FT_RED];
        [mainView addSubview:shareLocationView];
        
        shareLocationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 220, 40)];
        [shareLocationLabel setText:@"FitTag your location?"];
        [shareLocationLabel setTextColor:[UIColor whiteColor]];
        [shareLocationLabel setBackgroundColor:[UIColor clearColor]];
        [shareLocationLabel setFont:MULIREGULAR(16)];
        [shareLocationView addSubview:shareLocationLabel];
        
        shareLocationSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(commentRect.size.width - 80, 4, 0, 0)];
        [shareLocationSwitch setOn:NO];
        [shareLocationSwitch addTarget:self action:@selector(didChangeShareLocationSwitch:) forControlEvents:UIControlEventTouchUpInside];
        [shareLocationView addSubview:shareLocationSwitch];
        
        
        /*
        hashtagTextField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 44.0f, 320.0f, 30.0f)];
        hashtagTextField.font = [UIFont systemFontOfSize:12.0f];
        hashtagTextField.returnKeyType = UIReturnKeyDefault;
        hashtagTextField.textColor = [UIColor colorWithRed:73.0f/255.0f green:55.0f/255.0f blue:35.0f/255.0f alpha:1.0f];
        hashtagTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        hashtagTextField.backgroundColor = [UIColor whiteColor];
        hashtagTextField.placeholder = @" TAG THIS...";
        [hashtagTextField setValue:[UIColor colorWithRed:154.0f/255.0f
                                                   green:146.0f/255.0f
                                                    blue:138.0f/255.0f
                                                   alpha:1.0f]
                        forKeyPath:@"_placeholderLabel.textColor"];
        
        [mainView addSubview:hashtagTextField];
        
        
        CGFloat locationTextFieldY = commentField.frame.size.height + commentField.frame.origin.y + 10;
        locationTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, locationTextFieldY, self.frame.size.width, 25)];
        locationTextField.font = [UIFont systemFontOfSize:12.0f];
        locationTextField.returnKeyType = UIReturnKeyDefault;
        locationTextField.textColor = [UIColor colorWithRed:73.0f/255.0f
                                                      green:55.0f/255.0f
                                                       blue:35.0f/255.0f alpha:1.0f];
        locationTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        locationTextField.backgroundColor = [UIColor whiteColor];
        locationTextField.placeholder = EMPTY_STRING;
        locationTextField.userInteractionEnabled = YES;
        [locationTextField setValue:[UIColor colorWithRed:154.0f/255.0f
                                                    green:146.0f/255.0f
                                                     blue:138.0f/255.0f alpha:1.0f]
                         forKeyPath:@"_placeholderLabel.textColor"];
        
        [mainView addSubview:locationTextField];
        */
        
        facebookButton = [UIButton buttonWithType: UIButtonTypeCustom];
        facebookButton.frame = CGRectMake(20.0f, BUTTON_Y, BUTTON_W, BUTTON_H);
        [facebookButton setBackgroundImage:[UIImage imageNamed:IMAGE_SOCIAL_FACEBOOKOFF] forState:UIControlStateNormal];
        [facebookButton setBackgroundImage:[UIImage imageNamed:IMAGE_SOCIAL_FACEBOOK] forState:UIControlStateSelected];
        [facebookButton addTarget:self action:@selector(didTapFacebookShareButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [facebookButton setHidden:YES];
        [mainView addSubview:facebookButton];
         
        twitterButton = [UIButton buttonWithType: UIButtonTypeCustom];
        twitterButton.frame = CGRectMake(110.0f, BUTTON_Y, BUTTON_W, BUTTON_H);
        [twitterButton setBackgroundImage:[UIImage imageNamed:IMAGE_SOCIAL_TWITTEROFF] forState:UIControlStateNormal];
        [twitterButton setBackgroundImage:[UIImage imageNamed:IMAGE_SOCIAL_TWITTER] forState:UIControlStateSelected];
        [twitterButton addTarget:self action:@selector(didTapTwitterShareButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [mainView addSubview:twitterButton];
        
        submitButton = [UIButton buttonWithType: UIButtonTypeCustom];
        submitButton.frame = CGRectMake(230.0f, BUTTON_Y, BUTTON_W, BUTTON_H);
        [submitButton setBackgroundImage:[UIImage imageNamed:@"signup_button"] forState:UIControlStateNormal];
        [submitButton addTarget:self action:@selector(didTapSubmitPostButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [mainView addSubview:submitButton];
    }
    
    return self;
}

#pragma mark - FTDetailsFooterView

+ (CGRect)rectForView {
    return CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 185);
}

#pragma mark - ()

- (void)didChangeShareLocationSwitch:(UISwitch *)lever {
    if (![lever isOn]) {
        return;
    }
    
    if (delegate && [delegate respondsToSelector:@selector(postDetailsFooterView:didChangeShareLocationSwitch:)]) {
        [delegate postDetailsFooterView:self didChangeShareLocationSwitch:lever];
    }
}

- (void)didTapFacebookShareButtonAction:(UIButton *)button {
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [button setSelected:![button isSelected]];
        
        if ([button isSelected]) {
            if ([delegate respondsToSelector:@selector(postDetailsFooterView:didTapFacebookShareButton:)]){
                [delegate postDetailsFooterView:self didTapFacebookShareButton:button];
            }
        }
    } else {
        NSLog(@"is not linked with user...");
        [button setSelected:NO];
        [[[UIAlertView alloc] initWithTitle:@"Facebook Not Linked"
                                    message:@"Please visit the shared settings to link your FaceBook account."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

- (void)didTapTwitterShareButtonAction:(UIButton *)button {
    
    if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
        [button setSelected:![button isSelected]];
        if ([button isSelected]) {
            if ([delegate respondsToSelector:@selector(postDetailsFooterView:didTapTwitterShareButton:)]){
                [delegate postDetailsFooterView:self didTapTwitterShareButton:button];
            }
        }
    } else {
        // Twitter account is not linked
        [[[UIAlertView alloc] initWithTitle:@"Twitter Not Linked"
                                    message:@"Please visit the shared settings to link your Twitter account."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

- (void)didTapSubmitPostButtonAction:(UIButton *)button {
    
    if ([button isSelected])
        return;
    
    [button setSelected:YES];
    
    if ([delegate respondsToSelector:@selector(postDetailsFooterView:didTapSubmitPostButton:)]){
        [delegate postDetailsFooterView:self didTapSubmitPostButton:button];
    }
}

@end
