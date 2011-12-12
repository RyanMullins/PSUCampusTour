//
//  MapViewController.h
//  CampusTour
//
//  Created by Ryan Mullins on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "BuildingInfoViewController.h"

@interface MapViewController : UIViewController <MKMapViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet MKMapView * myMapView;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *myTapGestureRecognizer;

- (IBAction) hexagonTapToZoom:(UITapGestureRecognizer *)tapGestRec;

@end
