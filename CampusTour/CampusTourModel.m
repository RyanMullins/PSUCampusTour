//
//  CampusTourModel.m
//  CampusTour
//
//  Created by Ryan Mullins on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "CampusTourModel.h"
#import "Building.h"
#import "Event.h"
#import "KMLParser.h"

#define S_BLDGS_BY_DIST @"http://m.psu.edu/scripts/bldg_by_distance.php?lat=%f&long=%f&radius=%f"
#define S_BLDGS_BY_NAME @"http://m.psu.edu/scripts/bldg_by_name.php?name=%@&campus=%@"
#define S_CAMPUS_DEFAULT @"UP"

#define S_BLDGS_FILE_NAME @"buildings"
#define S_BLDGS_FILE_TYPE @"json"
#define S_EVENT_FILE_NAME @"events"
#define S_EVENT_FILE_TYPE @"xml"

#define S_EVENT_XML_RECORD @"record"
#define S_EVENT_XML_CONTRIBUTOR @"contributor"
#define S_EVENT_XML_CREATOR @"creator"
#define S_EVENT_XML_DATE @"date"
#define S_EVENT_XML_PHOTOGRAPHED @"date.photographed"
#define S_EVENT_XML_DESCRIPTION @"description"
#define S_EVENT_XML_IMAGE_URL @"filepath"
#define S_EVENT_XML_SUB_TITLE @"title.alternate"
#define S_EVENT_XML_TITLE @"title"
#define S_EVENT_XML_TYPE @"contributor"

@interface CampusTourModel()

@property (strong, nonatomic) NSMutableData * myBuildingQueryData;
@property (strong, nonatomic) NSURLConnection * myBuildingQueryConnection;

@property (strong, nonatomic) NSMutableArray * myXmlEvents;
@property (strong, nonatomic) NSMutableDictionary * myXmlEvent;
@property (strong, nonatomic) NSMutableString * myXmlElement;
@property (assign, nonatomic) BOOL waitingRecord;
@property (assign, nonatomic) BOOL waitingContributor;
@property (assign, nonatomic) BOOL waitingCreator;
@property (assign, nonatomic) BOOL waitingDate;
@property (assign, nonatomic) BOOL waitingPhotogrpahed;
@property (assign, nonatomic) BOOL waitingDescription;
@property (assign, nonatomic) BOOL waitingImageURL;
@property (assign, nonatomic) BOOL waitingSubTitle;
@property (assign, nonatomic) BOOL waitingTitle;
@property (assign, nonatomic) BOOL waitingType;

@property (strong, nonatomic, readonly) NSManagedObjectContext * myManagedObjectContext;
@property (strong, nonatomic, readonly) NSManagedObjectModel * myManagedObjectModel;
@property (strong, nonatomic, readonly) NSPersistentStoreCoordinator * myStoreCoordinator;

- (BOOL) doesDatabaseExist;
- (NSArray *) fetchManagedObjectsForEntity:(NSString*)entityName withPredicate:(NSPredicate*)predicate;
- (NSManagedObjectContext *) managedObjectContext;
- (NSManagedObjectModel *) managedObjectModel;
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator;
- (NSString *) applicaitonDocumentsDirectory;
- (NSString *) databasePath;
- (void) alertConnectionFailureWithMessage:(NSString *)message;
- (void) connectEventsToBuildings;
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void) connectionDidFinishLoading:(NSURLConnection *)connection;
- (void) createDatabase;
- (void) createBuildingFromDictionary:(NSDictionary *)bldgDict;
- (void) createEventFromDicitonary:(NSDictionary *)eventDict;
- (void) loadBuildings;
- (void) loadEvents;
- (void) saveContext;

@end

@implementation CampusTourModel

@synthesize myBuildingQueryData;
@synthesize myBuildingQueryConnection;
@synthesize myXmlEvents, myXmlElement, myXmlEvent;
@synthesize waitingContributor, waitingCreator, waitingDate, waitingDescription, waitingImageURL, 
            waitingPhotogrpahed, waitingRecord, waitingSubTitle, waitingTitle, waitingType;

@synthesize myManagedObjectContext = _myManagedObjectContext;
@synthesize myManagedObjectModel = _myManagedObjectModel;
@synthesize myStoreCoordinator = _myStoreCoordinator;

#pragma Instantiation

+ (id) sharedInstance {
    static id model = nil;
    
    if (model == nil) {
        model = [[self alloc] init];
        [model setMyBuildingQueryConnection:nil];
        [model setMyBuildingQueryData:nil];
        
        if (![model doesDatabaseExist]) {
            [model createDatabase];
        }
    } 
    
    return model;
}

#pragma Managed Object Context, Model, and Persistent Store

- (NSString *) applicaitonDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSString *) databasePath {
    return [[self applicaitonDocumentsDirectory] stringByAppendingPathComponent:@"CampusTour.sqlite"];
}

- (BOOL) doesDatabaseExist {
    NSString * dbPath = [self databasePath];
    return [[NSFileManager defaultManager] fileExistsAtPath:dbPath];
}

- (NSManagedObjectContext *) managedObjectContext {
    if (_myManagedObjectContext != nil) {
        return _myManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator * storeCoordinator = [self persistentStoreCoordinator];
    if (storeCoordinator != nil) {
        _myManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [_myManagedObjectContext setPersistentStoreCoordinator:storeCoordinator];
    }
    
    return _myManagedObjectContext;
}

- (NSManagedObjectModel *) managedObjectModel {
    if (_myManagedObjectModel != nil) {
        return _myManagedObjectModel;
    }
    
    NSString * modelPath = [[NSBundle mainBundle] pathForResource:@"CampusTour" ofType:@"momd"];
    NSURL * modelURL = [NSURL fileURLWithPath:modelPath];
    _myManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _myManagedObjectModel;
}

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if (_myStoreCoordinator != nil) {
        return _myStoreCoordinator;
    }
    
    _myStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[CampusTourModel sharedInstance] managedObjectModel]];
    NSURL * storeURL = [NSURL fileURLWithPath:[[self applicaitonDocumentsDirectory] stringByAppendingPathComponent:@"CampusTour.sqlite"]];
    NSError * error = nil;
    if (![_myStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    return _myStoreCoordinator;
}

- (void) saveContext {
    if (_myManagedObjectContext) {
        NSError * error = nil;
        if ([_myManagedObjectContext hasChanges] && ![_myManagedObjectContext save:&error]) {
            NSLog(@"Unresolved error: %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma Database Creation 

- (void) createDatabase {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    CampusTourModel * model = [CampusTourModel sharedInstance];
    [model loadBuildings];
    [model loadEvents];
    [model connectEventsToBuildings];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma Database - Building Data 

- (void) loadBuidlingsForLocation:(CLLocation *)location forRadius:(CGFloat)radius {
    NSString * urlString = [NSString stringWithFormat:S_BLDGS_BY_DIST, location.coordinate.latitude, location.coordinate.longitude, radius];
    NSURL * url = [NSURL URLWithString:urlString];
    NSURLRequest * request = [NSURLRequest requestWithURL:url];
    [self setMyBuildingQueryConnection:[NSURLConnection connectionWithRequest:request delegate:self]];
}

- (void) loadBuildings {
    // From local JSON data 
    NSURL * jsonUrl = [[NSBundle mainBundle] URLForResource:@"buildings" withExtension:@"json"];
    NSData * jsonData = [NSData dataWithContentsOfURL:jsonUrl];
    NSError * error;
    NSArray * jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData 
                                                           options:NSJSONReadingMutableContainers 
                                                             error:&error];
    
    for (NSDictionary * building in jsonObject) {
        [self createBuildingFromDictionary:building];
    }
    
    /*
    // From the http://m.psu.edu Web-Service
    NSString * urlString = [NSString stringWithFormat:S_BLDGS_BY_NAME, @"", @"UP"];
    NSURL * url = [NSURL URLWithString:urlString];
    NSURLRequest * request = [NSURLRequest requestWithURL:url];
    [self setMyBuildingQueryConnection:[NSURLConnection connectionWithRequest:request delegate:self]];
     */
}

- (NSDictionary *) buildingDataFromPlacemark:(CLPlacemark *)placemark {
    return nil;
}

- (void) createBuildingFromDictionary:(NSDictionary *)bldgDict {
    NSString * lat = [bldgDict objectForKey:S_BUILDING_LATITUDE];
    NSString * lon = [bldgDict objectForKey:S_BUILDING_LONGITUDE];
    NSString * name = [bldgDict objectForKey:S_BUILDING_NAME];
    NSString * oppCode = [bldgDict objectForKey:S_BUILDING_OPP_CODE];
    id yearConst = [bldgDict objectForKey:S_BUILDING_YEAR];
    
    if ([yearConst isKindOfClass:[NSNull class]]) {
        yearConst = @"";
    }
    
    Building * bldg = [NSEntityDescription insertNewObjectForEntityForName:S_ENTITY_BUILDING 
                                                    inManagedObjectContext:[[CampusTourModel sharedInstance] managedObjectContext]];
    [bldg setLatitude:[NSNumber numberWithDouble:[lat doubleValue]]];
    [bldg setLongitude:[NSNumber numberWithDouble:[lon doubleValue]]];
    [bldg setName:name];
    [bldg setOppCode:oppCode];
    [bldg setYear:yearConst];
    [self saveContext];
}

- (NSArray *) buildingsWithName:(NSString *)name {
    NSArray * queryResults = nil;
    
    if (name == nil || [name isEqualToString:@""]) {
        queryResults = [self fetchManagedObjectsForEntity:S_ENTITY_BUILDING withPredicate:nil];
    } else {
        NSString * predicateFormat = [NSString stringWithFormat:@"name = '%@'", name];
        NSPredicate * predicate = [NSPredicate predicateWithFormat:predicateFormat];
        queryResults = [self fetchManagedObjectsForEntity:S_ENTITY_BUILDING withPredicate:predicate];
    }
    
    return queryResults;
}

- (void) connectEventsToBuildings {
    CampusTourModel * model = [CampusTourModel sharedInstance];
    NSArray * buildings = [model fetchManagedObjectsForEntity:S_ENTITY_BUILDING withPredicate:nil];
    
    for (Building * building in buildings) {
        NSString * predString = [NSString stringWithFormat:@"title MATCHES '.*%@.*'", [building name]];
        NSPredicate * eventPred = [NSPredicate predicateWithFormat:predString argumentArray:nil];
        NSArray * events = [model fetchManagedObjectsForEntity:S_ENTITY_EVENT withPredicate:eventPred];
        NSSet * eventSet = [NSSet setWithArray:events];
        [building addEvents:eventSet];
    }
    
    [self saveContext];
}

#pragma Database - Event Data

- (void) loadEvents {    
    [self setMyXmlEvents:[[NSMutableArray alloc] init]];
    NSURL * eventFileURL = [[NSBundle mainBundle] URLForResource:S_EVENT_FILE_NAME withExtension:S_EVENT_FILE_TYPE];
    NSData * eventData = [NSData dataWithContentsOfURL:eventFileURL];
    NSXMLParser * xmlParser = [[NSXMLParser alloc] initWithData:eventData];
    [xmlParser setDelegate:self];
    [xmlParser parse];
    
    for (NSDictionary * event in myXmlEvents) {
        [self createEventFromDicitonary:event];
    }
}

- (void) createEventFromDicitonary:(NSDictionary *)eventDict {
    NSString * contributor = [eventDict objectForKey:S_EVENT_CONTRIBUTOR];
    NSString * creator = [eventDict objectForKey:S_EVENT_CREATOR];
    NSString * date = [eventDict objectForKey:S_EVENT_DATE];
    NSString * desc = [eventDict objectForKey:S_EVENT_DESCRIPTION];
    NSString * image = [eventDict objectForKey:S_EVENT_IMAGE_URL];
    NSString * photographed = [eventDict objectForKey:S_EVENT_PHOTOGRAPHED];
    NSString * subTitle = [eventDict objectForKey:S_EVENT_SUB_TITLE];
    NSString * title = [eventDict objectForKey:S_EVENT_TITLE];
    NSString * type = [eventDict objectForKey:S_EVENT_TYPE];
    
    Event * event = [NSEntityDescription insertNewObjectForEntityForName:S_ENTITY_EVENT 
                                                  inManagedObjectContext:[self myManagedObjectContext]];
    [event setContributor:contributor];
    [event setCreator:creator];
    [event setDate:date];
    [event setDatePhotographed:photographed];
    [event setDesc:desc];
    [event setImageURL:image];
    [event setSubTitle:subTitle];
    [event setTitle:title];
    [event setType:type];
    [self saveContext];
}

- (NSArray *) eventsBetweenStart:(NSInteger)startYear andEnd:(NSInteger)endYear forBuilding:(id)building {
    Building * bldg = (Building *)building;
    NSMutableSet * mutEvents = [[NSMutableSet alloc] init];
    
    for (Event * event in [bldg events]) {
        if ([[event datePhotographed] integerValue] >= startYear &&
            [[event datePhotographed] integerValue] < endYear) {
            [mutEvents addObject:event];
        }
    }
    
    NSSortDescriptor * descriptor = [[NSSortDescriptor alloc] initWithKey:S_EVENT_PHOTOGRAPHED ascending:YES];
    NSArray * events = [mutEvents sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
    return events;
}

- (NSArray *) eventsForBuiling:(id)building {
    Building * bldg = (Building *) building;
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"building.name MATCHES '%@'", [bldg name]];
    NSArray * events = [self fetchManagedObjectsForEntity:S_ENTITY_EVENT withPredicate:predicate];
    return  events;
}

#pragma Retrieving Core Data 

- (NSArray *) fetchManagedObjectsForEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate {
    NSManagedObjectContext * context = [self managedObjectContext];
    NSEntityDescription * entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setPredicate:predicate];
    NSString * sortField = nil;
    
    if ([entityName isEqualToString:@"Event"]) {
        sortField = S_EVENT_PHOTOGRAPHED;
    } else {
        sortField = S_BUILDING_NAME;
    }
    
    NSSortDescriptor * descriptor = [[NSSortDescriptor alloc] initWithKey:sortField ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:descriptor]];
    NSArray * results = [context executeFetchRequest:request error:nil];
    return results;
}

#pragma NSURLConnection Delegate Methods

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self setMyBuildingQueryData:[NSMutableData data]];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [[self myBuildingQueryData] appendData:data];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self alertConnectionFailureWithMessage:@"Connection failed during query."];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([[self myBuildingQueryData] length] > 0) {
        NSError * error = nil;
        NSArray * jsonReults = (NSArray *)[NSJSONSerialization JSONObjectWithData:[self myBuildingQueryData] 
                                                                          options:NSJSONReadingMutableContainers 
                                                                            error:&error];
        if (error != nil || [jsonReults count] <= 0) {
            [self alertConnectionFailureWithMessage:@"Query returned no results."];
        }
        
        for (NSDictionary * bldg in jsonReults) {
            [self createBuildingFromDictionary:bldg];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NC_BLDG_DATA_DOWNLOADED object:[CampusTourModel sharedInstance]];
    } else {
        [self alertConnectionFailureWithMessage:@"Invalid query result."];
    }
    [[CampusTourModel sharedInstance] saveContext];
}

#pragma NSXMLParser Delegate Mehtods

- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI 
                                        qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:S_EVENT_XML_RECORD]) {
        myXmlEvent = [[NSMutableDictionary alloc] init];
        waitingRecord = YES;
    } 
    
    if (waitingRecord) {
        waitingContributor = [elementName isEqualToString:S_EVENT_XML_CONTRIBUTOR];
        waitingCreator = [elementName isEqualToString:S_EVENT_XML_CREATOR];
        waitingDate = [elementName isEqualToString:S_EVENT_XML_DATE];
        waitingDescription = [elementName isEqualToString:S_EVENT_XML_DESCRIPTION];
        waitingImageURL = [elementName isEqualToString:S_EVENT_XML_IMAGE_URL];
        waitingPhotogrpahed = [elementName isEqualToString:S_EVENT_XML_PHOTOGRAPHED];
        waitingSubTitle = [elementName isEqualToString:S_EVENT_XML_SUB_TITLE];
        waitingTitle = [elementName isEqualToString:S_EVENT_XML_TITLE];
        waitingType = [elementName isEqualToString:S_EVENT_XML_TYPE];
        myXmlElement = [[NSMutableString alloc] init];
    }
}

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI 
                                      qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:S_EVENT_XML_RECORD] && waitingRecord) {
        [myXmlEvents addObject:myXmlEvent];
        myXmlEvent = nil;
        waitingRecord = NO;
    }
    
    if (waitingRecord) {
        if (myXmlElement == nil) {
            [myXmlElement setString:@""];
        }
        
        if (waitingContributor && [elementName isEqualToString:S_EVENT_XML_CONTRIBUTOR]) {
            [myXmlEvent setValue:myXmlElement forKey:S_EVENT_CONTRIBUTOR];
            waitingContributor = NO;
        }
        if (waitingCreator && [elementName isEqualToString:S_EVENT_XML_CREATOR]) {
            [myXmlEvent setValue:myXmlElement forKey:S_EVENT_CREATOR];
            waitingCreator = NO;
        }
        if (waitingDate && [elementName isEqualToString:S_EVENT_XML_DATE]) {
            [myXmlEvent setValue:myXmlElement forKey:S_EVENT_DATE];
            waitingDate = NO;
        }
        if (waitingDescription && [elementName isEqualToString:S_EVENT_XML_DESCRIPTION]) {
            [myXmlEvent setValue:myXmlElement forKey:S_EVENT_DESCRIPTION];
            waitingDescription = NO;
        }
        if (waitingImageURL && [elementName isEqualToString:S_EVENT_XML_IMAGE_URL]) {
            [myXmlEvent setValue:myXmlElement forKey:S_EVENT_IMAGE_URL];
            waitingImageURL = NO;
        }
        if (waitingPhotogrpahed && [elementName isEqualToString:S_EVENT_XML_PHOTOGRAPHED]) {
            [myXmlEvent setValue:myXmlElement forKey:S_EVENT_PHOTOGRAPHED];
            waitingPhotogrpahed = NO;
        }
        if (waitingSubTitle && [elementName isEqualToString:S_EVENT_XML_SUB_TITLE]) {
            [myXmlEvent setValue:myXmlElement forKey:S_EVENT_SUB_TITLE];
            waitingSubTitle = NO;
        }
        if (waitingTitle && [elementName isEqualToString:S_EVENT_XML_TITLE]) {
            [myXmlEvent setValue:myXmlElement forKey:S_EVENT_TITLE];
            waitingTitle = NO;
        }
        if (waitingType && [elementName isEqualToString:S_EVENT_XML_TYPE]) {
            [myXmlEvent setValue:myXmlElement forKey:S_EVENT_TYPE];
            waitingType = NO;
        }
        
        myXmlElement = nil;
    }
}

- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [myXmlElement appendString:string];
}

- (void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    [self alertConnectionFailureWithMessage:@"Error parsing events library"];
}

#pragma Alert & Notification Methods
- (void) alertConnectionFailureWithMessage:(NSString *)message {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Connection Failure" 
                                                     message:message
                                                    delegate:nil 
                                           cancelButtonTitle:@"OK" 
                                           otherButtonTitles:nil];
    [alert show];
}

@end
