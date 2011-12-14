//
//  MapViewController.m
//  CampusTour
//
//  Created by Ryan Mullins on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "Building.h"
#import "CampusTourModel.h"
#import "KMLParser.h"
#import "BuildingInfoViewController.h"
#import "MapViewController.h"

#define N_SPAN_ANNO_LAT 0.007876
#define N_SPAN_ANN0_LON 0.008006
#define N_SPAN_OVER_LAT 0.013800
#define N_SPAN_OVER_LON 0.013600
#define N_POINT_BOUND_DIM 20

#define S_SEGUE_MAP_BUILDING @"mapToBuilding"

@interface MapViewController()

@property (strong, nonatomic) KMLParser * kml;
@property (strong, nonatomic) CLLocation * myMapCenter;
@property (strong, nonatomic) NSMutableArray * myAnnotations;
@property (strong, nonatomic) Building * myBuilding;

- (void) loadAnnotations;
- (void) loadOverlays;
- (void) loadMapSymbology;

@end

@implementation MapViewController
@synthesize kml;
@synthesize myMapView;
@synthesize myTapGestureRecognizer;
@synthesize myMapCenter;
@synthesize myAnnotations;
@synthesize myBuilding;

#pragma View Controller Methods

- (void) viewDidLoad {
    [super viewDidLoad];
    [self loadMapSymbology];
    [self setTitle:@"University Park"];
    [myMapView setShowsUserLocation:YES];
}

- (void) viewDidUnload {
    [super viewDidUnload];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewWillUnload {
    [super viewWillUnload];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:S_SEGUE_MAP_BUILDING]) {
        [[segue destinationViewController] setBuilding:myBuilding];
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation != UIInterfaceOrientationLandscapeRight &&  toInterfaceOrientation != UIInterfaceOrientationLandscapeLeft);
}

#pragma MapView Delegate Methods

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (annotation == [[self myMapView] userLocation]) {
        return nil;
    }
    
    MKPinAnnotationView * bldgPinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:RI_BLDG_PIN];
    
    if (!bldgPinView) {
        bldgPinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:RI_BLDG_PIN];
    }
    
    CampusTourModel * model = [CampusTourModel sharedInstance];
    NSArray * buildings = [model buildingsWithName:[annotation title]];
    
    if (buildings != nil && [buildings count] > 0) {
        Building * building = [buildings objectAtIndex:0];
        if ([[building events] count] > 0) {
            UIButton * rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [bldgPinView setRightCalloutAccessoryView:rightButton];
        }
        [bldgPinView setPinColor:MKPinAnnotationColorPurple];
    }
    
    [bldgPinView setAnnotation:annotation];
    [bldgPinView setCanShowCallout:YES];
    [bldgPinView setAnimatesDrop:NO];
    return bldgPinView;
}

- (MKOverlayView *) mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    MKOverlayView * view = [kml viewForOverlay:overlay];
    return view;
}

- (void) mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (mapView.region.span.latitudeDelta <= N_SPAN_ANNO_LAT ||
        mapView.region.span.longitudeDelta <= N_SPAN_ANN0_LON) {
        if ([mapView overlays] != nil && [[mapView overlays] count] > 0) {
            [mapView removeOverlays:[mapView overlays]];
            [self loadAnnotations];
        }
    } else {    
        if ([mapView annotations] != nil && [[mapView annotations] count] > 0) {
            [mapView removeAnnotations:[mapView annotations]];
            [self loadOverlays];
        }
    }
}

- (void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    NSString * bldgName = [[view annotation] title];
    NSArray * buildings = [[CampusTourModel sharedInstance] buildingsWithName:bldgName];
    Building * building = [buildings objectAtIndex:0];
    [self setMyBuilding:building];
    [self performSegueWithIdentifier:S_SEGUE_MAP_BUILDING sender:self];
}

#pragma Priavte Map Mehtods

- (void) loadAnnotations {
    CampusTourModel * model = [CampusTourModel sharedInstance];
    NSArray * buildings = [model buildingsWithName:@""];
    NSInteger counter = 0;
    
    for (Building * building in buildings) {
        NSString * name = [building name];
        NSString * year = [building year];
        NSNumber * latitude = [building latitude];
        NSNumber * longitude = [building longitude];
        
        if (name != nil && latitude != nil && longitude != nil) {
            MKPointAnnotation * bldgAnno = [[MKPointAnnotation alloc] init];
            CLLocationCoordinate2D bldgCoord = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);
            NSMutableString * subtitle = [[NSMutableString alloc] initWithString:@"University Park"];
            
            if (year != nil && ![year isEqualToString:@""]) {
                [subtitle appendFormat:@" - %@", year];
            }
            
            [bldgAnno setCoordinate:bldgCoord];
            [bldgAnno setSubtitle:subtitle];
            [bldgAnno setTitle:name];
            
            [myMapView addAnnotation:bldgAnno];
            [myAnnotations addObject:bldgAnno];
            counter++;
        }
    }
}

- (void) loadMapSymbology {
    [self loadOverlays];
    MKMapRect flyTo = MKMapRectNull;
    
    for (id <MKOverlay> overlay in [myMapView overlays]) {
        if (MKMapRectIsNull(flyTo)) {
            flyTo = [overlay boundingMapRect];
        } else {
            flyTo = MKMapRectUnion(flyTo, [overlay boundingMapRect]);
        }
    }
    
    [myMapView setVisibleMapRect:flyTo];
}

- (void) loadOverlays {
    if ([[myMapView overlays] count] <= 0) {
        NSString * hexagonPath = [[NSBundle mainBundle] pathForResource:@"hexagons" ofType:@"kml"];
        kml = [KMLParser parseKMLAtPath:hexagonPath];
        NSArray * overlays = [kml overlays];
        [myMapView addOverlays:overlays];
    }
}

#pragma Gesture Handler Methods

- (void) hexagonTapToZoom:(UITapGestureRecognizer *)tapGestRec {
    if ([[myMapView overlays] count] > 0) {
        CGPoint tapPoint = [tapGestRec locationInView:myMapView];
        CGPoint upperLeft = CGPointMake(tapPoint.x - N_POINT_BOUND_DIM/2, tapPoint.y - N_POINT_BOUND_DIM/2);
        CGPoint lowerRight = CGPointMake(tapPoint.x + N_POINT_BOUND_DIM/2, tapPoint.y + N_POINT_BOUND_DIM/2);
        CLLocationCoordinate2D ulCoord = [myMapView convertPoint:upperLeft toCoordinateFromView:myMapView];
        CLLocationCoordinate2D lrCoord = [myMapView convertPoint:lowerRight toCoordinateFromView:myMapView];
        MKMapPoint ulMapPoint = MKMapPointForCoordinate(ulCoord);
        MKMapPoint lrMapPoint = MKMapPointForCoordinate(lrCoord);
        MKMapRect tapRect = MKMapRectMake(ulMapPoint.x, ulMapPoint.y, (lrMapPoint.x - ulMapPoint.x), (ulMapPoint.y - lrMapPoint.y));
        MKMapRect flyTo = MKMapRectNull;
        
        for (id<MKOverlay> overlay in [kml overlays]) {
            if ([overlay intersectsMapRect:tapRect]) {
                if (MKMapRectIsNull(flyTo)) {
                    flyTo = [overlay boundingMapRect];
                } else {
                    flyTo = MKMapRectUnion(flyTo, [overlay boundingMapRect]);
                }
            }
        }
        
        if (myMapView.region.span.longitudeDelta <= N_SPAN_OVER_LON || myMapView.region.span.latitudeDelta <= N_SPAN_OVER_LAT) {
            flyTo = MKMapRectMake(flyTo.origin.x, flyTo.origin.y, flyTo.size.width/2.0, flyTo.size.height/2.0);
        } 
        
        if (!MKMapRectIsNull(flyTo)) {
            [myMapView setVisibleMapRect:flyTo];
        }
    } else {
        CGPoint tapPoint = [tapGestRec locationInView:myMapView];
        CLLocationCoordinate2D tapCoord = [myMapView convertPoint:tapPoint toCoordinateFromView:myMapView];
        MKCoordinateSpan span = MKCoordinateSpanMake(0.5 * myMapView.region.span.latitudeDelta, 0.5 * myMapView.region.span.longitudeDelta);
        [myMapView setRegion:MKCoordinateRegionMake(tapCoord, span)];
    }
}

@end
