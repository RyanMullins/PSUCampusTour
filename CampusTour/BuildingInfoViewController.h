//
//  MasterViewController.h
//  CampusTour
//
//  Created by Ryan Mullins on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Building.h"

@interface BuildingInfoViewController : UITableViewController 

@property (strong, nonatomic) Building * building;

@end
