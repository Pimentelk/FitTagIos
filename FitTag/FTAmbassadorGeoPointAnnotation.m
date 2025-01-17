//
//  FTMapViewController.m
//  FitTag
//
//  Created by Kevin Pimentel on 9/11/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#import "FTAmbassadorGeoPointAnnotation.h"

@interface FTAmbassadorGeoPointAnnotation ()
@property (nonatomic, strong) PFObject *post;
@property (nonatomic, strong) PFUser *user;
@end

@implementation FTAmbassadorGeoPointAnnotation
@synthesize post;
@synthesize user;
@synthesize coordinate;
@synthesize title;
@synthesize subtitle;
@synthesize objectId;

#pragma mark - Initialization

- (id)initWithObject:(PFObject *)aPost {
    self = [super init];
    if (self) {
        post = aPost;
        objectId = post.objectId;
        user = [post objectForKey:kFTPostUserKey];
        
        PFGeoPoint *geoPoint = [self.post objectForKey:kFTPostLocationKey];
        [self setGeoPoint:geoPoint];
    }
    return self;
}

#pragma mark - MKAnnotation

// Called when the annotation is dragged and dropped. We update the geoPoint with the new coordinates.
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:newCoordinate.latitude
                                                  longitude:newCoordinate.longitude];
    [self setGeoPoint:geoPoint];
}

#pragma mark - ()

- (void)setGeoPoint:(PFGeoPoint *)geoPoint {
    coordinate = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
    title = [self.user objectForKey:kFTUserDisplayNameKey];
}

@end
