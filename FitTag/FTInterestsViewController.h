//
//  InterestsViewController.h
//  FitTag
//
//  Created by Kevin Pimentel on 6/26/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#import "FTLocationManager.h"

@protocol FTInterestsViewControllerDelegate;
@interface FTInterestsViewController : UICollectionViewController <FTLocationManagerDelegate>

/*! FTGalleryCell Delegate */
@property (nonatomic, weak) id <FTInterestsViewControllerDelegate> delegate;
@property (nonatomic) BOOL isFirstLaunch;
@end

@protocol FTInterestsViewControllerDelegate <NSObject>
@optional

// Sent to the delegate when interests data is updated
- (void)interestsViewController:(FTInterestsViewController *)interestsViewController didUpdateUserInterests:(NSArray *)interests;

@end