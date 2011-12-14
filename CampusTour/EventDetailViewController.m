//
//  DetailViewController.m
//  CampusTour
//
//  Created by Ryan Mullins on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "EventDetailViewController.h"
#import "Event.h"

#define N_SCROLL_COMPONENT_MAX_WIDTH 280.0
#define N_SCROLL_COMPONENT_MAX_HEIGHT 500.0
#define N_SCROLL_COMPONENT_INDENT 20.0

@interface EventDetailViewController ()

@property (strong, nonatomic) Event * myEvent;

- (UIView *) viewForAttribution;
- (UIView *) viewForDescription;
- (UIView *) viewForTitle;

- (void) configureView;
- (void) configureScrollView;

@end

@implementation EventDetailViewController
@synthesize detailItem = _detailItem;
@synthesize imageView = _imageView;
@synthesize scrollView = _scrollView;
@synthesize tapGestureRecognizer = _tapGestureRecognizer;
@synthesize myEvent;

#pragma mark - Managing the detail item

- (void) setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        [self setMyEvent:(Event *)_detailItem];
        [self configureView];
    }
}

- (void) configureView {
    if (self.detailItem) {
        NSURL * imageUrl = [NSURL URLWithString:[myEvent imageURL]];
        NSData * imageData = [NSData dataWithContentsOfURL:imageUrl];
        UIImage * image = [UIImage imageWithData:imageData];
        if (image != nil) {
            [[self imageView] setImage:image];
        }
        
        [self configureScrollView];
        [[self scrollView] setHidden:YES];
    }
}

- (void) configureScrollView {
    UIView * attributionView = [self viewForAttribution];
    UIView * descriptionView = [self viewForDescription];
    UIView * titleView = [self viewForTitle];
    CGRect titleFrame = [titleView frame];
    CGRect attributionFrame = [attributionView frame];
    CGRect descriptionFrame = [descriptionView frame];
    attributionFrame = CGRectMake(N_SCROLL_COMPONENT_INDENT, 
                                  titleFrame.size.height, 
                                  attributionFrame.size.width, 
                                  attributionFrame.size.height);
    descriptionFrame = CGRectMake(N_SCROLL_COMPONENT_INDENT, 
                                  titleFrame.size.height + attributionFrame.size.height, 
                                  descriptionFrame.size.width, 
                                  descriptionFrame.size.height);
    [attributionView setFrame:attributionFrame];
    [descriptionView setFrame:descriptionFrame];
    CGSize scrollViewSize = CGSizeMake(self.scrollView.frame.size.width, 
                                       titleFrame.size.height + attributionFrame.size.height + descriptionFrame.size.height);
    [[self scrollView] setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.75]];
    [[self scrollView] setContentSize:scrollViewSize];
    [[self scrollView] addSubview:descriptionView];
    [[self scrollView] addSubview:attributionView];
    [[self scrollView] addSubview:titleView];
}

- (UIView *) viewForAttribution {
    UILabel * attributionLabel = [[UILabel alloc] init];
    NSString * contributor = [myEvent contributor];
    NSString * creator = [myEvent creator];
    NSString * year = [myEvent datePhotographed];
    NSMutableString * attributionString = [[NSMutableString alloc] init];
    
    if (creator != nil && [creator length] > 1) {
        [attributionString appendFormat:@"Created by: %@\n", creator];
    }
    
    if (contributor != nil && [contributor length] > 1) {
        [attributionString appendFormat:@"Contriubted by: %@\n", contributor];
    }
    
    if (year != nil && [year length] > 1) {
        [attributionString appendFormat:@"Photogrpahed in %@", year];
    }
    
    CGSize maxSize = CGSizeMake(N_SCROLL_COMPONENT_MAX_WIDTH, N_SCROLL_COMPONENT_MAX_HEIGHT);
    CGSize attributionSize = [attributionString sizeWithFont:[UIFont systemFontOfSize:12.0] 
                                           constrainedToSize:maxSize];
    CGRect frame = CGRectMake(N_SCROLL_COMPONENT_INDENT, 0, attributionSize.width, attributionSize.height);
    [attributionLabel setBackgroundColor:[UIColor clearColor]];
    [attributionLabel setFont:[UIFont systemFontOfSize:12.0]];
    [attributionLabel setFrame:frame];
    [attributionLabel setNumberOfLines:0];
    [attributionLabel setText:attributionString];
    [attributionLabel setTextColor:[UIColor whiteColor]];
    [attributionLabel setUserInteractionEnabled:NO];
    return attributionLabel;
}

- (UIView *) viewForDescription {
    UILabel * descriptionLabel = [[UILabel alloc] init];
    NSString * descriptionText = [myEvent desc];
    
    if (descriptionText == nil || [descriptionText length] < 1) {
        [descriptionLabel setFrame:CGRectMake(0, 0, 0, 0)];
        return descriptionLabel;
    }
    
    CGSize maxSize = CGSizeMake(N_SCROLL_COMPONENT_MAX_WIDTH, N_SCROLL_COMPONENT_MAX_HEIGHT);
    CGSize descSize = [descriptionText sizeWithFont:[UIFont systemFontOfSize:14.0] 
                                  constrainedToSize:maxSize];
    CGRect frame = CGRectMake(N_SCROLL_COMPONENT_INDENT, 0, descSize.width, descSize.height);
    [descriptionLabel setBackgroundColor:[UIColor clearColor]];
    [descriptionLabel setFont:[UIFont systemFontOfSize:14.0]];
    [descriptionLabel setFrame:frame];
    [descriptionLabel setNumberOfLines:0];
    [descriptionLabel setText:descriptionText];
    [descriptionLabel setTextColor:[UIColor whiteColor]];
    [descriptionLabel setUserInteractionEnabled:NO];
    return descriptionLabel;
}

- (UIView *) viewForTitle {
    UILabel * titleLabel = [[UILabel alloc] init];
    NSString * titleString = [myEvent subTitle];
    CGSize maxSize = CGSizeMake(N_SCROLL_COMPONENT_MAX_WIDTH, N_SCROLL_COMPONENT_MAX_HEIGHT);
    CGSize titleSize = [titleString sizeWithFont:[UIFont boldSystemFontOfSize:20.0] 
                               constrainedToSize:maxSize];
    CGRect frame = CGRectMake(N_SCROLL_COMPONENT_INDENT, 0, titleSize.width, titleSize.height);
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
    [titleLabel setFrame:frame];
    [titleLabel setNumberOfLines:0];
    [titleLabel setText:titleString];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setUserInteractionEnabled:NO];
    return titleLabel;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void) viewDidLoad {
    [super viewDidLoad];
}

- (void) viewDidUnload {
    [self setImageView:nil];
    [self setScrollView:nil];
    [self setTapGestureRecognizer:nil];
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self configureView];
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

#pragma Tap Gesture Recognizer

- (IBAction) handleTapGetsure:(UITapGestureRecognizer *)gestureRecognizer {
    if ([self scrollView]) {
        [[self scrollView] setHidden:![[self scrollView] isHidden]];
    }
}

@end
