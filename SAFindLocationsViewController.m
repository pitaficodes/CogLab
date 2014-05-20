//
//  SAFindLocationsViewController.m
//
//  Copyright (c) 2014. All rights reserved.
//

#import "SAFindLocationsViewController.h"
#import "SALocationCell.h"
#import "SAAddNewLocationViewController.h"
#import "SAAPIManager.h"

@interface SAFindLocationsViewController ()<APIManagerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MKMapViewDelegate, SABaseViewControllerDelegate, SAAddNewLocationViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *searchbar;
@property (weak, nonatomic) IBOutlet UITableView *tblLocations;
@property (weak, nonatomic) IBOutlet MKMapView *mkLocations;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;

@property (nonatomic, assign) BOOL shouldBeginEditing;
@end

@implementation SAFindLocationsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupNavigationBarTitle:@"FIND LOCATIONS" showRightButton:YES rightButtonType:UINavigationBarRightButtonTypeAddNew topBarImage:nil showBackGround:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fourSqaureAuthCompleted) name:kFoursquareAuthCompeletionNotification object:nil];

    self.shouldBeginEditing = YES;
    self.activityView.hidden = YES;
    
    [self.searchbar setValue:WhiteColor forKeyPath:kKeyPath_For_Placeholder_Color];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.baseDelegate = self;
}

- (void)dealloc
{
    self.mkLocations.delegate = nil;
    self.mkLocations = nil;
    [self.mkLocations removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFoursquareAuthCompeletionNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Story Board Delegate Method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[SABaseViewController class]])
    {
        [(SABaseViewController *)segue.destinationViewController setShowNavigationBarOnPop:YES];
    }
    if ([segue.identifier isEqualToString:@"locationToAddLocation"])
    {
        SAAddNewLocationViewController *controller = (SAAddNewLocationViewController *)segue.destinationViewController;
        controller.delegate = self;
    }
}

- (void)userAddedNewLocation:(SALocation *)newLocation
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(newLocationSelected:)])
    {
        [self.delegate newLocationSelected:newLocation];
    }
}

- (void)goBackWithNewLocation:(SALocation *)newLocation
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(newLocationSelected:)])
    {
        [self.delegate newLocationSelected:newLocation];
    }
    [super backButtonClicked:nil];
}

#pragma mark - FourSquare Notifcation

- (void)fourSqaureAuthCompleted
{
    if ([[SAFourSquareManager sharedManager] errorDescription])
    {
        [Utilities showAlertView:MSG_ALERT message:[SAFourSquareManager sharedManager].errorDescription delegate:nil];
    }
    else if ([[SAFourSquareManager sharedManager] accessToken])
    {
        NSLog(@"Token: %@", [[SAFourSquareManager sharedManager] accessToken]);
        [self performSegueWithIdentifier:@"locationToAddLocation" sender:self];
    }
}

#pragma mark - Base Delegate Method

- (void)rightNavigationBarButtonClicked
{
    [[SAFourSquareManager sharedManager] authenticateFourSquareUser];
//    [self performSegueWithIdentifier:@"locationToAddLocation" sender:self];
}

#pragma mark - UITextField Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.searchbar resignFirstResponder];
    
    [self getNearByLocations:self.mkLocations.userLocation.location searchString:self.searchbar.text];
    
    return YES;
}

#pragma mark - UITableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.locationsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SALocationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"locationCell"];
    
    SALocation *location = [self.locationsArray objectAtIndex:indexPath.row];
    
    cell.lblLocationAddress.text = location.locationAddressWithDistance;
    cell.lblLocationTitle.text = location.locationTitleUpperCase;
    [cell.imgLocationThumbnail setImageWithURL:location.locationImageURL placeholderImage:kLocationImagePlaceHolder];
    
    if (cell.imgLocationThumbnail.layer.cornerRadius < 1)
    {
        cell.imgLocationThumbnail.layer.cornerRadius = cell.imgLocationThumbnail.frame.size.height/2;
        cell.imgLocationThumbnail.layer.masksToBounds = YES;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self goBackWithNewLocation:[self.locationsArray objectAtIndex:indexPath.row]];
}

#pragma mark - MKMapView Methods

-(void)refreshMapView
{
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.mkLocations.userLocation.coordinate, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    MKCoordinateRegion adjustedRegion = [self.mkLocations regionThatFits:viewRegion];
    
    [self.mkLocations setRegion:adjustedRegion animated:YES];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [self refreshMapView];
}

#pragma mark - API Handling Methods

// Get Locations Based on user current location
- (void)getNearByLocations:(CLLocation *)currentLocation searchString:(NSString *)searchString
{
    [self hideLocationActivityView:NO];
    
    SAAPIManager *apiManager = [[SAAPIManager alloc] init];
    apiManager.delegate = self;
    [apiManager nearByLocations:@{@"reqType":@"getlocations",
                                  @"latitude":[NSNumber numberWithFloat:currentLocation.coordinate.latitude],
                                  @"longitude":[NSNumber numberWithFloat:currentLocation.coordinate.longitude],
                                  @"search":searchString
                                  }];
}

- (void)didGetNearByLocations:(SAAPIManager *)manager
{
    self.locationsArray = [SALocation locationsFromLocationsResponse:manager.data];
    [self.tblLocations reloadData];
    [self hideLocationActivityView:YES];
}

- (void)didFailToGetNearByLocations:(SAAPIManager *)manager error:(Error *)error
{
    [self hideLocationActivityView:YES];
}

- (void)hideLocationActivityView:(BOOL)hide
{
    self.activityView.hidden = hide;
    hide ? [self.activityView stopAnimating] : [self.activityView startAnimating];    
}

@end
