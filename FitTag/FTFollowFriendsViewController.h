//
//  FTFollowFriendsViewController.h
//  FitTag
//
//  Used to find friends by location or interest
//
//  Created by Kevin Pimentel on 10/27/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

typedef enum {
    FTFollowUserQueryTypeNone = 0,
    FTFollowUserQueryTypeNear = 1 << 0,
    FTFollowUserQueryTypeInterest = 1 << 1,
    FTFollowUserQueryTypeAmbassador = 1 << 2,
    FTFollowUserQueryTypeBusiness = 1 << 3,
    FTFollowUserQueryTypeUser = 1 << 4,
    FTFollowUserQueryTypeTagger = FTFollowUserQueryTypeAmbassador | FTFollowUserQueryTypeBusiness | FTFollowUserQueryTypeUser,
    FTFollowUserQueryTypeDefault = FTFollowUserQueryTypeNear
} FTFollowUserQueryType;

#import "FTFollowCell.h"
#import "FTInviteTableHeaderView.h"
#import "FTLocationManager.h"

@class FTLocationManager;
@interface FTFollowFriendsViewController : UITableViewController <FTFollowCellDelegate,FTInviteTableHeaderViewDelegate,FTLocationManagerDelegate>
@property (nonatomic, assign) FTFollowUserQueryType followUserQueryType;
@property (nonatomic, strong) NSString *searchString;

- (void)querySearchForUser;

@end
