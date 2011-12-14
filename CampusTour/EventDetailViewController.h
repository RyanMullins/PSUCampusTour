//
//  DetailViewController.h
//  CampusTour
//
//  Created by Ryan Mullins on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventDetailViewController : UIViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UIImageView * imageView;
@property (weak, nonatomic) IBOutlet UIScrollView * scrollView;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGestureRecognizer;

- (IBAction) handleTapGetsure:(UITapGestureRecognizer *)gestureRecognizer;

@end
