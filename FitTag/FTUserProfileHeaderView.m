//
//  UITableView+FTProfileCollectionHeaderView.m
//  FitTag
//
//  Created by Kevin Pimentel on 10/4/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#import "FTUserProfileHeaderView.h"
#import "UIImage+ImageEffects.h"

// Collection Filters
#define GRID_IMAGE @"grid_button"
#define GRID_IMAGE_ACTIVE @"grid_button_active"
#define TAGGED_IMAGE @"tagged_button"
#define TAGGED_IMAGE_ACTIVE @"tagged_button_active"
#define POSTS_IMAGE @"posts"
#define POSTS_IMAGE_ACTIVE @"posts_active"

@interface FTUserProfileHeaderView() {
    BOOL isFollowingUser;
}
@property (nonatomic, strong) UIView *profileFilter;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *profilePictureBackgroundView;

@property (nonatomic, strong) UILabel *followerCountLabel;
@property (nonatomic, strong) UILabel *followingCountLabel;
@property (nonatomic, strong) UILabel *userSettingsLabel;
@property (nonatomic, strong) UILabel *userDisplay;

@property (nonatomic, strong) UIImageView *photoCountIconImageView;
@property (nonatomic, strong) UIImageView *coverPhoto;
@property (nonatomic, strong) PFImageView *profilePictureImageView;
@property (nonatomic, strong) PFImageView *coverPhotoImageView;

@property (nonatomic, strong) UITextView *profileBiography;

@property (nonatomic, strong) UIButton *gridViewButton;
@property (nonatomic, strong) UIButton *businessButton;
@property (nonatomic, strong) UIButton *taggedInButton;
@end

@implementation FTUserProfileHeaderView
@synthesize profileFilter;
@synthesize followerCountLabel;
@synthesize photoCountIconImageView;
@synthesize followingCountLabel;
@synthesize userSettingsLabel;
@synthesize profilePictureImageView;
@synthesize profilePictureBackgroundView;
@synthesize profileBiography;
@synthesize gridViewButton;
@synthesize businessButton;
@synthesize taggedInButton;
@synthesize coverPhoto;
@synthesize userDisplay;
@synthesize delegate;
@synthesize coverPhotoImageView;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        
        self.clipsToBounds = YES;
        self.containerView.clipsToBounds = YES;
        self.superview.clipsToBounds = YES;
    
        self.containerView = [[UIView alloc] initWithFrame:frame];
        [self.containerView setBackgroundColor:[UIColor whiteColor]];
        
        // Profile Picture Background (this is the view area)
        profilePictureBackgroundView = [[UIView alloc] initWithFrame:CGRectMake( 0, 0, self.frame.size.width, self.frame.size.width / 2)];
        [profilePictureBackgroundView setBackgroundColor:[UIColor clearColor]];
        [profilePictureBackgroundView setAlpha: 0.0f];
        [profilePictureBackgroundView setClipsToBounds: YES];
        [self.containerView addSubview:profilePictureBackgroundView];
        
        // Profile Picture Image
        profilePictureImageView = [[PFImageView alloc] initWithFrame:CGRectMake( 0, 0, self.frame.size.width, self.frame.size.width / 2)];
        [profilePictureImageView setClipsToBounds: YES];
        [profilePictureImageView setContentMode:UIViewContentModeScaleAspectFill];
        [self.containerView addSubview:profilePictureImageView];
        
        // Cover Photo
        coverPhotoImageView = [[PFImageView alloc] initWithFrame:CGRectMake( 0, 0, self.frame.size.width, self.frame.size.width / 2)];
        [coverPhotoImageView setClipsToBounds: YES];
        [coverPhotoImageView setContentMode:UIViewContentModeScaleAspectFill];
        [self.containerView addSubview:coverPhotoImageView];
        
        UIImageView *profileHexagon = [FTUtility getProfileHexagonWithX:5 Y:40 width:100 hegiht:115];
        //[profileHexagon setCenter:CGPointMake((self.frame.size.width / 2), 10 + (profileHexagon.frame.size.height / 2))];
        [profilePictureImageView setContentMode:UIViewContentModeScaleAspectFill];
        profilePictureImageView.frame = profileHexagon.frame;
        profilePictureImageView.layer.mask = profileHexagon.layer.mask;
        profilePictureImageView.alpha = 0.0f;
        
        // Followers count UILabel
        CGFloat followLabelsY = profilePictureBackgroundView.frame.size.height;
        CGFloat followLabelsWidth = self.containerView.bounds.size.width / 2;
        
        UITapGestureRecognizer *followerLabelTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                  action:@selector(didTapFollowerAction:)];
        [followerLabelTapGesture setNumberOfTapsRequired:1];
        
        followerCountLabel = [[UILabel alloc] init];
        [followerCountLabel setFrame:CGRectMake(0, followLabelsY, followLabelsWidth, 30)];
        [followerCountLabel setTextAlignment:NSTextAlignmentCenter];
        [followerCountLabel setBackgroundColor:[UIColor whiteColor]];
        [followerCountLabel setTextColor:[UIColor blackColor]];
        [followerCountLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
        [followerCountLabel.layer setBorderColor:[UIColor colorWithRed:234/255.0f green:234/255.0f blue:234/255.0f alpha:1].CGColor];
        [followerCountLabel.layer setBorderWidth:1.0f];
        [followerCountLabel setUserInteractionEnabled:YES];
        [followerCountLabel addGestureRecognizer:followerLabelTapGesture];
        [followerCountLabel setText:@"0 FOLLOWERS"];
        [self.containerView addSubview:followerCountLabel];
        
        
        UITapGestureRecognizer *followingLabelTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                   action:@selector(didTapFollowingAction:)];
        [followingLabelTapGesture setNumberOfTapsRequired:1];
        
        // Following count UILabel
        followingCountLabel = [[UILabel alloc] init];
        [followingCountLabel setFrame:CGRectMake(followerCountLabel.frame.size.width + 1, followLabelsY, followLabelsWidth, 30)];
        [followingCountLabel setTextAlignment:NSTextAlignmentCenter];
        [followingCountLabel setBackgroundColor:[UIColor whiteColor]];
        [followingCountLabel setTextColor:[UIColor blackColor]];
        [followingCountLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
        [followingCountLabel.layer setBorderColor:[UIColor colorWithRed:234/255.0f green:234/255.0f blue:234/255.0f alpha:1].CGColor];
        [followingCountLabel.layer setBorderWidth:1.0f];
        [followingCountLabel setUserInteractionEnabled:YES];
        [followingCountLabel addGestureRecognizer:followingLabelTapGesture];
        [followingCountLabel setText:@"0 FOLLOWING"];
        [self.containerView addSubview:followingCountLabel];
        
        // User settings UILabel
        CGFloat userSettingsLabelY = followingCountLabel.frame.size.height + followLabelsY;
        userSettingsLabel = [[UILabel alloc] init];
        [userSettingsLabel setFrame:CGRectMake(0, userSettingsLabelY, self.containerView.bounds.size.width, 30)];
        [userSettingsLabel setTextAlignment:NSTextAlignmentCenter];
        [userSettingsLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
        [userSettingsLabel setBackgroundColor:[UIColor whiteColor]];
        [userSettingsLabel setTextColor:[UIColor whiteColor]];
        
        [self.containerView addSubview:userSettingsLabel];
        [self.containerView bringSubviewToFront:userSettingsLabel];
        
        // User bio text view
        profileBiography = [[UITextView alloc] initWithFrame:CGRectMake(0, userSettingsLabel.frame.origin.y +
                                                                        userSettingsLabel.frame.size.height,
                                                                        self.frame.size.width, 55)];
        
        [profileBiography setBackgroundColor:[UIColor whiteColor]];
        [profileBiography setTextColor:[UIColor blackColor]];
        [profileBiography setFont:[UIFont boldSystemFontOfSize:14.0f]];
        [profileBiography setText:EMPTY_STRING];
        [profileBiography setUserInteractionEnabled:NO];
        
        [self.containerView addSubview:profileBiography];
        
        // Image filter
        profileFilter = [[UIView alloc] initWithFrame:CGRectMake(0, profileBiography.frame.size.height + profileBiography.frame.origin.y,self.frame.size.width, 60)];
        [profileFilter setBackgroundColor:[UIColor whiteColor]];
        
        gridViewButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [gridViewButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [gridViewButton setBackgroundImage:[UIImage imageNamed:GRID_IMAGE] forState:UIControlStateNormal];
        [gridViewButton setBackgroundImage:[UIImage imageNamed:GRID_IMAGE_ACTIVE] forState:UIControlStateSelected];
        [gridViewButton setFrame:CGRectMake(0, 0, 35, 35)];
        [gridViewButton setCenter:CGPointMake( 20 + gridViewButton.frame.size.width, profileFilter.frame.size.height / 2)];
        [gridViewButton addTarget:self action:@selector(didTapGridButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [gridViewButton setSelected:YES];
        [profileFilter addSubview:gridViewButton];
        
        businessButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [businessButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [businessButton setBackgroundImage:[UIImage imageNamed:POSTS_IMAGE] forState:UIControlStateNormal];
        [businessButton setBackgroundImage:[UIImage imageNamed:POSTS_IMAGE_ACTIVE] forState:UIControlStateSelected];
        [businessButton setFrame:CGRectMake(0, 0, 30, 35)];
        [businessButton setCenter:CGPointMake(self.frame.size.width / 2, profileFilter.frame.size.height / 2)];
        [businessButton addTarget:self action:@selector(didTapBusinessButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [businessButton setSelected:NO];
        [profileFilter addSubview:businessButton];
        
        taggedInButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [taggedInButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [taggedInButton setBackgroundImage:[UIImage imageNamed:TAGGED_IMAGE] forState:UIControlStateNormal];
        [taggedInButton setBackgroundImage:[UIImage imageNamed:TAGGED_IMAGE_ACTIVE] forState:UIControlStateSelected];
        [taggedInButton setFrame:CGRectMake(0, 0, 30, 35)];
        [taggedInButton setCenter:CGPointMake(self.frame.size.width - taggedInButton.frame.size.width - 20, profileFilter.frame.size.height / 2)];
        [taggedInButton addTarget:self action:@selector(didTapTaggedButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [taggedInButton setSelected:NO];
        [profileFilter addSubview:taggedInButton];
        
        /* // User display label
        userDisplay = [[UILabel alloc] initWithFrame:CGRectMake(0,0,self.frame.size.width,30)];
        [userDisplay setTextAlignment:NSTextAlignmentCenter];
        [userDisplay setBackgroundColor:[UIColor clearColor]];
        [userDisplay setTextColor:[UIColor whiteColor]];
        [userDisplay setFont:[UIFont boldSystemFontOfSize:14.0f]];
        [userDisplay setText:@"Test"];
        [userDisplay setCenter:CGPointMake((self.containerView.frame.size.width / 2),130)];
        [self.containerView addSubview:userDisplay];
        */
        
        [self.containerView addSubview:profileFilter];
        [self addSubview:self.containerView]; // Add the view
    }
    return self;
}

#pragma mark - ()


- (void)didTapFollowerAction:(id)sender {
    //NSLog(@"- (void)didTapFollowerAction:(id)sender;");
    if(delegate && [delegate respondsToSelector:@selector(userProfileCollectionHeaderView:didTapFollowersButton:)]){
        [delegate userProfileCollectionHeaderView:self didTapFollowersButton:sender];
    }
}

- (void)didTapFollowingAction:(id)sender {
    //NSLog(@"- (void)didTapFollowingAction:(id)sender;");
    if(delegate && [delegate respondsToSelector:@selector(userProfileCollectionHeaderView:didTapFollowingButton:)]){
        [delegate userProfileCollectionHeaderView:self didTapFollowingButton:sender];
    }
}

- (void)didTapGridButtonAction:(UIButton *)button {
    //NSLog(@"%@::didTapGridButtonAction:",VIEWCONTROLLER_USER_HEADER);
    if (![gridViewButton isSelected]) {
        [self resetSelectedProfileFilterButtons];
        [gridViewButton setSelected:YES];
        if(delegate && [delegate respondsToSelector:@selector(userProfileCollectionHeaderView:didTapGridButton:)]){
            [delegate userProfileCollectionHeaderView:self didTapGridButton:button];
        }
    }
}

- (void)didTapBusinessButtonAction:(UIButton *)button {
    //NSLog(@"%@::didTapBusinessButtonAction:",VIEWCONTROLLER_USER_HEADER);
    if (![businessButton isSelected]) {
        [self resetSelectedProfileFilterButtons];
        [businessButton setSelected:YES];
        if(delegate && [delegate respondsToSelector:@selector(userProfileCollectionHeaderView:didTapBusinessButton:)]){
            [delegate userProfileCollectionHeaderView:self didTapBusinessButton:button];
        }
    }
}

- (void)didTapTaggedButtonAction:(UIButton *)button {
    //NSLog(@"%@::didTapTaggedButtonAction:",VIEWCONTROLLER_USER_HEADER);
    if (![taggedInButton isSelected]) {
        [self resetSelectedProfileFilterButtons];
        [taggedInButton setSelected:YES];
        if(delegate && [delegate respondsToSelector:@selector(userProfileCollectionHeaderView:didTapTaggedButton:)]){
            [delegate userProfileCollectionHeaderView:self didTapTaggedButton:button];
        }
    }
}

- (void)didTapSettingsButtonAction:(id)sender {
    //NSLog(@"%@::didTapTaggedButtonAction:",VIEWCONTROLLER_USER_HEADER);
    if(delegate && [delegate respondsToSelector:@selector(userProfileCollectionHeaderView:didTapSettingsButton:)]){
        [delegate userProfileCollectionHeaderView:self didTapSettingsButton:sender];
    }
}

- (void)resetSelectedProfileFilterButtons {
    [gridViewButton setSelected:NO];
    [taggedInButton setSelected:NO];
    [businessButton setSelected:NO];
}

- (void)fetchUserProfileData:(PFUser *)aUser {
    
    //NSLog(@"- (void)fetchUserProfileData:(PFUser *)aUser: %@",aUser);
    
    if (!aUser) {
        [NSException raise:NSInvalidArgumentException format:@"user cannot be nil"];
    }
    
    [self updateFollowingCount];
    
    PFFile *coverPhotoFile = [self.user objectForKey:kFTUserCoverPhotoKey];
    if (coverPhotoFile) {
        [coverPhotoImageView setFile:coverPhotoFile];
        [coverPhotoImageView loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) {
                coverPhoto = [[UIImageView alloc] initWithImage:image];
                coverPhoto.frame = self.bounds;
                coverPhoto.alpha = 0.0f;
                coverPhoto.clipsToBounds = YES;
                
                [self.containerView addSubview:coverPhoto];
                [self.containerView sendSubviewToBack:coverPhoto];
                
                [UIView animateWithDuration:0.2f animations:^{
                    coverPhoto.alpha = 1.0f;
                }];
            }
        }];
    }
    
    PFFile *imageFile = [self.user objectForKey:kFTUserProfilePicMediumKey];
    if (imageFile) {
        [profilePictureImageView setFile:imageFile];
        [profilePictureImageView loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) {
                [UIView animateWithDuration:0.2f animations:^{
                    profilePictureBackgroundView.alpha = 1.0f;
                    profilePictureImageView.alpha = 1.0f;
                    [self.containerView bringSubviewToFront:profilePictureImageView];
                }];
            }
        }];
    }
    
    NSDictionary *followingDictionary = [[PFUser currentUser] objectForKey:@"FOLLOWING"];
    if (followingDictionary) {
        [followingCountLabel setText:[NSString stringWithFormat:@"%lu FOLLOWING", (unsigned long)[[followingDictionary allValues] count]]];
    }
    
    PFQuery *queryFollowingCount = [PFQuery queryWithClassName:kFTActivityClassKey];
    [queryFollowingCount whereKey:kFTActivityTypeKey equalTo:kFTActivityTypeFollow];
    [queryFollowingCount whereKey:kFTActivityFromUserKey equalTo:self.user];
    [queryFollowingCount setCachePolicy:kPFCachePolicyCacheElseNetwork];
    [queryFollowingCount countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            [followingCountLabel setText:[NSString stringWithFormat:@"%d FOLLOWING", number]];
        }
    }];
    
    // check to see if it is not current users profile
    if (![[self.user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        //NSLog(@"Viewing someone elses profile.");
        UIActivityIndicatorView *loadingActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [loadingActivityIndicatorView startAnimating];
        //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingActivityIndicatorView];
        
        // check if the currentUser is following this user
        PFQuery *queryIsFollowing = [PFQuery queryWithClassName:kFTActivityClassKey];
        [queryIsFollowing whereKey:kFTActivityTypeKey equalTo:kFTActivityTypeFollow];
        [queryIsFollowing whereKey:kFTActivityToUserKey equalTo:self.user];
        [queryIsFollowing whereKey:kFTActivityFromUserKey equalTo:[PFUser currentUser]];
        [queryIsFollowing setCachePolicy:kPFCachePolicyCacheThenNetwork];
        [queryIsFollowing countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
            if (error && [error code] != kPFErrorCacheMiss) {
                //NSLog(@"Couldn't determine follow relationship: %@", error);
                //self.navigationItem.rightBarButtonItem = nil;
            } else {
                if (number == 0) {
                    [self configureFollowButton];
                } else {
                    [self configureUnfollowButton];
                }
            }
        }];
    } else {
        
        //NSLog(@"Vieweing own profile.");
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapSettingsButtonAction:)];
        tap.numberOfTapsRequired = 1;
        
        [userSettingsLabel setBackgroundColor:[UIColor colorWithRed:234/255.0f green:234/255.0f blue:234/255.0f alpha:1]];
        [userSettingsLabel setTextColor:[UIColor colorWithRed:234/255.0f green:37/255.0f blue:37/255.0f alpha:1]];
        [userSettingsLabel setText:NAVIGATION_TITLE_SETTINGS];
        [userSettingsLabel addGestureRecognizer:tap];
        [userSettingsLabel setUserInteractionEnabled:YES];
    }
    
    [profileBiography setText:[self.user objectForKey:kFTUserBioKey]];
}

- (void)configureFollowButton {
    //NSLog(@"NOT FOLLOWING USER");
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(followButtonAction:)];
    tap.numberOfTapsRequired = 1;
    
    [[FTCache sharedCache] setFollowStatus:NO user:self.user];
    [userSettingsLabel setText:[NSString stringWithFormat:@"FOLLOW %@",[self.user objectForKey: kFTUserDisplayNameKey]]];
    [userSettingsLabel setBackgroundColor:[UIColor colorWithRed:234/255.0f green:234/255.0f blue:234/255.0f alpha:1]];
    [userSettingsLabel setTextColor:[UIColor redColor]];
    [userSettingsLabel addGestureRecognizer:tap];
    [userSettingsLabel setUserInteractionEnabled:YES];
}

- (void)configureUnfollowButton {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(unfollowButtonAction:)];
    tap.numberOfTapsRequired = 1;
    
    [[FTCache sharedCache] setFollowStatus:YES user:self.user];
    [userSettingsLabel setText:[NSString stringWithFormat:@"FOLLOWING %@",[self.user objectForKey: kFTUserDisplayNameKey]]];
    [userSettingsLabel setBackgroundColor:[UIColor redColor]];
    [userSettingsLabel setTextColor:[UIColor whiteColor]];
    [userSettingsLabel addGestureRecognizer:tap];
    [userSettingsLabel setUserInteractionEnabled:YES];
}

- (void)followButtonAction:(id)sender {
    UIActivityIndicatorView *loadingActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [loadingActivityIndicatorView startAnimating];
    [self configureUnfollowButton];
    [FTUtility followUserEventually:self.user block:^(BOOL succeeded, NSError *error) {
        if (error) {
            [self configureFollowButton];
        }
        
        if (succeeded) {
            NSLog(@"followButtonAction::succeeded");
            [self updateFollowingCount];
        } else {
            NSLog(@"followButtonAction::error");
        }
    }];
}

- (void)unfollowButtonAction:(id)sender {
    UIActivityIndicatorView *loadingActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [loadingActivityIndicatorView startAnimating];
    [self configureFollowButton];
    [FTUtility unfollowUserEventually:self.user block:^(NSError *error) {
        if (error) {
            [self configureUnfollowButton];
        }
        
        if (!error) {
            NSLog(@"unfollowButtonAction::succeeded");
            [self updateFollowingCount];
        } else {
            NSLog(@"unfollowButtonAction::error");
        }
    }];
}

- (void)updateFollowingCount {
    PFQuery *queryFollowerCount = [PFQuery queryWithClassName:kFTActivityClassKey];
    [queryFollowerCount whereKey:kFTActivityTypeKey equalTo:kFTActivityTypeFollow];
    [queryFollowerCount whereKey:kFTActivityToUserKey equalTo:self.user];
    [queryFollowerCount setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [queryFollowerCount countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            [followerCountLabel setText:[NSString stringWithFormat:@"%d FOLLOWER%@", number, number==1?@"":@"S"]];
        }
    }];
}

@end
