//
//  FTEditPhotoViewController.m
//  FitTag
//
//  Created by Kevin Pimentel on 7/26/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#import "FTEditPhotoViewController.h"
#import "UIImage+ResizeAdditions.h"
//#import "FTCheckInViewController.h"

@interface FTEditPhotoViewController (){
    CLLocationManager *locationManager;
}
@end

@interface FTEditPhotoViewController()
@property (nonatomic) CGFloat locationLabelOriginalY;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *videoURL;
@property (nonatomic, strong) UITextView *commentTextView;
//@property (nonatomic, strong) UITextField *tagTextField;
//@property (nonatomic, strong) UITextField *locationTextField;
@property (nonatomic, assign) UIBackgroundTaskIdentifier fileUploadBackgroundTaskId;
@property (nonatomic, assign) UIBackgroundTaskIdentifier photoPostBackgroundTaskId;
@property (nonatomic, assign) NSInteger scrollViewHeight;
@property (nonatomic, strong) PFFile *photoFile;
@property (nonatomic, strong) PFFile *thumbnailFile;
@property (nonatomic, strong) PFGeoPoint *geoPoint;
@property (nonatomic, strong) NSString *postLocation;
@property (nonatomic, strong) FTPostDetailsFooterView *postDetailsFooterView;
@end

@implementation FTEditPhotoViewController
@synthesize postDetailsFooterView;
@synthesize scrollView;
@synthesize image;
@synthesize commentTextView;
@synthesize photoFile;
@synthesize thumbnailFile;
@synthesize fileUploadBackgroundTaskId;
@synthesize photoPostBackgroundTaskId;
//@synthesize tagTextField;
@synthesize scrollViewHeight;
@synthesize locationLabelOriginalY;

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (id)initWithImage:(UIImage *)aImage {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        if (!aImage) {
            return nil;
        }
        
        self.image = aImage;
        self.fileUploadBackgroundTaskId = UIBackgroundTaskInvalid;
        self.photoPostBackgroundTaskId = UIBackgroundTaskInvalid;
    }
    return self;
}

#pragma mark - UIViewController

- (void)loadView {
    self.scrollView = [[UIScrollView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor whiteColor];
    self.view = self.scrollView;
    
    UIImageView *photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    [photoImageView setBackgroundColor:[UIColor whiteColor]];
    [photoImageView setImage:self.image];
    [photoImageView setContentMode:CONTENTMODE];
    
    [self.scrollView addSubview:photoImageView];
 
    CGRect footerRect = [FTPostDetailsFooterView rectForView];
    footerRect.origin.y = photoImageView.frame.origin.y + photoImageView.frame.size.height;
    
    self.postDetailsFooterView = [[FTPostDetailsFooterView alloc] initWithFrame:footerRect];
    self.commentTextView = postDetailsFooterView.commentField;
    //self.tagTextField = postDetailsFooterView.hashtagTextField;
    //self.locationTextField = postDetailsFooterView.locationTextField;

    //self.locationTextField.delegate = self;
    self.commentTextView.delegate = self;
    //self.tagTextField.delegate = self;
    self.postDetailsFooterView.delegate = self;
    
    [self.scrollView addSubview:postDetailsFooterView];
    
    scrollViewHeight = photoImageView.frame.origin.y + photoImageView.frame.size.height + postDetailsFooterView.frame.size.height;
    
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width, scrollViewHeight)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Start Updating Location
    if(IS_OS_8_OR_LATER) {
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestAlwaysAuthorization];
    }
    [[self locationManager] startUpdatingLocation];
    
    // NavigationBar & ToolBar
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.toolbar setHidden:YES];
    [self.navigationItem setTitle:@"TAG YOUR FIT"];
    [self.navigationItem setHidesBackButton:NO];
    
    // Override the back idnicator
    UIBarButtonItem *backIndicator = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigate_back"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(hideCameraView:)];
    [backIndicator setTintColor:[UIColor whiteColor]];
    [self.navigationItem setLeftBarButtonItem:backIndicator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self shouldUploadImage:self.image];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:VIEWCONTROLLER_EDIT_PHOTO];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark - UITextFieldDelegate
/*
- (BOOL)textFieldShouldReturn:(UITextField *)textField {    
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if ([textField isEqual:self.locationTextField]) {
        FTCheckInViewController *checkInViewController = [[FTCheckInViewController alloc] initWithStyle:UITableViewStylePlain];
        
        UINavigationController *navController = [[UINavigationController alloc] init];
        [navController setViewControllers:@[ checkInViewController ] animated:NO];
        [navController.navigationBar setTintColor:FT_RED];
        [navController.navigationBar setBarTintColor:FT_RED];
        
        [self presentViewController:navController animated:NO completion:^{
            NSLog(@"location select complete");
        }];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField isEqual:self.locationTextField]) {
        
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    return YES;
}
*/
#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.commentTextView resignFirstResponder];
    //[self.tagTextField resignFirstResponder];
    //[self.locationTextField resignFirstResponder];
}

#pragma mark - FTPhotoPostDetailsFooterViewDelegate

- (void)postDetailsFooterView:(FTPostDetailsFooterView *)postDetailsFooterView
    didTapFacebookShareButton:(UIButton *)button {
    // Facebook button is on
}

- (void)postDetailsFooterView:(FTPostDetailsFooterView *)postDetailsFooterView
     didTapTwitterShareButton:(UIButton *)button {
    // Twitter button is on
}

#pragma mark - ()

- (void)incrementUserPostCount {
    // Increment user post count
    PFUser *user = [PFUser currentUser];
    [user incrementKey:kFTUserPostCountKey byAmount:[NSNumber numberWithInt:1]];
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            long int postCount = (long)[[user objectForKey:kFTUserPostCountKey] integerValue];
            NSLog(@"postCount %ld",postCount);
            
            NSNumber *rewardCount = [NSNumber numberWithUnsignedInteger:(postCount / 10)];
            NSLog(@"rewardCount %@",rewardCount);
            
            [user setValue:rewardCount forKey:kFTUserRewardsEarnedKey];
            [user saveInBackground];
        }
    }];
}

- (NSArray *)checkForHashtag {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:&error];
    NSArray *matches = [regex matchesInString:self.commentTextView.text options:0 range:NSMakeRange(0,self.commentTextView.text.length)];
    NSMutableArray *matchedResults = [[NSMutableArray alloc] init];
    for (NSTextCheckingResult *match in matches) {
        NSRange wordRange = [match rangeAtIndex:1];
        NSString *word = [self.commentTextView.text substringWithRange:wordRange];
        //NSLog(@"Found tag %@", word);
        [matchedResults addObject:word];
    }
    return matchedResults;
}

- (NSMutableArray *) checkForMention {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@(\\w+)" options:0 error:&error];
    NSArray *matches = [regex matchesInString:self.commentTextView.text options:0 range:NSMakeRange(0,self.commentTextView.text.length)];
    NSMutableArray *matchedResults = [[NSMutableArray alloc] init];
    for (NSTextCheckingResult *match in matches) {
        NSRange wordRange = [match rangeAtIndex:1];
        NSString *word = [self.commentTextView.text substringWithRange:wordRange];
        //NSLog(@"Found mention %@", word);
        [matchedResults addObject:word];
    }
    return matchedResults;
}

- (void)hideCameraView:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)shouldUploadImage:(UIImage *)anImage {
    
    UIImage *resizedImage = [anImage resizedImageWithContentMode:CONTENTMODE
                                                          bounds:CGSizeMake(640, 640)
                                            interpolationQuality:kCGInterpolationHigh];
    UIImage *thumbnailImage = [anImage thumbnailImage:86.0f transparentBorder:0.0f cornerRadius:10.0f interpolationQuality:kCGInterpolationDefault];
    
    // JPEG to decrease file size and enable faster uploads & downloads
    NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.8f);
    NSData *thumbnailImageData = UIImagePNGRepresentation(thumbnailImage);
    
    if (!imageData || !thumbnailImageData) {
        return NO;
    }
    
    self.photoFile = [PFFile fileWithName:@"photo.jpeg" data:imageData];
    self.thumbnailFile = [PFFile fileWithName:@"thumbnail.png" data:imageData];
    
    if ([PFUser currentUser]) {
        // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
        self.fileUploadBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
        }];
    
        [self.photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [self.thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
                
                    if (error) {
                        NSLog(@"self.thumbnailFile saveInBackgroundWithBlock: %@", error);
                    }
                }];
            } else {
                [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
            }
        
            if (error) {
                NSLog(@"self.photoFile saveInBackgroundWithBlock: %@", error);
            }
        }];
    }
    
    return YES;
}

- (void)keyboardWillShow:(NSNotification *)note {
    CGRect keyboardFrameEnd = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize scrollViewContentSize = self.scrollView.bounds.size;
    scrollViewContentSize.height += keyboardFrameEnd.size.height;
    [self.scrollView setContentSize:scrollViewContentSize];
    
    CGPoint scrollViewContentOffset = self.scrollView.contentOffset;
    // Align the bottom edge of the photo with the keyboard
    scrollViewContentOffset.y = scrollViewContentOffset.y + keyboardFrameEnd.size.height * 3.0f - [UIScreen mainScreen].bounds.size.height;
    
    [self.scrollView setContentOffset:scrollViewContentOffset animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)note {
    CGSize scrollViewContentSize = CGSizeMake(self.scrollView.frame.size.width,scrollViewHeight);
    [UIView animateWithDuration:0.200f animations:^{
        [self.scrollView setContentSize:scrollViewContentSize];
    }];
}

- (void)postDetailsFooterView:(FTPostDetailsFooterView *)postDetailsFooterView
       didTapSubmitPostButton:(UIButton *)button {
    
    // Make sure there were no errors creating the image files
    if (!self.photoFile || !self.thumbnailFile) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your photo" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
        [alert show];
        return;
    }
    
    if ([PFUser currentUser]) {
    
        NSDictionary *userInfo = [NSDictionary dictionary];
        NSString *trimmedComment = [self.commentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
        if (trimmedComment.length > 0) {
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:trimmedComment,kFTEditPhotoViewControllerUserInfoCommentKey,nil];
        }
        
        // Make sure there were no errors creating the image files
        if (!self.photoFile || !self.thumbnailFile) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your photo" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
            [alert show];
            return;
        }
        
        // both files have finished uploading
        
        NSMutableArray *hashtags = [[NSMutableArray alloc] initWithArray:[self checkForHashtag]];
        NSMutableArray *mentions = [[NSMutableArray alloc] initWithArray:[self checkForMention]];
        
        // create a photo object
        PFObject *photo = [PFObject objectWithClassName:kFTPostClassKey];
        [photo setObject:[PFUser currentUser] forKey:kFTPostUserKey];
        [photo setObject:self.photoFile forKey:kFTPostImageKey];
        [photo setObject:self.thumbnailFile forKey:kFTPostThumbnailKey];
        [photo setObject:kFTPostImageKey forKey:kFTPostTypeKey];
        [photo setObject:hashtags forKey:kFTPostHashTagKey];
        [photo setObject:mentions forKey:kFTPostMentionKey];
        
        NSString *description = EMPTY_STRING;
        
        NSLog(@"Posting photo...");
        
        // userInfo might contain any caption which might have been posted by the uploader
        if (userInfo) {
            NSString *commentText = [userInfo objectForKey:kFTEditPhotoViewControllerUserInfoCommentKey];
            
            if (commentText && commentText.length > 0) {
                // create and save photo caption
                NSLog(@"photo caption");
                [photo setObject:commentText forKey:kFTPostCaptionKey];
                description = commentText;
            }
        }
        
        if (self.geoPoint) {
            [photo setObject:self.geoPoint forKey:kFTPostLocationKey];
        }
        
        // photos are public, but may only be modified by the user who uploaded them
        PFACL *photoACL = [PFACL ACLWithUser:[PFUser currentUser]];
        [photoACL setPublicReadAccess:YES];
        photo.ACL = photoACL;
    
        // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
        self.photoPostBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
        }];
    
        // Save the Photo PFObject
        [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
            
                [[FTCache sharedCache] setAttributesForPost:photo likers:[NSArray array] commenters:[NSArray array] likedByCurrentUser:NO];            
                [self incrementUserPostCount];
                
                //NSLog(@"photo:%@",photo.objectId);
                NSString *link = [NSString stringWithFormat:@"http://fittag.com/viewer.php?pid=%@",photo.objectId];
                
                PFFile *caption = nil;
                if ([photo objectForKey:kFTPostImageKey]) {
                    caption = [photo objectForKey:kFTPostImageKey];
                }
                
                // If facebook icon selected, post to facebook
                if ([self.postDetailsFooterView.facebookButton isSelected]) {
                    if (caption.url) {
                        [FTUtility shareCapturedMomentOnFacebook:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                  @"Captured Healthy Moment", @"name",
                                                                  @"Healthy moment was shared via #FitTag.", @"caption",
                                                                  description, @"description",
                                                                  link, @"link",
                                                                  caption.url, @"picture", nil]];
                    }
                }
                
                // If twitter icon selected, update twitter status
                if ([self.postDetailsFooterView.twitterButton isSelected]) {
                    NSString *status = [NSString stringWithFormat:@"Captured a healthy moment via #FitTag http://fittag.com/viewer.php?pid=%@",photo.objectId];
                    [FTUtility shareCapturedMomentOnTwitter:status];
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:FTTabBarControllerDidFinishEditingPhotoNotification object:photo];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Couldn't post your photo"
                                            message:nil
                                           delegate:nil
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"Dismiss", nil] show];
            }
            [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
        }];
    
        // Dismiss this screen
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)cancelButtonAction:(id)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CLLocationManagerDelegate

- (CLLocationManager *)locationManager {
    //NSLog(@"(CLLocationManager *)locationManager");
    if (locationManager != nil) {
        return locationManager;
    }
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    return locationManager;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    //NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:@"Failed to Get Your Location"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [errorAlert show];
    postDetailsFooterView.locationTextField.text = @"Please visit privacy settings to enable location tracking.";
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    //NSLog(@"(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations %@",locations);
    [locationManager stopUpdatingLocation];
    if ([PFUser currentUser]) {
        CLLocation *location = [locations lastObject];
        //NSLog(@"lat%f - lon%f", location.coordinate.latitude, location.coordinate.longitude);
        self.geoPoint = [PFGeoPoint geoPointWithLatitude:location.coordinate.latitude
                                               longitude:location.coordinate.longitude];
        
        // Set location
        CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
        [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            for (CLPlacemark *placemark in placemarks) {
                //NSLog(@"City: %@",[placemark locality]);
                //NSLog(@"State: %@",[placemark administrativeArea]);
                self.postLocation = [NSString stringWithFormat:@" %@, %@", [placemark locality], [placemark administrativeArea]];
                if (postDetailsFooterView) {
                    //postDetailsFooterView.locationTextField.text = self.postLocation;
                }
            }
        }];
    }
}

@end

