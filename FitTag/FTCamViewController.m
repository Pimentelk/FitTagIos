//
//  FTCameraViewController.m
//  FitTag
//
//  Created by Kevin Pimentel on 8/10/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#define FLASH_IMAGE_ON @"flash"
#define FLASH_IMAGE_OFF @"no_flash"
#define FLASH_IMAGE_AUTO @"auto_flash"

// GUI Images

#define BUTTON_IMAGE_CAMERA_ROLL @"camera_roll"
#define BUTTON_IMAGE_VIDEO @"video_button"
#define BUTTON_IMAGE_RECORD @"record_video_button"
#define BUTTON_IMAGE_TAKE_PICTURE @"take_picture"
#define BUTTON_IMAGE_TOGGLE_CAMERA @"toggle_camera"
#define BUTTON_IMAGE_TOGGLE_CROSSHAIRS @"toggle_crosshairs"
#define BUTTON_IMAGE_CROSSHAIRS @"no_crosshairs"
#define BUTTON_IMAGE_CAMERA_CROSSHAIRS @"crosshairs"
#define BUTTON_IMAGE_CAMERA_OVERLAY @"camera_overlay"

#define BUTTON_TITTLE_NEXT @"NEXT"


#include <math.h>

#import "FTCamViewController.h"
#import "FTCamRollViewController.h"
#import "FTEditVideoViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * RecordingContext = &RecordingContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

@interface FTCamViewController (){
    BOOL isVideoRecorded;
}
@end

@interface FTCamViewController () <AVCaptureFileOutputRecordingDelegate>
@property (nonatomic, readonly, assign) FTCamFlashButtonState camFlashButtonState;
@property (nonatomic, strong) FTEditPhotoViewController *editPhotoViewController;
@property (nonatomic, strong) FTEditVideoViewController *editVideoViewController;
@property (nonatomic, strong) UIView *liveView;
@property (nonatomic, strong) UIButton *toggleCamera;
@property (nonatomic, strong) UIButton *showCameraButton;
@property (nonatomic, strong) UIButton *takePicture;
@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIBarButtonItem *nextBarButton;
@property (nonatomic) UIImageView *crosshairs;
@property (nonatomic) UIImageView *cameraOverlay;
@property (nonatomic) UIButton *toggleFlashButton;
@property (nonatomic) UIButton *toggleCrosshairs;

// Track flash mode
@property (nonatomic) NSArray *flashImages;
@property (nonatomic) UIView *progressViewBorder;
@property (nonatomic) UIProgressView *progressView;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;
@end

@implementation FTCamViewController

@synthesize toggleCamera;
@synthesize showCameraButton;
@synthesize editVideoViewController;
@synthesize takePicture;
@synthesize cameraOverlay;
@synthesize crosshairs;
@synthesize delegate;
@synthesize flashImages;
@synthesize toggleFlashButton;
@synthesize toggleCrosshairs;
@synthesize recordButton;
@synthesize progressViewBorder;
@synthesize progressView;
@synthesize nextBarButton;
@synthesize editPhotoViewController;
@synthesize camFlashButtonState;

- (BOOL)isSessionRunningAndDeviceAuthorized{
	return [[self session] isRunning] && [self isDeviceAuthorized];
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized{
	return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    NSLog(@"%@viewDidLoad:",VIEWCONTROLLER_CAM);
    
    // Background color
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    // Create the AVCaptureSession
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
	[self setSession:session];
    [self.session setSessionPreset:AVCaptureSessionPresetMedium];
    
    // Setup the preview view
	[[self previewLayer] setSession:session];
    
    // Check for device authorization
	[self checkDeviceAuthorizationStatus];
    
    // Configure the preview layer
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    // NavigationBar & TabBar
    [self.navigationItem setTitle:NAVIGATION_TITLE_CAM];
    [self.navigationItem setHidesBackButton:NO];
    
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,nil];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:FT_RED_COLOR_RED
                                                                           green:FT_RED_COLOR_GREEN
                                                                            blue:FT_RED_COLOR_BLUE
                                                                           alpha:1.0f];
    
    nextBarButton = [[UIBarButtonItem alloc] initWithTitle:BUTTON_TITTLE_NEXT
                                                     style:UIBarButtonItemStylePlain target:self
                                                    action:@selector(didTapNextButtonAction:)];
    [nextBarButton setTintColor:[UIColor whiteColor]];
    
    [self.navigationItem setRightBarButtonItem:nextBarButton];
    [nextBarButton setEnabled:NO];
    isVideoRecorded = NO;
    
    // Override the back idnicator
    
    UIBarButtonItem *backIndicator = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:NAVIGATION_BAR_BUTTON_BACK]
                                                                      style:UIBarButtonItemStylePlain target:self action:@selector(didTapBackButtonAction:)];
    
    [backIndicator setTintColor:[UIColor whiteColor]];
    [self.navigationItem setLeftBarButtonItem:backIndicator];
    
    float previewHeight = self.view.frame.size.height * .65;
    float navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    
    // Camera Overlay
    
    cameraOverlay = [[UIImageView alloc] initWithImage:[UIImage imageNamed:BUTTON_IMAGE_CAMERA_OVERLAY]];
    [cameraOverlay setFrame:CGRectMake(0.0f,navigationBarHeight,320.0f,33.0f)];
    [self.view addSubview:cameraOverlay];
    
    // Add crosshairs
    
    crosshairs = [[UIImageView alloc] initWithImage:[UIImage imageNamed:BUTTON_IMAGE_CAMERA_CROSSHAIRS]];
    [crosshairs setFrame:CGRectMake(0.0f,33.0f,320.0f,previewHeight-66.0f)];
    
    // Camera View
    
    UIView *liveView = [[UIView alloc] initWithFrame:CGRectMake(0.0f,0.0f,320.0f,previewHeight)];
    [liveView setBackgroundColor:[UIColor blackColor]];
    
    [self.previewLayer setFrame:CGRectMake(0,0,liveView.frame.size.width,liveView.frame.size.height)];
    [liveView.layer addSublayer:self.previewLayer];
    
    // Container
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0f,cameraOverlay.frame.origin.y,crosshairs.frame.size.width,
                                                                 crosshairs.frame.size.height + (cameraOverlay.frame.size.height * 2))];
    [self.view addSubview:container];
    [container addSubview:liveView];
    [container addSubview:crosshairs];
    [liveView sendSubviewToBack:container];
    [self.view bringSubviewToFront:cameraOverlay];
    
    // Camera Overlay
    
    UIView *cameraBarOverlay = [[UIView alloc] initWithFrame:CGRectMake(0.0f,previewHeight+11, 320.0f, 33.0f)];
    [cameraBarOverlay setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:BUTTON_IMAGE_CAMERA_OVERLAY]]];
    [self.view addSubview:cameraBarOverlay];
    
    // Toggle Camera
    
    toggleCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    [toggleCamera setFrame:CGRectMake((self.view.frame.size.width - 26.0f)/2, 4.0f, 26.0f, 25.0f)];
    [toggleCamera setBackgroundImage:[UIImage imageNamed:BUTTON_IMAGE_TOGGLE_CAMERA] forState:UIControlStateNormal];
    [toggleCamera addTarget:self action:@selector(changeCamera:) forControlEvents:UIControlEventTouchUpInside];
    [toggleCamera setTintColor:[UIColor grayColor]];
    [toggleCamera setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // Toggle Flash
    
    toggleFlashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [toggleFlashButton setFrame:CGRectMake(250.0f, 4.0f, 18.0f, 24.0f)];
    [toggleFlashButton setImage:[UIImage imageNamed:FLASH_IMAGE_AUTO] forState:UIControlStateNormal];
    [toggleFlashButton addTarget:self action:@selector(didTapToggleFlashButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [toggleFlashButton setTintColor:[UIColor grayColor]];
    [toggleFlashButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // Toggle Crosshairs
    
    toggleCrosshairs = [UIButton buttonWithType:UIButtonTypeCustom];
    [toggleCrosshairs setFrame:CGRectMake(40.0f, 4.0f, 25.0f, 25.0f)];
    [toggleCrosshairs setBackgroundImage:[UIImage imageNamed:BUTTON_IMAGE_TOGGLE_CROSSHAIRS] forState:UIControlStateNormal];
    [toggleCrosshairs setBackgroundImage:[UIImage imageNamed:BUTTON_IMAGE_CROSSHAIRS] forState:UIControlStateSelected];
    [toggleCrosshairs addTarget:self action:@selector(didTapCrosshairsButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [toggleCrosshairs setTintColor:[UIColor grayColor]];
    [toggleCrosshairs setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // Add buttons to the overlay bar
    
    [cameraBarOverlay addSubview:toggleCrosshairs];
    [cameraBarOverlay addSubview:toggleCamera];
    [cameraBarOverlay addSubview:toggleFlashButton];

    // Setup the progressview
    
    progressViewBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,cameraBarOverlay.frame.size.height + cameraBarOverlay.frame.origin.y,self.view.frame.size.width,10.0f)];
    [progressViewBorder setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"progress_bg"]]];

    self.progressView = [[UIProgressView alloc] init];
    CGAffineTransform transform = CGAffineTransformMakeScale(1.0f, 5.0f);
    self.progressView.transform = transform;
    
    [self.progressView setFrame: CGRectMake(0.0f,3.0f,self.view.frame.size.width,5.0f)];
    [self.progressView setProgressTintColor:[UIColor whiteColor]];
    [self.progressView setUserInteractionEnabled:NO];
    [self.progressView setProgressViewStyle:UIProgressViewStyleDefault];
    [self.progressView setTrackTintColor:[UIColor clearColor]];
    [self.progressView setProgress:0];
    
    [progressViewBorder setHidden:YES];
    [progressViewBorder addSubview:self.progressView];
    [progressViewBorder bringSubviewToFront:self.progressView];
    
    [self.view addSubview:progressViewBorder];
    
    // Take picture button
    
    takePicture = [UIButton buttonWithType:UIButtonTypeCustom];
    [takePicture setFrame:CGRectMake((self.view.frame.size.width - 74.0f)/2,
                                     (long)[self getTopPaddingNavigationBarHeight:navigationBarHeight
                                                                    previewHeight:previewHeight
                                                                    elementHeight:74.0f
                                                                      frameHeight:self.view.frame.size.height], 74.0f, 74.0f)];
    
    [takePicture setBackgroundImage:[UIImage imageNamed:BUTTON_IMAGE_TAKE_PICTURE] forState:UIControlStateNormal];
    [takePicture addTarget:self action:@selector(snapStillImage:) forControlEvents:UIControlEventTouchUpInside];
    [takePicture setTintColor:[UIColor grayColor]];
    [takePicture setHidden:NO];
    
    [self.view addSubview:takePicture];
    
    // Record record Video Button
    
    recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [recordButton setBackgroundImage:[UIImage imageNamed:BUTTON_IMAGE_RECORD] forState:UIControlStateNormal];
    [recordButton addTarget:self action:@selector(didTapStartRecordingButtonAction:) forControlEvents:UIControlEventTouchDown];
    [recordButton addTarget:self action:@selector(didReleaseRecordingButtonAction:) forControlEvents:UIControlEventTouchDragExit];
    [recordButton addTarget:self action:@selector(didReleaseRecordingButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [recordButton setHidden:YES];
    [recordButton setFrame:CGRectMake((self.view.frame.size.width - 74.0f)/2,
                                      (long)[self getTopPaddingNavigationBarHeight:navigationBarHeight
                                                                     previewHeight:previewHeight
                                                                     elementHeight:74.0f
                                                                       frameHeight:self.view.frame.size.height], 74.0f, 74.0f)];
    [self.view addSubview:recordButton];
    
    // Show Camera Button
    if (!self.isProfilePciture && !self.isCoverPhoto) {
        showCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [showCameraButton setBackgroundImage:[UIImage imageNamed:BUTTON_IMAGE_VIDEO] forState:UIControlStateNormal];
        [showCameraButton addTarget:self action:@selector(toggleVideoControlsAction:) forControlEvents:UIControlEventTouchDown];
        [showCameraButton setTintColor:[UIColor grayColor]];
        [showCameraButton setFrame:CGRectMake(250.0f, [self getTopPaddingNavigationBarHeight:navigationBarHeight
                                                                               previewHeight:previewHeight
                                                                               elementHeight:39.0f
                                                                                 frameHeight:self.view.frame.size.height], 44.0f, 39.0f)];
        [self.view addSubview:showCameraButton];
    }
    
    
    // Camera roll button
    UIButton *cameraRoll = [UIButton buttonWithType:UIButtonTypeCustom];
    [cameraRoll setFrame:CGRectMake(40.0f, [self getTopPaddingNavigationBarHeight:navigationBarHeight
                                                                    previewHeight:previewHeight
                                                                    elementHeight:50.0f
                                                                      frameHeight:self.view.frame.size.height], 44.0f, 50.0f)];
    
    [cameraRoll setBackgroundImage:[UIImage imageNamed:BUTTON_IMAGE_CAMERA_ROLL] forState:UIControlStateNormal];
    [cameraRoll addTarget:self action:@selector(didTapCameraRollButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [cameraRoll setTintColor:[UIColor grayColor]];
    
    [self.view addSubview:cameraRoll];
    
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	[self setSessionQueue:sessionQueue];
    
    dispatch_async(sessionQueue, ^{
		[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
		
		NSError *error = nil;
		
		AVCaptureDevice *videoDevice = [FTCamViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		
		if (error) {
			NSLog(@"%@", error);
		}
		
        //NSLog(@"videoDeviceInput::Can session add input? %hhd ",[session canAddInput:videoDeviceInput]);
		if ([session canAddInput:videoDeviceInput])	{
			[session addInput:videoDeviceInput];
			[self setVideoDeviceInput:videoDeviceInput];
            
			dispatch_async(dispatch_get_main_queue(), ^{
				// Why are we dispatching this to the main queue?
				// Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
				// Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                
				[[(AVCaptureVideoPreviewLayer *)[self previewLayer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
                
                // Set the default flash state to auto
                camFlashButtonState = FTCamFlashButtonStateAuto;
                [FTCamViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[[self videoDeviceInput] device]];
			});
		}
		
		AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
		AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
		
		if (error) {
			NSLog(@"%@", error);
		}
		
		if ([session canAddInput:audioDeviceInput]) {
			[session addInput:audioDeviceInput];
		}
		
        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];

		if ([session canAddOutput:movieFileOutput]) {
			[session addOutput:movieFileOutput];
			AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
			if ([connection isVideoStabilizationSupported])
                [connection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
			[self setMovieFileOutput:movieFileOutput];
		}
		
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([session canAddOutput:stillImageOutput]) {
			[stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
			[session addOutput:stillImageOutput];
			[self setStillImageOutput:stillImageOutput];
		}
        
	});
}

- (void)didTapNextButtonAction:(id)sender {
    [self.navigationController pushViewController:editVideoViewController animated:NO];
}

- (void)toggleVideoControlsAction:(id)sender {
    
    if ([recordButton isHidden]) {
        [crosshairs setHidden:YES];
        [toggleFlashButton setHidden:YES];
        [toggleCrosshairs setHidden:YES];
        [recordButton setHidden:NO];
        [takePicture setHidden:YES];
        [progressViewBorder setHidden:NO];
        [self.navigationItem setTitle: @"VIDEO"];
        
        if (isVideoRecorded) {
            [self.nextBarButton setEnabled:YES];
        } else {
            [self.nextBarButton setEnabled:NO];
        }
        
    } else {
        [crosshairs setHidden:NO];
        [toggleFlashButton setHidden:NO];
        [toggleCrosshairs setHidden:NO];
        [recordButton setHidden:YES];
        [takePicture setHidden:NO];
        [progressViewBorder setHidden:YES];
        [self.navigationItem setTitle:NAVIGATION_TITLE_CAM];
        [self.nextBarButton setEnabled:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [progressView setProgress:0];
    [self.tabBarController.tabBar setHidden:YES];
    
	dispatch_async([self sessionQueue], ^{
		[self addObserver:self
               forKeyPath:@"sessionRunningAndDeviceAuthorized"
                  options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                  context:SessionRunningAndDeviceAuthorizedContext];
        
		[self addObserver:self
               forKeyPath:@"stillImageOutput.capturingStillImage"
                  options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                  context:CapturingStillImageContext];
        
		[self addObserver:self
               forKeyPath:@"movieFileOutput.recording"
                  options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                  context:RecordingContext];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(subjectAreaDidChange:)
                                                     name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                                   object:[[self videoDeviceInput] device]];
		
		__weak FTCamViewController *weakSelf = self;
		[self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter]
                                               addObserverForName:AVCaptureSessionRuntimeErrorNotification
                                               object:[self session]
                                               queue:nil
                                               usingBlock:^(NSNotification *note) {
                                                   
			FTCamViewController *strongSelf = weakSelf;
			dispatch_async([strongSelf sessionQueue], ^{
				// Manually restarting the session since it must have been stopped due to an error.
				[[strongSelf session] startRunning];
				[[strongSelf recordButton] setTitle:NSLocalizedString(@"", @"Recording button record title")
                                           forState:UIControlStateNormal];
			});
		}]];
		[[self session] startRunning];
	});
}

- (void)viewDidDisappear:(BOOL)animated {
    // Show the tabbar
    [self.tabBarController.tabBar setHidden:NO];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:VIEWCONTROLLER_CAM];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
	dispatch_async([self sessionQueue], ^{
		[[self session] stopRunning];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
		[[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
		
		[self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
		[self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
		[self removeObserver:self forKeyPath:@"movieFileOutput.recording" context:RecordingContext];
	});
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didTapBackButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)didTapToggleFlashButtonAction:(UIButton *)sender {
    switch (camFlashButtonState) {
        case FTCamFlashButtonStateAuto:
            //NSLog(@"FTCamFlashButtonStateAuto -> FTCamFlashButtonStateOn");
            camFlashButtonState = FTCamFlashButtonStateOn;
            [toggleFlashButton setImage:[UIImage imageNamed:FLASH_IMAGE_ON] forState:UIControlStateNormal];
            [toggleFlashButton setFrame:CGRectMake(250, 4, 15, 24)];
            [FTCamViewController setFlashMode:AVCaptureFlashModeOn forDevice:[[self videoDeviceInput] device]];
            break;
        case FTCamFlashButtonStateOn:
            //NSLog(@"FTCamFlashButtonStateOn -> FTCamFlashButtonStateOff");
            camFlashButtonState = FTCamFlashButtonStateOff;
            [toggleFlashButton setImage:[UIImage imageNamed:FLASH_IMAGE_OFF] forState:UIControlStateNormal];
            [toggleFlashButton setFrame:CGRectMake(250, 4, 25, 25)];
            [FTCamViewController setFlashMode:AVCaptureFlashModeOff forDevice:[[self videoDeviceInput] device]];
            break;
        case FTCamFlashButtonStateOff:
            //NSLog(@"FTCamFlashButtonStateOff -> FTCamFlashButtonStateAuto");
            camFlashButtonState = FTCamFlashButtonStateAuto;
            [toggleFlashButton setImage:[UIImage imageNamed:FLASH_IMAGE_AUTO] forState:UIControlStateNormal];
            [toggleFlashButton setFrame:CGRectMake(250, 4, 18, 24)];
            [FTCamViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[[self videoDeviceInput] device]];
            break;
        default:
            //NSLog(@"Default");
            camFlashButtonState = FTCamFlashButtonStateAuto;
            [toggleFlashButton setFrame:CGRectMake(250, 4.0f, 18.0f, 24)];
            [FTCamViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[[self videoDeviceInput] device]];
            break;
    }
}

-(void)didTapCrosshairsButtonAction:(id)sender {
    if ([toggleCrosshairs isSelected]) {
        [toggleCrosshairs setSelected:NO];
        [crosshairs setHidden:NO];
    } else {
        [toggleCrosshairs setSelected:YES];
        [crosshairs setHidden:YES];
    }
}

-(void)didTapCameraRollButtonAction:(id)sender {
    FTCamRollViewController *camRollViewController = [[FTCamRollViewController alloc] init];
    
    camRollViewController.delegate = self;
    if (self.isProfilePciture) {
        camRollViewController.isProfilePicture = YES;
    } else if (self.isCoverPhoto) {
        camRollViewController.isCoverPhoto = YES;
    }
    
    [self.navigationController pushViewController:camRollViewController animated:YES];    
}

- (void)changeCamera:(id)sender {
	[[self toggleCamera] setEnabled:NO];
	[[self recordButton] setEnabled:NO];
	[[self takePicture] setEnabled:NO];
	
	dispatch_async([self sessionQueue], ^{
		AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
		AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
		AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
		
		switch (currentPosition) {
			case AVCaptureDevicePositionUnspecified:
				preferredPosition = AVCaptureDevicePositionBack;
				break;
			case AVCaptureDevicePositionBack:
				preferredPosition = AVCaptureDevicePositionFront;
				break;
			case AVCaptureDevicePositionFront:
				preferredPosition = AVCaptureDevicePositionBack;
				break;
		}
		
		AVCaptureDevice *videoDevice = [FTCamViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
		
		[[self session] beginConfiguration];
		[[self session] removeInput:[self videoDeviceInput]];
        
		if ([[self session] canAddInput:videoDeviceInput]) {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
			
			//[FTCamViewController setFlashMode:AVCaptureFlashModeAuto forDevice:videoDevice];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDevice];
			
			[[self session] addInput:videoDeviceInput];
			[self setVideoDeviceInput:videoDeviceInput];
		} else {
			[[self session] addInput:[self videoDeviceInput]];
		}
		
		[[self session] commitConfiguration];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[[self toggleCamera] setEnabled:YES];
			[[self recordButton] setEnabled:YES];
			[[self takePicture] setEnabled:YES];
		});
	});
}

#pragma mark File Output Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
	if (error)
		NSLog(@"captureOutput: %@", error);
	
	[self setLockInterfaceRotation:NO];
    
	// Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
	
    UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
	[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
	
    if (backgroundRecordingID != UIBackgroundTaskInvalid)
        [[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
    
    
    NSData *videodata = [NSData dataWithContentsOfURL:outputFileURL];
    
    //NSLog(@"video data length: %lu",(unsigned long)[videodata length]);
    
    if ([videodata length] > 10485760) {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"Couldn't post your video, too large."
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:@"Dismiss", nil] show];
    } else {
        // Set video data and then Show UIBarButton
        editVideoViewController = [[FTEditVideoViewController alloc] initWithVideo:videodata];
        [self.nextBarButton setEnabled:YES];
        isVideoRecorded = YES;
    }
    
    [[NSFileManager defaultManager] removeItemAtURL:outputFileURL
                                              error:nil];
}

#pragma mark Actions

- (void)subjectAreaDidChange:(NSNotification *)notification {
    CGPoint devicePoint = CGPointMake(.5, .5);
        [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus
             exposeWithMode:AVCaptureExposureModeContinuousAutoExposure
              atDevicePoint:devicePoint
   monitorSubjectAreaChange:NO];
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    
	dispatch_async([self sessionQueue], ^{
		AVCaptureDevice *device = [[self videoDeviceInput] device];
		NSError *error = nil;
        
		if ([device lockForConfiguration:&error]) {
			
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode]) {
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
            
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode]) {
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
            
		} else {
			NSLog(@"%@", error);
		}
	});
 }

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device {
    
	if ([device hasFlash] && [device isFlashModeSupported:flashMode]) {

		NSError *error = nil;
		
        if ([device lockForConfiguration:&error]) {
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		} else {
			NSLog(@" setFlashMode: %@", error);
		}
	} else {
        NSLog(@" Device does not have flash or flash is not supported.");
    }
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {
    
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices) {
		if ([device position] == position) {
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}

#pragma mark UI

- (void)runStillImageCaptureAnimation {
    
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self previewLayer] setOpacity:0.0];
		[UIView animateWithDuration:.25 animations:^{
			[[self previewLayer] setOpacity:1.0];
		}];
	});
}

- (void)checkDeviceAuthorizationStatus {
    
	NSString *mediaType = AVMediaTypeVideo;
	
	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
		if (granted){
			//Granted access to mediaType
			[self setDeviceAuthorized:YES];
		} else {
			//Not granted access to mediaType
			dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:@"AVCam!"
											message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
										   delegate:self
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
				[self setDeviceAuthorized:NO];
			});
		}
	}];
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (BOOL)shouldAutorotate {
	// Disable autorotation of the interface when recording is in progress.
	return ![self lockInterfaceRotation];
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[[(AVCaptureVideoPreviewLayer *)[self previewLayer] connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
	if (context == CapturingStillImageContext) {
        
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		
		if (isCapturingStillImage){
			[self runStillImageCaptureAnimation];
		}
	} else if (context == RecordingContext) {
        
		BOOL isRecording = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async([self sessionQueue], ^{ // Background queue started
            // While the movie is recording, update the progress bar
            while ([[self movieFileOutput] isRecording]) {
                double duration = CMTimeGetSeconds([[self movieFileOutput] recordedDuration]);
                double time = CMTimeGetSeconds([[self movieFileOutput] maxRecordedDuration]);
                CGFloat progress = (CGFloat) (duration / time);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressView setProgress:progress animated:YES];
                });
            }
            
            // Dispatch changes to the view to main queue, they can't be updated in the background.
            dispatch_async(dispatch_get_main_queue(), ^{
                if (isRecording){
                    [[self toggleCamera] setEnabled:NO];
                    [[self recordButton] setTitle:NSLocalizedString(@"", @"Recording button stop title") forState:UIControlStateNormal];
                    [[self recordButton] setEnabled:YES];
                } else {
                    [[self toggleCamera] setEnabled:YES];
                    [[self recordButton] setTitle:NSLocalizedString(@"", @"Recording button record title") forState:UIControlStateNormal];
                    [[self recordButton] setEnabled:YES];
                }
            });
        });
        
	} else if (context == SessionRunningAndDeviceAuthorizedContext) {
		BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (isRunning) {
				[[self toggleCamera] setEnabled:YES];
				[[self recordButton] setEnabled:YES];
				[[self takePicture] setEnabled:YES];
			} else {
				[[self toggleCamera] setEnabled:NO];
				[[self recordButton] setEnabled:NO];
				[[self takePicture] setEnabled:NO];
			}
		});
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Actions

- (void)didTapStartRecordingButtonAction:(UIButton *)button {
    NSLog(@"%@::didTapStartRecordingButtonAction",VIEWCONTROLLER_CAM);
    [[self recordButton] setEnabled:NO];
    CMTime maxDuration = CMTimeMakeWithSeconds(10, 50);
	[[self movieFileOutput] setMaxRecordedDuration:maxDuration];
    [self.progressView setProgress:0 animated:NO];
    
	dispatch_async([self sessionQueue], ^{
		if (![[self movieFileOutput] isRecording]) {
            
			[self setLockInterfaceRotation:YES];
			
			if ([[UIDevice currentDevice] isMultitaskingSupported])	{
				// Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
				[self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
			}
			
			// Update the orientation on the movie file output video connection before starting recording.
			[[[self movieFileOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[self previewLayer] connection] videoOrientation]];
			
			// Turning OFF flash for video recording
            camFlashButtonState = FTCamFlashButtonStateOff;
			[FTCamViewController setFlashMode:AVCaptureFlashModeOff forDevice:[[self videoDeviceInput] device]];
            [toggleFlashButton setImage:[UIImage imageNamed:FLASH_IMAGE_OFF] forState:UIControlStateNormal];
            
			// Start recording to a temporary file.
			NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[@"movie" stringByAppendingPathExtension:@"mov"]];
			[[self movieFileOutput] startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
            
		} else {
			[[self movieFileOutput] stopRecording];
		}
	});
}

- (void)shouldUpdateProgressView:(NSNumber *)progress {
    NSLog(@"%@::updateProgress:",VIEWCONTROLLER_CAM);
    if (![progress isEqualToNumber:[NSDecimalNumber notANumber]]) {
        NSLog(@"progress: %f",[progress floatValue]);
        [self.progressView setProgress:[progress floatValue] animated:YES];
    }
}

- (void)pauseMovieRecording:(id)sender {
    if ([[self movieFileOutput] isRecording]) {
        
    }
}

- (void)didReleaseRecordingButtonAction:(UIButton *)button {
    NSLog(@"%@::didTapStopRecordingButtonAction:",VIEWCONTROLLER_CAM);
    if ([[self movieFileOutput] isRecording]) {
        [[self movieFileOutput] stopRecording];
    }
}

- (void)snapStillImage:(id)sender {
    NSLog(@"%@::snapStillImage:",VIEWCONTROLLER_CAM);
	dispatch_async([self sessionQueue], ^{
		// Update the orientation on the still image output video connection before capturing.
		[[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[self previewLayer] connection] videoOrientation]];
		
		// Flash set to Auto for Still Capture
		//[FTCamViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[[self videoDeviceInput] device]];
		
		// Capture a still image.
		[[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
			
			if (imageDataSampleBuffer) {
				NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
				UIImage *image = [[UIImage alloc] initWithData:imageData];
                UIImage *croppedImage = [self squareImageFromImage:image scaledToSize:320.0f];
				
                if (!self.isProfilePciture && !self.isCoverPhoto) {
                    // Prepare to upload the taken image
                    self.editPhotoViewController = [[FTEditPhotoViewController alloc] initWithImage:croppedImage];
                    [self.navigationController pushViewController:editPhotoViewController animated:NO];
                } else if (self.isProfilePciture){
                    // Return the profile image
                    [self didTakeProfilePictureAction:croppedImage];
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                } else if (self.isCoverPhoto) {
                    [self didTakeCoverPhotoAction:croppedImage];
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                }
            }
		}];
	});
}

- (UIImage *)squareImageFromImage:(UIImage *)image scaledToSize:(CGFloat)newSize {
    
    CGAffineTransform scaleTransform;
    CGPoint origin;
    
    if (image.size.width > image.size.height) {
        CGFloat scaleRatio = newSize / image.size.height;
        scaleTransform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
        
        origin = CGPointMake(-(image.size.width - image.size.height) / 2.0f, 0);
    } else {
        CGFloat scaleRatio = newSize / image.size.width;
        scaleTransform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
        
        origin = CGPointMake(0, -(image.size.height - image.size.width) / 2.0f);
    }
    
    CGSize size = CGSizeMake(newSize, newSize);
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, scaleTransform);
    
    [image drawAtPoint:origin];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer {
	CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)[self previewLayer] captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
	[self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (NSInteger) getTopPaddingNavigationBarHeight:(NSInteger)navBar
                                 previewHeight:(NSInteger)preview
                                 elementHeight:(NSInteger)element
                                   frameHeight:(NSInteger)frame {
    return preview + ((((navBar + frame) - preview) - element) / 2);
}

#pragma mark - ()

- (void)didTakeProfilePictureAction:(UIImage *)photo {
    if ([delegate respondsToSelector:@selector(camViewController:profilePicture:)]){
        [delegate camViewController:self profilePicture:photo];
    }
}

- (void)didSelectProfilePictureAction:(UIImage *)photo {
    if ([delegate respondsToSelector:@selector(camViewController:profilePicture:)]){
        [delegate camViewController:self profilePicture:photo];
    }
}

- (void)didTakeCoverPhotoAction:(UIImage *)photo {
    if ([delegate respondsToSelector:@selector(camViewController:coverPhoto:)]){
        [delegate camViewController:self coverPhoto:photo];
    }
}

- (void)didSelectCoverPhotoAction:(UIImage *)photo {
    if ([delegate respondsToSelector:@selector(camViewController:coverPhoto:)]){
        [delegate camViewController:self coverPhoto:photo];
    }
}

#pragma mark - FTCamRollViewControllerDelegate

- (void)camRollViewController:(FTCamRollViewController *)camRollViewController profilePhoto:(UIImage *)photo {
    [self didSelectProfilePictureAction:photo];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)camRollViewController:(FTCamRollViewController *)camRollViewController coverPhoto:(UIImage *)photo {
    [self didSelectCoverPhotoAction:photo];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
