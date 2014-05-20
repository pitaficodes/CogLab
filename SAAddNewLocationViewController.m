//
//  SAAddNewLocationViewController.m
//
//  Copyright (c) 2014. All rights reserved.
//

#import "SAAddNewLocationViewController.h"
#import <MapKit/MapKit.h>
#import "SALocationCategoriesViewController.h"
#import "SALocationOnMapViewController.h"
#import "SAAPIManager.h"

@interface SAAddNewLocationViewController ()<MKMapViewDelegate, SALocationCategoryDelegate, SALocationOnMapViewDelegate, UITextFieldDelegate, APIManagerDelegate>


@property (weak, nonatomic) IBOutlet UITextField *txtName;
@property (weak, nonatomic) IBOutlet UIButton *btnCategory;
@property (weak, nonatomic) IBOutlet UITextField *txtAddress;
@property (weak, nonatomic) IBOutlet MKMapView *mkMapView;

@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

@property (nonatomic) CLLocationCoordinate2D locationCoordinatesNew;
@property (strong, nonatomic) SALocationCategory *locationCategoryNew;

@end

@implementation SAAddNewLocationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.txtAddress setValue:kGameTitlePlaceholderColor forKeyPath:kKeyPath_For_Placeholder_Color];
    [self.txtName setValue:kGameTitlePlaceholderColor forKeyPath:kKeyPath_For_Placeholder_Color];
    [self setupNavigationBarTitle:@"ADD NEW LOCATION" showRightButton:YES rightButtonType:UINavigationBarRightButtonTypeDone topBarImage:NO showBackGround:YES];
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapViewTappedByUser:)];
    self.tapGesture.numberOfTapsRequired = 1;
    self.tapGesture.numberOfTouchesRequired = 1;
    
    [self.mkMapView addGestureRecognizer:self.tapGesture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.baseDelegate = self;
    [self refreshMapView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark - Story Board Delegate Method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[SABaseViewController class]])
    {
        [(SABaseViewController *)segue.destinationViewController setShowNavigationBarOnPop:YES];
    }
    
    if ([segue.identifier isEqualToString:@"addLocationToCategories"])
    {
        SALocationCategoriesViewController *controller = (SALocationCategoriesViewController *)segue.destinationViewController;
        controller.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"addLocationToMap"])
    {
        SALocationOnMapViewController *controller = (SALocationOnMapViewController *)segue.destinationViewController;
        controller.delegate = self;
    }
}

- (void)userSelectedLocation:(CLLocationCoordinate2D)coordinates
{
    NSLog(@"Selected Lat: %f, Long: %f", coordinates.latitude, coordinates.longitude);
    self.locationCoordinatesNew = coordinates;
}

- (void)userSelectedNewCategory:(SALocationCategory *)newCategory
{
    NSLog(@"Selected Category: %@", newCategory);
    self.locationCategoryNew = newCategory;
    [self.btnCategory setTitle:newCategory.categoryName forState:UIControlStateNormal];
}


#pragma mark - Base Delegate Method

- (void)rightNavigationBarButtonClicked
{
    if (self.txtName.text.length < 5)
    {
        [Utilities showAlertView:MSG_ALERT message:@"Name should not be empty or less than 5 characters" delegate:nil];
    }
    else if (self.locationCategoryNew == nil)
    {
        [Utilities showAlertView:MSG_ALERT message:@"Select category first" delegate:nil];
    }
    else if (self.locationCoordinatesNew.latitude == 0)
    {
        [Utilities showAlertView:MSG_ALERT message:@"Your current location not found. Please try later" delegate:nil];
    }
    else
    {
        [self addNewLocationToFourSquare];
    }
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.txtAddress)
    {
        [self.view endEditing:YES];
    }
    
    return YES;
}

#pragma mark - Buttons Action

- (IBAction)btnCategoryClicked:(id)sender
{
    [self performSegueWithIdentifier:@"addLocationToCategories" sender:self];    
}


#pragma mark - MKMapView Methods

- (void) mapViewTappedByUser:(UITapGestureRecognizer *)gesture
{
    [self performSegueWithIdentifier:@"addLocationToMap" sender:self];
}

-(void)refreshMapView
{
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.mkMapView.userLocation.coordinate, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    MKCoordinateRegion adjustedRegion = [self.mkMapView regionThatFits:viewRegion];
    
    [self.mkMapView setRegion:adjustedRegion animated:YES];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [self refreshMapView];
}


#pragma mark - API Methods

- (void)addNewLocationToFourSquare
{
    [SVProgressHUD show];
    
    SAAPIManager *apiManager = [[SAAPIManager alloc] init];
    apiManager.delegate = self;
    
    [apiManager addNewUserLocation:@{@"reqType":@"addlocation",
                                     @"oauth_token":[[SAFourSquareManager sharedManager] accessToken]/*@"3LFME22KMIHA3ADWZ0QSIO3INK11SVXNX0JEL3FS3M3RGUC1"*/,
                                     @"name":self.txtName.text,
                                     @"latitude":[NSNumber numberWithFloat:self.locationCoordinatesNew.latitude],
                                     @"longitude":[NSNumber numberWithFloat:self.locationCoordinatesNew.longitude],
                                     @"primaryCategoryId":self.locationCategoryNew.categoryID,
                                     @"address":self.txtAddress.text}];
}

- (void)didAddLocation:(SAAPIManager *)manager
{
    [SVProgressHUD dismiss];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(userAddedNewLocation:)])
    {
        SALocation *location = [[SALocation alloc] initWithDict:manager.data];
        
        [self.delegate userAddedNewLocation:location];
    }
    
    [super goBackToIndex:2];
}

- (void)didFailToAddLocation:(SAAPIManager *)manager error:(Error *)error
{
    [SVProgressHUD dismiss];
    
    [Utilities showAlertView:MSG_ALERT message:error.message delegate:nil];
}

@end
