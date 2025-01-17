//
//  FTCamRollViewController.h
//  FitTag
//
//  Created by Kevin Pimentel on 6/26/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "FTEditPhotoViewController.h"
#import "ELCImagePickerHeader.h"
#import "FTEditPostViewController.h"

@protocol FTCamRollViewControllerDelegate;

@interface FTCamRollViewController : UIViewController <ELCImagePickerControllerDelegate,FTEditPostViewControllerDelegate>

@property (nonatomic, strong) ELCAssetTablePicker *tableView;
@property (nonatomic,weak) id <FTCamRollViewControllerDelegate> delegate;
@property (nonatomic, copy) NSArray *chosenImages;
@property (nonatomic) BOOL isProfilePicture;
@property (nonatomic) BOOL isCoverPhoto;
@end

@protocol FTCamRollViewControllerDelegate <NSObject>
@optional
- (void)camRollViewController:(FTCamRollViewController *)camRollViewController profilePhoto:(UIImage *)photo;
- (void)camRollViewController:(FTCamRollViewController *)camRollViewController coverPhoto:(UIImage *)photo;
@end