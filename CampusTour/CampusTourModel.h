//
//  CampusTourModel.h
//  CampusTour
//
//  Created by Ryan Mullins on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CampusTourModel : NSObject <NSXMLParserDelegate>

+ (id) sharedInstance;
//- (NSDictionary *) buildingDataFromPlacemark:(CLPlacemark *)placemark;
- (NSArray *) buildingsWithName:(NSString *)name;
- (NSArray *) eventsForBuiling:(id)building;
- (NSArray *) eventsBetweenStart:(NSInteger)startYear andEnd:(NSInteger)endYear forBuilding:(id)building;

@end
