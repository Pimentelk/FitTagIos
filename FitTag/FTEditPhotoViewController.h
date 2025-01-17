//
//  FTEditPhotoViewController.h
//  FitTag
//
//  Created by Kevin Pimentel on 7/26/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#import "FTPostDetailsFooterView.h"
#import <CoreLocation/CoreLocation.h>
#import "FTSuggestionTableView.h"
#import "FTPlacesViewController.h"

@interface FTEditPhotoViewController : UIViewController <UITextViewDelegate,
                                                         UITextFieldDelegate,
                                                         UIScrollViewDelegate,
                                                         FTSuggestionTableViewDelegate,
                                                         FTPlacesViewControllerDelegate,
                                                         FTPostDetailsFooterViewDelegate,
                                                         CLLocationManagerDelegate>

- (id)initWithImage:(UIImage *)aImage;

@end
