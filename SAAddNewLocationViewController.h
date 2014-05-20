//
//  SAAddNewLocationViewController.h
//
//  Copyright (c) 2014. All rights reserved.
//

#import "SABaseViewController.h"
#import "SALocation.h"

@class SAAddNewLocationViewController;

@protocol SAAddNewLocationViewDelegate <NSObject>

@required

- (void)userAddedNewLocation:(SALocation *)newLocation;

@end

@interface SAAddNewLocationViewController : SABaseViewController<SABaseViewControllerDelegate>

@property (nonatomic, assign) id<SAAddNewLocationViewDelegate> delegate;

@end
