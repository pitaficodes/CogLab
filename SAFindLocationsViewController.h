//
//  SAFindLocationsViewController.h
//
//  Copyright (c) 2014. All rights reserved.
//

#import "SABaseViewController.h"
#import <MapKit/MapKit.h>
#import "SALocation.h"
#import "SAFourSquareManager.h"

@class SAFindLocationsViewController;

@protocol SAFindLocationsDelegate <NSObject>

@required

- (void)newLocationSelected:(SALocation *)location;

@end

@interface SAFindLocationsViewController : SABaseViewController

@property (nonatomic, assign) id<SAFindLocationsDelegate> delegate;

@property (nonatomic, strong) NSArray *locationsArray;

@end
