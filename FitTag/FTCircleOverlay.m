//
//  FTCircleOverlay.m
//  FitTag
//
//  Created by Kevin Pimentel on 9/14/14.
//  Copyright (c) 2014 Kevin Pimentel. All rights reserved.
//

#import "FTCircleOverlay.h"

@implementation FTCircleOverlay
@synthesize radius = _radius;
@synthesize coordinate = _coordinate;

#pragma mark - Initialization

- (id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate radius:(CLLocationDistance)aRadius {
    NSLog(@"%@::initWithCoordinate:radius:",VIEWCONTROLLER_CIRCLE);
    NSLog(@"aCoordinate: %f - %f",aCoordinate.latitude,aCoordinate.longitude);
    NSLog(@"aRadius: %f",aRadius);
    
    self = [super init];
    if (self) {
        _coordinate = aCoordinate;
        _radius = aRadius;
    }
    return self;
}


#pragma mark - MKAnnotation

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    NSLog(@"%@::setCoordinate:",VIEWCONTROLLER_CIRCLE);
    NSLog(@"newCoordinate: %f - %f",newCoordinate.latitude,newCoordinate.longitude);
    _coordinate = newCoordinate;
}

- (MKMapRect)boundingMapRect {
    NSLog(@"%@::boundingMapRect:",VIEWCONTROLLER_CIRCLE);
    MKMapPoint centerMapPoint = MKMapPointForCoordinate(_coordinate);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(_coordinate, _radius * 2, _radius * 2);
    return MKMapRectMake(centerMapPoint.x,
                         centerMapPoint.y,
                         region.span.latitudeDelta,
                         region.span.longitudeDelta);
}

@end