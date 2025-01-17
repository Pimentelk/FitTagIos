//
//  UITableView+FTProfileTimelineViewController.m
//  FitTag
//
//  Created by Kevin Pimentel on 10/4/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#import "FTBusinessProfileViewController.h"
#import "FTUserProfileViewController.h"
#import "FTUserProfileCollectionViewCell.h"
#import "FTPostDetailsViewController.h"
#import "FTCamViewController.h"
#import "FTSettingsViewController.h"
#import "FTViewFriendsViewController.h"
#import "FTSearchViewController.h"

#define GRID_SMALL @"SMALLGRID"
#define GRID_FULL @"FULGRID"
#define GRID_BUSINESS @"BUSINESS"
#define GRID_TAGGED @"TAGGED"

#define DATACELL @"DataCell"
#define HEADERVIEW @"HeaderView"

@interface FTUserProfileViewController() <UICollectionViewDataSource,UICollectionViewDelegate> {
    NSString *cellTab;
}
@property (nonatomic, strong) NSArray *cells;
@property (nonatomic, strong) FTViewFriendsViewController *viewFriendsViewController;
@property (nonatomic, strong) FTUserProfileHeaderView *headerView;
@property (nonatomic, strong) FTSearchViewController *searchViewController;
@property (nonatomic, strong) FTBusinessProfileViewController *businessProfileViewController;
@property (nonatomic, strong) FTUserProfileViewController *userProfileViewController;
@property (nonatomic, strong) FTFollowFriendsViewController *followFriendsViewController;
//@property int threshold;
@end

@implementation FTUserProfileViewController
@synthesize user;
@synthesize viewFriendsViewController;
@synthesize searchViewController;
@synthesize businessProfileViewController;
@synthesize followFriendsViewController;
@synthesize userProfileViewController;
@synthesize headerView;
//@synthesize threshold;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTUtilityUserFollowersChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTUtilityUserFollowingChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTProfileDidChangeBioNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTProfileDidChangeProfilePhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTProfileDidChangeCoverPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTTabBarControllerDidFinishEditingPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FTTimelineViewControllerUserDeletedPostNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.user) {
        [NSException raise:NSInvalidArgumentException format:IF_USER_NOT_SET_MESSAGE];
        return;
    }
    
    // Add observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFollowersAction:) name:FTUtilityUserFollowersChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFollowingAction:) name:FTUtilityUserFollowingChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeBioAction:) name:FTProfileDidChangeBioNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeProfilePhotoAction:) name:FTProfileDidChangeProfilePhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeCoverPhotoAction:) name:FTProfileDidChangeCoverPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidPublishPost:) name:FTTabBarControllerDidFinishEditingPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidDeletePost:) name:FTTimelineViewControllerUserDeletedPostNotification object:nil];

    headerView = nil;
    
    cellTab = GRID_SMALL;
    
    // tresh hold
    //threshold = 3;
    
    // Show navigation bar
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,nil];
    self.navigationController.navigationBar.barTintColor = FT_RED;
    
    // Set Background
    [self.collectionView setBackgroundColor:[UIColor whiteColor]];
    
    // Data view
    [self.collectionView registerClass:[FTUserProfileCollectionViewCell class]
            forCellWithReuseIdentifier:DATACELL];
    
    [self.collectionView registerClass:[FTUserProfileHeaderView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:HEADERVIEW];
    
    [self.collectionView setDelegate:self];
    [self.collectionView setDataSource:self];
    
    UIBarButtonItem *backIndicator = [[UIBarButtonItem alloc] init];
    [backIndicator setImage:[UIImage imageNamed:NAVIGATION_BAR_BUTTON_BACK]];
    [backIndicator setStyle:UIBarButtonItemStylePlain];
    [backIndicator setTarget:self];
    [backIndicator setAction:@selector(didTapBackButtonAction:)];
    [backIndicator setTintColor:[UIColor whiteColor]];
        
    viewFriendsViewController = [[FTViewFriendsViewController alloc] init];
    [viewFriendsViewController.navigationItem setLeftBarButtonItem:backIndicator];
    [viewFriendsViewController setUser:self.user];
    
    searchViewController = [[FTSearchViewController alloc] init];
    [searchViewController.navigationItem setLeftBarButtonItem:backIndicator];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(self.view.frame.size.width/3,105)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:0];
    [flowLayout setSectionInset:UIEdgeInsetsMake(0,0,0,0)];
    [flowLayout setHeaderReferenceSize:CGSizeMake(self.view.frame.size.width,PROFILE_HEADER_VIEW_HEIGHT_BUSINESS)];
    
    // Business profile
    businessProfileViewController = [[FTBusinessProfileViewController alloc] initWithCollectionViewLayout:flowLayout];
    [businessProfileViewController.navigationItem setLeftBarButtonItem:backIndicator];
    
    // User profile
    userProfileViewController = [[FTUserProfileViewController alloc] initWithCollectionViewLayout:flowLayout];
    [userProfileViewController.navigationItem setLeftBarButtonItem:backIndicator];
    
    // Show suggestions if mention not found
    followFriendsViewController = [[FTFollowFriendsViewController alloc] initWithStyle:UITableViewStylePlain];
    [followFriendsViewController.navigationItem setLeftBarButtonItem:backIndicator];
}

- (void)setUser:(PFUser *)aUser {
    user = aUser;
    [self queryForTable:self.user];
}

- (void)viewWillAppear:(BOOL)animated{
    //NSLog(@"%@::viewWillAppear:",VIEWCONTROLLER_USER);
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES];
    
    // Toolbar & Navigationbar Setup
    if ([user objectForKey:kFTUserDisplayNameKey]) {
        [self.navigationItem setTitle:[user objectForKey:kFTUserDisplayNameKey]];
    } else {
        [self.navigationItem setTitle:NAVIGATION_TITLE_PROFILE];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    //NSLog(@"%@::viewDidAppear:",VIEWCONTROLLER_USER);
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:VIEWCONTROLLER_USER];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillDisappear:(BOOL)animated{
    //NSLog(@"%@::viewWillDisappear:",VIEWCONTROLLER_USER);
    [super viewWillDisappear:animated];
    
    // Get the classname of the next view controller
    NSUInteger numberOfViewControllersOnStack = [self.navigationController.viewControllers count];
    UIViewController *parentViewController = self.navigationController.viewControllers[numberOfViewControllersOnStack-1];
    Class parentVCClass = [parentViewController class];
    NSString *className = NSStringFromClass(parentVCClass);
    if([className isEqual:VIEWCONTROLLER_CAM]){
        [self.navigationController setToolbarHidden:YES];
    }
}

- (void)queryForTable:(PFUser *)aUser {
    //NSLog(@"%@::queryForTable:",VIEWCONTROLLER_USER);
    // Show HUD view
    PFQuery *postsFromUserQuery = [PFQuery queryWithClassName:kFTPostClassKey];
    [postsFromUserQuery whereKey:kFTPostUserKey equalTo:aUser];
    [postsFromUserQuery whereKey:kFTPostTypeKey containedIn:@[kFTPostTypeImage,kFTPostTypeVideo,kFTPostTypeGallery]];
    [postsFromUserQuery orderByDescending:@"createdAt"];
    [postsFromUserQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    [postsFromUserQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.cells = objects;
            [self.collectionView reloadData];
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

#pragma mark - UICollectionView

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%@::collectionView:viewForSupplementaryElementOfKind:atIndexPath:",VIEWCONTROLLER_USER);
    UICollectionReusableView *reusableview = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                        withReuseIdentifier:HEADERVIEW
                                                               forIndexPath:indexPath];
        
        [headerView setDelegate:self];
        [headerView setUser:self.user];
        [headerView fetchUserProfileData:self.user];
        reusableview = headerView;
    }
    return reusableview;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {

    NSString *content = [self.user objectForKey:kFTUserBioKey];
    NSString *website = [self.user objectForKey:kFTUserWebsiteKey];
    
    if (website) {
        content = [NSString stringWithFormat:@"%@\n%@",content,[self.user objectForKey:kFTUserWebsiteKey]];
    }
    
    CGFloat height = [FTUtility findHeightForText:content havingWidth:self.view.frame.size.width AndFont:SYSTEMFONTBOLD(14)];
    CGSize headerSize = CGSizeMake(self.view.frame.size.width, height + PROFILE_HEADER_VIEW_HEIGHT + 15);
    
    return headerSize;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.cells.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"indexpath: %ld",(long)indexPath.row);
    if ([cellTab isEqualToString:kFTUserTypeBusiness]) {
        PFUser *business = self.cells[indexPath.row];
        //NSLog(@"FTUserProfileCollectionViewController:: business: %@",business);
        if (business) {
            [businessProfileViewController setBusiness:business];
            [self.navigationController pushViewController:businessProfileViewController animated:YES];
        }
    } else {
        FTPostDetailsViewController *postDetailView = [[FTPostDetailsViewController alloc] initWithPost:self.cells[indexPath.row] AndType:nil];
        [self.navigationController pushViewController:postDetailView animated:YES];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%@::collectionView:cellForItemAtIndexPath:",VIEWCONTROLLER_USER);
    // Set up cell identifier that matches the Storyboard cell name
    static NSString *identifier = DATACELL;
    
    FTUserProfileCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    if ([cell isKindOfClass:[FTUserProfileCollectionViewCell class]]) {
        cell.backgroundColor = [UIColor clearColor];
        if ([cellTab isEqualToString:kFTUserTypeBusiness]) {
            //NSLog(@"self.cells: %@", self.cells[indexPath.row]);
            PFUser *business = self.cells[indexPath.row];
            [cell setUser:business];
        } else {
            PFObject *object = self.cells[indexPath.row];
            [cell setPost:object];
        }
    }
    return cell;
}

#pragma mark - Navigation Bar

- (void)didTapLoadCameraButtonAction:(id)sender {
    //NSLog(@"%@::didTapLoadCameraButtonAction:",VIEWCONTROLLER_USER);
    FTCamViewController *camViewController = [[FTCamViewController alloc] init];
    [self.navigationController pushViewController:camViewController animated:YES];
}

- (void)didTapBackButtonAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - FTUserProfileCollectionHeaderViewDelegate

/*
- (void)userProfileCollectionHeaderView:(FTUserProfileHeaderView *)userProfileCollectionHeaderView
                       didTapGridButton:(UIButton *)button {
    //NSLog(@"%@::userProfileCollectionHeaderView:didTapGridButton:",VIEWCONTROLLER_USER);
    cellTab = GRID_SMALL;
    [self queryForTable:self.user];
}

- (void)userProfileCollectionHeaderView:(FTUserProfileHeaderView *)userProfileCollectionHeaderView
                   didTapBusinessButton:(UIButton *)button {
    //NSLog(@"%@::userProfileCollectionHeaderView:didTapBusinessButton:",VIEWCONTROLLER_USER);
    
    cellTab = kFTUserTypeBusiness; // kFTUserTypeBusiness | SMALLGRID | FULLGRID | TAGGED
    //[MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    PFQuery *followingBusinessActivitiesQuery = [PFQuery queryWithClassName:kFTActivityClassKey];
    [followingBusinessActivitiesQuery whereKey:kFTActivityTypeKey equalTo:kFTActivityTypeFollow];
    [followingBusinessActivitiesQuery whereKey:kFTActivityFromUserKey equalTo:[PFUser currentUser]];
    [followingBusinessActivitiesQuery includeKey:kFTActivityToUserKey];
    followingBusinessActivitiesQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [followingBusinessActivitiesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *businesses = [[NSMutableArray alloc] init];
            for (PFObject *object in objects){
                PFUser *business = [object objectForKey:kFTActivityToUserKey];
                if ([[business objectForKey:kFTUserTypeKey] isEqualToString:kFTUserTypeBusiness]) {
                    [businesses addObject:business];
                }
            }
            self.cells = businesses;
            //[MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
            [self.collectionView reloadData];
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (void)userProfileCollectionHeaderView:(FTUserProfileHeaderView *)userProfileCollectionHeaderView
                     didTapTaggedButton:(UIButton *)button {
    //NSLog(@"%@::userProfileCollectionHeaderView:didTapTaggedButton:",VIEWCONTROLLER_USER);
    
    cellTab = GRID_TAGGED;
    NSMutableString *displayName = [[self.user objectForKey:kFTUserDisplayNameKey] mutableCopy];
    NSString *mentionTag = [displayName stringByReplacingOccurrencesOfString:@"@"
                                                                  withString:EMPTY_STRING];
    
    NSMutableArray *userMention = [[NSMutableArray alloc] init];
    [userMention addObject:[NSString stringWithFormat:@"%@",mentionTag]];
    
    //[MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    PFQuery *postsWhereMentionedQuery = [PFQuery queryWithClassName:kFTActivityClassKey];
    [postsWhereMentionedQuery whereKey:kFTActivityMentionKey containedIn:userMention];
    [postsWhereMentionedQuery includeKey:kFTActivityPostKey];
    [postsWhereMentionedQuery setCachePolicy: kPFCachePolicyNetworkOnly];
    [postsWhereMentionedQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *posts = [[NSMutableArray alloc] init];
            for (PFObject *activity in objects) {
                if ([activity objectForKey:kFTActivityPostKey]) {
                    [posts addObject:[activity objectForKey:kFTActivityPostKey]];
                }
            }
            self.cells = posts;
            //[MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
            [self.collectionView reloadData];
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}
*/
- (void)userProfileHeaderView:(FTUserProfileHeaderView *)userProfileHeaderView
         didTapSettingsButton:(id)sender {
    //NSLog(@"%@::userProfileHeaderView:didTapSettingsButton:",VIEWCONTROLLER_USER);
    
    FTSettingsViewController *settingsViewController = [[FTSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    UINavigationController *navController = [[UINavigationController alloc] init];
    [navController setViewControllers:@[settingsViewController] animated:NO];
    [self presentViewController:navController animated:YES completion:^(){
        
    }];
}

- (void)userProfileHeaderView:(FTUserProfileHeaderView *)userProfileHeaderView
        didTapFollowersButton:(id)sender {
    
    [viewFriendsViewController queryForFollowers];
    [self.navigationController pushViewController:viewFriendsViewController animated:YES];
}

- (void)userProfileHeaderView:(FTUserProfileHeaderView *)userProfileHeaderView
        didTapFollowingButton:(id)sender {
    
    [viewFriendsViewController queryForFollowing];
    [self.navigationController pushViewController:viewFriendsViewController animated:YES];
}

- (void)userProfileHeaderView:(FTUserProfileHeaderView *)userProfileHeaderView didTapHashtag:(NSString *)Hashtag {
    
    if (searchViewController) {
        [searchViewController setSearchQueryType:FTSearchQueryTypeFitTag];
        [searchViewController setSearchString:Hashtag];
        [self.navigationController pushViewController:searchViewController animated:YES];
    }
}

- (void)userProfileHeaderView:(FTUserProfileHeaderView *)userProfileHeaderView didTapUserMention:(NSString *)mention {
    
    NSString *lowercaseStringWithoutSymbols = [FTUtility getLowercaseStringWithoutSymbols:mention];
    
    //****** Display Name ********//
    PFQuery *queryStringMatchHandle = [PFQuery queryWithClassName:kFTUserClassKey];
    [queryStringMatchHandle whereKeyExists:kFTUserDisplayNameKey];
    [queryStringMatchHandle whereKey:kFTUserDisplayNameKey equalTo:lowercaseStringWithoutSymbols];
    [queryStringMatchHandle findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        if (!error) {
            
            //NSLog(@"users:%@",users);
            //NSLog(@"users.count:%lu",(unsigned long)users.count);
            
            if (users.count == 1) {
                
                PFUser *mentionedUser = [users objectAtIndex:0];
                //NSLog(@"mentionedUser:%@",mentionedUser);
                
                if ([mentionedUser objectForKey:kFTUserTypeBusiness]) {
                    [businessProfileViewController setBusiness:mentionedUser];
                    [self.navigationController pushViewController:businessProfileViewController animated:YES];
                } else {
                    [userProfileViewController setUser:mentionedUser];
                    [self.navigationController pushViewController:userProfileViewController animated:YES];
                }
                
            } else {
                
                [followFriendsViewController setFollowUserQueryType:FTFollowUserQueryTypeTagger];
                [followFriendsViewController setSearchString:lowercaseStringWithoutSymbols];
                [followFriendsViewController querySearchForUser];
                
                [self.navigationController pushViewController:followFriendsViewController animated:YES];
            }
        }
    }];
}

- (void)userProfileHeaderView:(FTUserProfileHeaderView *)userProfileHeaderView didTapLink:(NSString *)link {
    
    // Clean the string
    NSString *cleanLink;
    cleanLink = [link lowercaseString];
    cleanLink = [cleanLink stringByReplacingOccurrencesOfString:@"www." withString:@""];
    cleanLink = [cleanLink stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    cleanLink = [NSString stringWithFormat:@"http://www.%@",cleanLink];

    NSURL *url = [NSURL URLWithString:cleanLink];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - ()
#pragma GCC diagnostic ignored "-Wundeclared-selector"

- (void)didChangeFollowersAction:(NSNotification *)note {
    //NSLog(@"FTUserProfileViewController::didChangeFollowersAction");
    if (headerView && [headerView respondsToSelector:@selector(updateFollowerCount)]) {
        [headerView performSelector:@selector(updateFollowerCount)];
    }
}

- (void)didChangeFollowingAction:(NSNotification *)note {
    //NSLog(@"FTUserProfileViewController::didChangeFollowingAction");
    if (headerView && [headerView respondsToSelector:@selector(updateFollowingCount)]) {
        [headerView performSelector:@selector(updateFollowingCount)];
    }
}

- (void)didChangeBioAction:(NSNotification *)note {
    
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    
    NSString *biography = [note object];
    
    if (headerView && [headerView respondsToSelector:@selector(updateBiography:)]) {
        [headerView performSelector:@selector(updateBiography:) withObject:biography];
    }
}

- (void)didChangeProfilePhotoAction:(NSNotification *)note {
    
    UIImage *photo = [note object];
    
    if (headerView && [headerView respondsToSelector:@selector(updateProfilePicture:)]) {
        [headerView performSelector:@selector(updateProfilePicture:) withObject:photo];
    }
}

- (void)didChangeCoverPhotoAction:(NSNotification *)note {
    
    UIImage *photo = [note object];
    
    if (headerView && [headerView respondsToSelector:@selector(updateCoverPhoto:)]) {
        [headerView performSelector:@selector(updateCoverPhoto:) withObject:photo];
    }
}

- (void)userDidPublishPost:(NSNotification *)note {
    [self queryForTable:self.user];
}

- (void)userDidDeletePost:(NSNotificationCenter *)note {
    [self queryForTable:self.user];
}

@end
