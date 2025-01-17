//
//  FTFollowFriendsViewController.m
//  FitTag
//
//  Created by Kevin Pimentel on 10/27/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#import "FTFollowFriendsViewController.h"
#import "FTUserProfileViewController.h"
#import "FTBusinessProfileViewController.h"

#define DATACELL_IDENTIFIER @"DataCell"
#define TABLE_VIEW_HEIGHT 40

@interface FTFollowFriendsViewController()
@property (nonatomic, strong) NSArray *objects;
@property (nonatomic, strong) FTInviteTableHeaderView *headerView;
@property (nonatomic, strong) FTLocationManager *locationManager;
@property (nonatomic, strong) UIBarButtonItem *backIndicator;
@property (nonatomic, strong) UIImageView *errorLocationImage;
@property BOOL locationUpdated;
@end

@implementation FTFollowFriendsViewController
@synthesize followUserQueryType;
@synthesize headerView;
@synthesize locationManager;
@synthesize backIndicator;
@synthesize locationUpdated;
@synthesize errorLocationImage;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"FTFollowFriendsViewController::viewDidLoad");
    
    locationUpdated = NO;
    
    UIImage *noLocationImage = [UIImage imageNamed:@"no_location"];
    errorLocationImage = [[UIImageView alloc] initWithImage:noLocationImage];
    [errorLocationImage setFrame:CGRectMake(0, 0, 263, 298)];
    [errorLocationImage setCenter:CGPointMake(self.view.frame.size.width/2, (self.view.frame.size.height/2)-TABLE_VIEW_HEIGHT)];
    
    // manage user location
    locationManager = [[FTLocationManager alloc] init];
    [locationManager setDelegate:self];
    
    //[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    
    // Set background image
    [self.tableView setBackgroundColor:FT_GRAY];
    [self.tableView setDelegate:self];
    
    // Fittag navigationbar color
    self.navigationController.navigationBar.barTintColor = FT_RED;
    
    // backbutton
    backIndicator = [[UIBarButtonItem alloc] init];
    [backIndicator setImage:[UIImage imageNamed:NAVIGATION_BAR_BUTTON_BACK]];
    [backIndicator setStyle:UIBarButtonItemStylePlain];
    [backIndicator setTarget:self];
    [backIndicator setAction:@selector(didTapBackButtonAction:)];
    [backIndicator setTintColor:[UIColor whiteColor]];
    
    // Table headerview
    headerView = [[FTInviteTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, TABLE_VIEW_HEIGHT)];
    headerView.delegate = self;
    
    [headerView setLocationSelected];
    
    if (followUserQueryType & FTFollowUserQueryTypeTagger) {
        [self.tableView.tableHeaderView setHidden:YES];
        [self querySearchForUser];
    } else {
        [self.tableView setTableHeaderView:headerView];
        [self.tableView.tableHeaderView setHidden:NO];
        
        if (followUserQueryType == 0) {
            [self queryForUserType:FTFollowUserQueryTypeDefault];
        } else {
            [self queryForUserType:followUserQueryType];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [locationManager requestLocationAuthorization];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:VIEWCONTROLLER_FOLLOW];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark - ()

- (void)querySearchForUser {
    // List of all users where handle matches string OR handle contains substring
    //NSLog(@"self.searchString: %@",self.searchString);
    
    if (self.searchString && ![self.searchString isEqualToString:EMPTY_STRING]) {
        
        //****** Display Name ********//
        PFQuery *queryStringMatchHandle = [PFQuery queryWithClassName:kFTUserClassKey];
        [queryStringMatchHandle whereKeyExists:kFTUserDisplayNameKey];
        [queryStringMatchHandle whereKey:kFTUserDisplayNameKey equalTo:self.searchString];
        
        PFQuery *querySubStringHandle = [PFQuery queryWithClassName:kFTUserClassKey];
        [querySubStringHandle whereKeyExists:kFTUserDisplayNameKey];
        [querySubStringHandle whereKey:kFTUserDisplayNameKey containsString:self.searchString];
        
        //****** First Name ********//
        PFQuery *queryStringMatchFirstName = [PFQuery queryWithClassName:kFTUserClassKey];
        [queryStringMatchFirstName whereKeyExists:kFTUserFirstnameKey];
        [queryStringMatchFirstName whereKey:kFTUserFirstnameKey equalTo:self.searchString];
        
        PFQuery *querySubStringFirstName = [PFQuery queryWithClassName:kFTUserClassKey];
        [querySubStringFirstName whereKeyExists:kFTUserFirstnameKey];
        [querySubStringFirstName whereKey:kFTUserFirstnameKey containsString:self.searchString];
        
        //****** Last Name ********//
        PFQuery *queryStringMatchLastName = [PFQuery queryWithClassName:kFTUserClassKey];
        [queryStringMatchLastName whereKeyExists:kFTUserLastnameKey];
        [queryStringMatchLastName whereKey:kFTUserLastnameKey equalTo:self.searchString];
        
        PFQuery *querySubStringLastName = [PFQuery queryWithClassName:kFTUserClassKey];
        [querySubStringLastName whereKeyExists:kFTUserLastnameKey];
        [querySubStringLastName whereKey:kFTUserLastnameKey containsString:self.searchString];
        
        NSArray *queries = @[ queryStringMatchHandle, querySubStringHandle, queryStringMatchFirstName,
                              querySubStringFirstName, queryStringMatchLastName, querySubStringLastName ];
        
        PFQuery *query = [PFQuery orQueryWithSubqueries:queries];
        [query findObjectsInBackgroundWithBlock:^(NSArray *taggers, NSError *error) {
            if (!error) {
                if (taggers.count > 0) {
                    self.objects = taggers;
                    [self.tableView reloadData];
                } else {
                    //IMAGE_NO_RESULTS
                    UIImageView *imageView = [[UIImageView alloc] initWithImage:IMAGE_NO_RESULTS];
                    [imageView setFrame:CGRectMake((self.tableView.frame.size.width - 130) / 2, (self.tableView.frame.size.width - 156) / 2, 130, 156)];
                    [self.tableView addSubview:imageView];
                }
            }
        }];
    }
}

- (void)queryForUserType:(FTFollowUserQueryType)type {
    
    NSLog(@"%@::queryForUserType::%d",VIEWCONTROLLER_INVITE,type);
    
    // List of all users being followed by the current user
    PFQuery *followingActivitiesQuery = [PFQuery queryWithClassName:kFTActivityClassKey];
    [followingActivitiesQuery whereKey:kFTActivityTypeKey equalTo:kFTActivityTypeFollow];
    [followingActivitiesQuery whereKey:kFTActivityFromUserKey equalTo:[PFUser currentUser]];
    [followingActivitiesQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    [followingActivitiesQuery includeKey:kFTActivityToUserKey];
    [followingActivitiesQuery findObjectsInBackgroundWithBlock:^(NSArray *followedUsers, NSError *error) {
        if (!error) {
            NSMutableArray *followedUserIds = [[NSMutableArray alloc] init];
            
            // Obtain an array of object ids for all users being followed
            for (PFObject *aFollowedUser in followedUsers) {
                PFUser *followedUser = [aFollowedUser objectForKey:kFTActivityToUserKey];                
                if (followedUser.objectId) {
                    [followedUserIds addObject:followedUser.objectId];
                }
            }
            
            switch (type) {
                case FTFollowUserQueryTypeNear: {
                    
                    if (!locationUpdated) {
                        [self.view addSubview:errorLocationImage];
                        self.objects = nil;
                        [self.tableView reloadData];
                        return;
                    }
                    
                    if (![[PFUser currentUser] objectForKey:kFTUserLocationKey]) {
                        [[[UIAlertView alloc] initWithTitle:@"User Location Error"
                                                    message:@"User location needs to be enabled to find users near you."
                                                   delegate:self
                                          cancelButtonTitle:@"ok"
                                          otherButtonTitles:nil] show];
                        return;
                    }
                    
                    PFGeoPoint *geoPoint = [[PFUser currentUser] objectForKey:kFTUserLocationKey];
                    
                    // List of all users within 50 miles that are not already being followed
                    PFQuery *followUsersByLocationQuery = [PFQuery queryWithClassName:kFTUserClassKey];
                    [followUsersByLocationQuery whereKey:kFTUserObjectIdKey notEqualTo:[PFUser currentUser].objectId];
                    [followUsersByLocationQuery whereKey:kFTUserLocationKey nearGeoPoint:geoPoint withinMiles:LOCATION_USERS_WITHIN_MILES];
                    [followUsersByLocationQuery whereKeyExists:kFTUserLocationKey];
                    [followUsersByLocationQuery whereKey:kFTUserObjectIdKey notContainedIn:followedUserIds];
                    [followUsersByLocationQuery setLimit:100];
                    [followUsersByLocationQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        if (!error) {
                            [headerView setLocationSelected];
                            self.objects = objects;
                            [self.tableView reloadData];
                        }
                    }];
                }
                    break;
                    
                case FTFollowUserQueryTypeInterest: {
                    
                    
                    if (![[PFUser currentUser] objectForKey:kFTUserInterestsKey]) {
                        [[[UIAlertView alloc] initWithTitle:@"User Interest Error"
                                                    message:@"User interest needs to be selected to find friends."
                                                   delegate:self
                                          cancelButtonTitle:@"ok"
                                          otherButtonTitles:nil] show];
                        return;
                    }
                    
                    [errorLocationImage removeFromSuperview];
                    
                    NSArray *interests = [[PFUser currentUser] objectForKey:kFTUserInterestsKey];
                                        
                    PFQuery *followUsersByInterestQuery = [PFQuery queryWithClassName:kFTUserClassKey];
                    [followUsersByInterestQuery whereKey:kFTUserObjectIdKey notEqualTo:[PFUser currentUser].objectId];
                    [followUsersByInterestQuery whereKey:kFTUserInterestsKey containedIn:interests];
                    [followUsersByInterestQuery whereKeyExists:kFTUserInterestsKey];
                    [followUsersByInterestQuery whereKey:kFTUserObjectIdKey notContainedIn:followedUserIds];
                    [followUsersByInterestQuery setLimit:100];
                    [followUsersByInterestQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        if (!error) {
                            [headerView setInterestSelected];
                            self.objects = objects;
                            [self.tableView reloadData];
                        }
                    }];
                    
                }
                    break;
                    
                default:
                    break;
            }
        }
    }];
}

#pragma mark - FTLocationManagerDelegate

- (void)locationManager:(FTLocationManager *)locationManager didUpdateUserLocation:(CLLocation *)location geoPoint:(PFGeoPoint *)aGeoPoint {
    locationUpdated = YES;
}

- (void)locationManager:(FTLocationManager *)locationManager didFailWithError:(NSError *)error {
    locationUpdated = NO;
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FTFollowCell *cell = (FTFollowCell *)[tableView dequeueReusableCellWithIdentifier:DATACELL_IDENTIFIER];
    if (cell == nil) {
        cell = [[FTFollowCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DATACELL_IDENTIFIER];
        cell.delegate = self;
    }
    
    if(indexPath.row != self.objects.count-1){
        UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
        line.backgroundColor = [UIColor whiteColor];
        [cell addSubview:line];
    }
    
    [cell setUser:self.objects[indexPath.row]];

    return cell;
}

#pragma mark - FTFollowCellDelegate

- (void)followCell:(FTFollowCell *)inviteCell didTapProfileImage:(UIButton *)button user:(PFUser *)aUser {
    NSLog(@"%@::followCell:didTapProfileImage:user",VIEWCONTROLLER_INVITE);
    
    PFUser *selectedUser = aUser;
    NSString *userType = [selectedUser objectForKey:kFTUserTypeKey];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(self.view.frame.size.width/3,105)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:0];
    [flowLayout setSectionInset:UIEdgeInsetsMake(0,0,0,0)];
    
    if ([userType isEqualToString:kFTUserTypeBusiness]) {
        
        [flowLayout setHeaderReferenceSize:CGSizeMake(self.view.frame.size.width,PROFILE_HEADER_VIEW_HEIGHT_BUSINESS)];
        
        FTBusinessProfileViewController *businessViewController = [[FTBusinessProfileViewController alloc] initWithCollectionViewLayout:flowLayout];
        [businessViewController setBusiness:selectedUser];
        [businessViewController.navigationItem setLeftBarButtonItem:backIndicator];
        [self.navigationController pushViewController:businessViewController animated:YES];
        
    } else {
        
        [flowLayout setHeaderReferenceSize:CGSizeMake(self.view.frame.size.width,PROFILE_HEADER_VIEW_HEIGHT)];
        
        FTUserProfileViewController *profileViewController = [[FTUserProfileViewController alloc] initWithCollectionViewLayout:flowLayout];
        [profileViewController setUser:selectedUser];
        [profileViewController.navigationItem setLeftBarButtonItem:backIndicator];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}

#pragma mark - FTInviteTableHeaderViewDelegate

- (void)inviteTableHeaderView:(FTInviteTableHeaderView *)inviteTableHeaderView
         didTapInterestButton:(UIButton *)button {
    [self queryForUserType:FTFollowUserQueryTypeInterest];
}

- (void)inviteTableHeaderView:(FTInviteTableHeaderView *)inviteTableHeaderView
         didTapLocationButton:(UIButton *)button {
    [self queryForUserType:FTFollowUserQueryTypeNear];
}

#pragma mark - ()

- (void)didTapBackButtonAction:(UIButton *)button {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
