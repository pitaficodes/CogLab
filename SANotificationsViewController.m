//
//  SANotificationsViewController.m
//
//

#import "SANotificationsViewController.h"
#import "SANotificationsCell.h"
#import "SAApiManager.h"
#import "NSDate+TimeAgo.h"

@interface SANotificationsViewController () <SABaseViewControllerDelegate,UITableViewDataSource,UITableViewDelegate, APIManagerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tblNotifications;

@property (strong, nonatomic) NSMutableArray *notificationsList;

@end

@implementation SANotificationsViewController

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

    self.notificationsList = [[NSMutableArray alloc] init];
    
	[self setupNavigationBarTitle:@"NOTIFICATIONS" showRightButton:YES rightButtonType:UINavigationBarRightButtonTypeSetting topBarImage:nil showBackGround:NO];
    
    MONotification *savedNotification = [[MONotification fetchWithPredicate:nil sortDescriptor:nil fetchLimit:1] lastObject];
    
    if (savedNotification)
    {
        if ([savedNotification.notificationCreatedBy intValue] != [SAUserInfo getUserInfo].userId)
        {
            [MONotification deleteAllObjects];
        }
    }
    
    [self reloadNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteNotificationReceived) name:kRemoteNotificationReceived object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.baseDelegate = self;
    
    [self hideNavigationBar:NO];
    
    [self getMyNotificationsList];
    
    [Utilities removeApplicationBagdeIcon];
}

- (void)remoteNotificationReceived
{
    [self getMyNotificationsList];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRemoteNotificationReceived object:nil];
}

#pragma mark - BaseDelegate Method

-(void)rightNavigationBarButtonClicked
{
    SANotificationSettingsViewController *notificationSettings = [self.storyboard instantiateViewControllerWithIdentifier:@"SANotificationSettingsViewController"];
    notificationSettings.showNavigationBarOnPop = YES;
    
    [self.navigationController pushViewController:notificationSettings animated:YES];
}

#pragma mark - TableView Delegates and DataSource


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notificationsList.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SANotificationsCell *cell = (SANotificationsCell *)[self.tblNotifications dequeueReusableCellWithIdentifier:@"NotificationsCell"];
    
    MONotification *notification = [self.notificationsList objectAtIndex:indexPath.row];
    
    if (notification.notificationImage.length > 10)
    {
        [cell.imgGamePerson setImageWithURL:[NSURL URLWithString:notification.notificationImage] placeholderImage:kUserImagePlaceHolder];
    }
    else
    {
        cell.imgGamePerson.image = [SASportsList imageForSportTypeID:notification.notificationImage];
    }
    
    cell.lblTitle.text = [notification.notificationTitle uppercaseString];
    cell.lblDescription.text = notification.notificationDescription;
    cell.lblDate.text = [[NSDate dateWithTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT] sinceDate:notification.notificationCreatedOn] timeAgo];
    
    if (cell.imgGamePerson.layer.cornerRadius < 1)
    {
        cell.imgGamePerson.layer.cornerRadius = 30.0f;
        cell.imgGamePerson.layer.masksToBounds = YES;
        cell.imgGamePerson.contentMode = UIViewContentModeScaleToFill;
    }

//    [cell setSelected:YES];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MONotification *notification = self.notificationsList[indexPath.row];
    
    switch ([notification.notificationType intValue])
    {
        case kNotificationTypeFRIEND_REQUEST:
            [self getUserProfileDetails:notification.notificationRefferenceId];
            break;
        case kNotificationTypeGAME_INVITE:
            [self getGameDetailsByGameId:notification.notificationRefferenceId];
            break;
        case kNotificationTypeNEW_FRIEND:
            [self getUserProfileDetails:notification.notificationRefferenceId];
            break;
        default:
            [Utilities showAlertView:MSG_ALERT message:@"NotificationType is not registered for this notification" delegate:nil];
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - API Delegate Method

- (void)reloadNotifications
{
    NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"notificationId" ascending:NO];
    
    self.notificationsList = [[MONotification fetchWithPredicate:nil sortDescriptor:@[sortDesc] fetchLimit:0] mutableCopy];

    [self.tblNotifications reloadData];
}

- (NSString *)lastNotificationTimeStamp
{
    NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"notificationId" ascending:NO];

    MONotification *notification = [[MONotification fetchWithPredicate:nil sortDescriptor:@[sortDesc] fetchLimit:1] lastObject];
    
    if (notification)
    {
        return [Utilities timeStampStringFromDate:notification.notificationCreatedOn];
    }
    
    return @"0000-00-00 00:00:00";
}

- (void)getMyNotificationsList
{
    SAAPIManager *apiManager = [[SAAPIManager alloc] init];
    apiManager.delegate = self;
    
    [apiManager getMyNotifications:@{@"reqType":@"getnotifications", @"accessToken":[Utilities getUserAccessToken], @"timestamp":[self lastNotificationTimeStamp]}];
}

- (void)didGetMyNotifications:(SAAPIManager *)manager
{
    NSArray *notifications = manager.data;

    if (notifications.count > 0)
    {
        for (NSDictionary *dict in notifications)
        {
            MONotification *notification = [[MONotification fetchWithPredicate:[NSPredicate predicateWithFormat:@"notificationId = %d", [[dict objectForKeyNotNull:@"id"] intValue]] sortDescriptor:nil fetchLimit:1] lastObject];
            
            if (!notification)
            {
                notification = (MONotification *)[MONotification create];
                
                notification.notificationId = [NSNumber numberWithInt:[[dict objectForKeyNotNull:@"id"] intValue]];
            }
            
            notification.notificationCreatedBy = [NSNumber numberWithInt:[[dict objectForKeyNotNull:@"createdFor"] intValue]];
            notification.notificationType = [NSNumber numberWithInt:[[dict objectForKeyNotNull:@"type"] intValue]];
            notification.notificationCreatedOn = [Utilities timeStampDateFromString:[dict objectForKeyNotNull:@"createdOn"]];
            notification.notificationDescription = [dict objectForKeyNotNull:@"description"];
            notification.notificationImage = [dict objectForKeyNotNull:@"imageURL"];
            notification.notificationRefferenceId = [NSNumber numberWithInt:[[dict objectForKeyNotNull:@"refferenceId"] intValue]];
            notification.notificationTitle = [dict objectForKeyNotNull:@"title"];
        }
        
        [MONotificationSetting save];
        
        [self reloadNotifications];
    }
}

- (void)didFailToGetMyNotifications:(SAAPIManager *)manager error:(Error *)error
{
}


#pragma mark - Notification Click Actions

- (void)getUserProfileDetails:(NSNumber *)userId
{
    SAAPIManager *apiManager = [[SAAPIManager alloc] init];
    apiManager.delegate = self;
    
    [apiManager getPlayerProfile:@{@"reqType":@"getplayerdetails", @"accessToken":[Utilities getUserAccessToken], @"playerId": userId}];
    
    [SVProgressHUD show];
}

- (void)didGetPlayerProfile:(SAAPIManager *)manager
{
    [SVProgressHUD dismiss];
    
    SAProfileViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SAProfileViewController"];
    controller.showNavigationBarOnPop = YES;
    controller.isFromNotification = YES;
    controller.userProfileData = [[SAUserInfo alloc] initWithDict:manager.data];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)didFailToGetPlayerProfile:(SAAPIManager *)manager error:(Error *)error
{
    [SVProgressHUD showErrorWithStatus:error.message];
}

- (void)getGameDetailsByGameId:(NSNumber *)gameId
{
    [SVProgressHUD show];
    
    SAAPIManager *apiManager = [[SAAPIManager alloc] init];
    apiManager.delegate = self;
    [apiManager getGameInfo:@{@"reqType":@"getpregamedata", @"accessToken":[Utilities getUserAccessToken], @"gameId":gameId}];
}

- (void)didGetGameInfo:(SAAPIManager *)manager
{
    [SVProgressHUD dismiss];
    
    SAGame *myGame = [[SAGame alloc] initWithGameDict:manager.data];
    
    [self showMyGameInfo:myGame];
}

- (void)didFailToGetGameInfo:(SAAPIManager *)manager error:(Error *)error
{
    [SVProgressHUD dismiss];
    
    [SVProgressHUD showErrorWithStatus:error.message];
}

- (void)showMyGameInfo:(SAGame *)myGame
{
    if([myGame.gameStaringDateTime compare:[Utilities threeHoursBackDate]] == NSOrderedDescending)
    {
        SAPreGameViewController *preGamesController =[self.storyboard instantiateViewControllerWithIdentifier:@"SAPreGameViewController"];
        preGamesController.showNavigationBarOnPop = YES;
        preGamesController.game = myGame;
        [self.navigationController pushViewController:preGamesController animated:YES];
    }
    else
    {
        SAPostGameViewController *postGamesController =[self.storyboard instantiateViewControllerWithIdentifier:@"SAPostGameViewController"];
        postGamesController.showNavigationBarOnPop = YES;
        postGamesController.game = myGame;
        [self.navigationController pushViewController:postGamesController animated:YES];
    }
}


@end
