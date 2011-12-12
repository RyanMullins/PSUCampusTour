//
//  Event.h
//  CampusTour
//
//  Created by Ryan Mullins on 12/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Event : NSManagedObject

@property (nonatomic, retain) NSString * contributor;
@property (nonatomic, retain) NSString * creator;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSString * datePhotographed;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSString * subTitle;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSManagedObject * building;

@end
