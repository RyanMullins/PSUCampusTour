//
//  MasterViewController.m
//  CampusTour
//
//  Created by Ryan Mullins on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BuildingInfoViewController.h"
#import "EventDetailViewController.h"
#import "Building.h"
#import "Event.h"
#import "CampusTourModel.h"

#define S_SEGUE_BLDG_EVENT @"buildingToEvent"

@interface BuildingInfoViewController ()

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (NSArray *) eventsInSection:(NSInteger)section InTableView:(UITableView *)tableView;
- (NSArray *) sectionYearBoundsForTableView:(UITableView *)tableView andSection:(NSInteger)section;

@end

@implementation BuildingInfoViewController
@synthesize building;

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void) viewDidLoad {
    [super viewDidLoad];
}

- (void) viewDidUnload {
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setTitle:[building name]];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationLandscapeRight &&  interfaceOrientation != UIInterfaceOrientationLandscapeLeft);
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sectionCount = 0;
    
    if (building != nil) {
        NSCalendar * calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDate * today = [[NSDate alloc] init];
        NSDateComponents * dateComponents = [calendar components:NSYearCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit 
                                                        fromDate:today];
        NSInteger currentYear = [dateComponents year];
        NSInteger interval = 0;
        NSSortDescriptor * descriptor = [[NSSortDescriptor alloc] initWithKey:S_EVENT_PHOTOGRAPHED ascending:YES];
        NSArray * events = [[building events] sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
        
        if ([events count] <= 0) {
            return 0;
        }
        
        if ([building year] != nil && ![[building year] isEqualToString:@""]) {
            NSInteger bldgYear = [[building year] integerValue];
            interval = currentYear - bldgYear;
        } else {
            Event * first = nil;
            
            for (Event * event in events) {
                if ([event datePhotographed] != nil && 
                    ![[event datePhotographed] isEqualToString:@""] && 
                    ![[event datePhotographed] isEqualToString:@"0"] ) {
                    first = event;
                    break;
                }
            }
        
            NSInteger eventYear = [[first datePhotographed] integerValue];
            interval = currentYear - eventYear;
        }
        
        if (interval != 0) {
            sectionCount = interval / 10 + 1;
        }
        
        if (interval % 10 != 0) {
            sectionCount++;
        }
    }
    
    return sectionCount;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowCount = 0;
    NSArray * events = [self eventsInSection:section InTableView:tableView];
    
    if (events != nil && [events count] > 0) {
        rowCount = [events count];
    }
    
    return rowCount;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * CellIdentifier = @"eventCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if (!cell || cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"eventCell"];
    }
    
    CampusTourModel * model = [CampusTourModel sharedInstance];
    NSArray * bounds = [self sectionYearBoundsForTableView:[self tableView] andSection:[indexPath section]];
    NSNumber * start = [bounds objectAtIndex:0];
    NSNumber * end = [bounds objectAtIndex:1];
    NSArray * events = [model eventsBetweenStart:[start integerValue] andEnd:[end integerValue] forBuilding:building];
    Event * event = [events objectAtIndex:[indexPath row]];
    NSString * title = [event subTitle];
    NSMutableString * subtitle = [[NSMutableString alloc] init];
    
    if ([event datePhotographed] != nil && ![[event datePhotographed] isEqualToString:@"0"]) {
        [subtitle appendString:[event datePhotographed]];
        if ([event contributor] != nil && ![[event contributor] isEqualToString:@""]) {
            [subtitle appendFormat:@" | %@", [event contributor]];
        }
    }
    
    [[cell textLabel] setNumberOfLines:0];
    [[cell textLabel] setText:title];
    [[cell detailTextLabel] setNumberOfLines:0];
    [[cell detailTextLabel] setText:subtitle];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSInteger sectionCount = [self numberOfSectionsInTableView:tableView];
    
    if (section == (sectionCount - 1)) {
        return @"No date";
    } else {
        NSArray * bounds = [self sectionYearBoundsForTableView:tableView andSection:section];
        NSInteger rowCount = [self tableView:tableView numberOfRowsInSection:section];
        
        if (rowCount == 0) {
            return @"";
        } else {
            return [NSString stringWithFormat:@"%d's", [[bounds objectAtIndex:0] integerValue]];
        }
    }
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:S_SEGUE_BLDG_EVENT sender:self];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:S_SEGUE_BLDG_EVENT]) {
        NSIndexPath * indexPath = [self.tableView indexPathForSelectedRow];
        Event * event = [[self eventsInSection:[indexPath section] InTableView:[self tableView]] objectAtIndex:[indexPath row]];
        [[segue destinationViewController] setDetailItem:event];
        [[segue destinationViewController] setTitle:[self title]];
    }
}

- (NSArray *) sectionYearBoundsForTableView:(UITableView *)tableView andSection:(NSInteger)section {
    NSArray * bounds = nil;
    if (section == ([tableView numberOfSections] - 1)) {
        bounds = [NSArray arrayWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:1], nil];
    } else {
        NSCalendar * calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDate * today = [[NSDate alloc] init];
        NSDateComponents * dateComponents = [calendar components:NSYearCalendarUnit fromDate:today];
        NSInteger currentYear = [dateComponents year];
        NSInteger sectionCount = [tableView numberOfSections];
        NSInteger sectionYear = currentYear - ((sectionCount - section - 2) * 10);      // This isn't magic: -1 no date, -1 for index offset
        NSNumber * sectionLow = [NSNumber numberWithInteger:(sectionYear - (sectionYear % 10))];
        NSNumber * sectionHigh = [NSNumber numberWithInteger:(sectionYear + (10 - (sectionYear % 10)))];
        bounds = [NSArray arrayWithObjects:sectionLow, sectionHigh, nil];
    }
    return bounds;
}

- (NSArray *) eventsInSection:(NSInteger)section InTableView:(UITableView *)tableView {
    NSArray * events = nil;
    CampusTourModel * model = [CampusTourModel sharedInstance];
    NSArray * bounds = [self sectionYearBoundsForTableView:tableView andSection:section];
    NSNumber * low = [bounds objectAtIndex:0];
    NSNumber * high = [bounds objectAtIndex:1];
    events = [model eventsBetweenStart:[low integerValue] 
                                andEnd:[high integerValue] 
                           forBuilding:building];
    return events;
}

@end
