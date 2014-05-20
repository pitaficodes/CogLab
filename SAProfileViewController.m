//
//  SAProfileViewController.m
//
//

#import "SAProfileViewController.h"
#import "SALineChartView.h"
#import "SAPostGameViewController.h"
#import "SACompleteStatsViewController.h"
#import "SAUserFriendsViewController.h"
#import "SAUserGamesViewController.h"

#define SHARINGVIEW_HIEGHT 95

@interface SAProfileViewController ()<SALineChartDelegate>
{
    NSMutableArray *userGraphRating;
    NSUInteger currentGraphViewIndex;
    NSArray *userGraphRatingData;
}

@property (weak, nonatomic) IBOutlet UIImageView *imgPlayerProfile;
@property (weak, nonatomic) IBOutlet UILabel *lblPlayerName;
@property (weak, nonatomic) IBOutlet UILabel *lblPlayerAddress;
@property (weak, nonatomic) IBOutlet UILabel *lblPlayerUserName;
@property (weak, nonatomic) IBOutlet UIButton *btnPlayerFriendsCount;
@property (weak, nonatomic) IBOutlet UIButton *btnPlayerActiveGames;
@property (weak, nonatomic) IBOutlet UILabel *lblPlayerOverallSkillLevel;
@property (weak, nonatomic) IBOutlet UIButton *btnMessage;
@property (weak, nonatomic) IBOutlet UIButton *btnLeftMenu;
@property (weak,nonatomic) SAFindPlayersViewController *findPlayersController;
@property (weak, nonatomic) IBOutlet SALineChartView *lineChartView;
@property (weak, nonatomic) IBOutlet UILabel *lblAvgSkillLevel;
@property (weak, nonatomic) IBOutlet UIImageView *imgGame;
@property (weak, nonatomic) IBOutlet UIView *viewSharing;
@property (weak, nonatomic) IBOutlet UIButton *btnSharing;
@property (weak, nonatomic) IBOutlet UIButton *btnFriendRequestState;
@property (weak, nonatomic) IBOutlet UILabel *lblNoRatingFound;

@end

@implementation SAProfileViewController

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

    self.navigationController.navigationBarHidden = YES;
        
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [self showBackgroundImage];
    
    self.lineChartView.delegate = self;
    
    userGraphRating = [[NSMutableArray alloc] init];
    userGraphRatingData = [[NSArray alloc] init];

    [self showNoGraphRatingLabel:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [self populateUserProfileData];    
    
    [self getMyGraphRatings];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)populateUserProfileData
{
    [self.btnLeftMenu setImage:self.navigationController.viewControllers.count > 1 ? NavBarBackImageWhite:NavBarMenuWhiteImage forState:UIControlStateNormal];
    self.btnMessage.hidden = self.navigationController.viewControllers.count == 1;
    
    [self.viewSharing setFrame:CGRectMake(self.viewSharing.frame.origin.x, self.viewSharing.frame.origin.y, self.viewSharing.frame.size.width, 0)];
    
    if (self.btnMessage.hidden) // means its my profile
    {
        self.userProfileData = [SAUserInfo getUserInfo];
    }

    self.btnMessage.hidden = self.userProfileData.userId == [SAUserInfo getUserInfo].userId;// means its my profile
    [self.btnSharing setHidden:!self.btnMessage.hidden];
    [self.btnFriendRequestState setHidden:self.btnMessage.hidden];
    
    [self updateFriendRequestStatusImage];
    
    [self.imgPlayerProfile setImageWithURL:self.userProfileData.userProfileImageURL placeholderImage:kUserImagePlaceHolder];
    [Utilities setCircularView:self.imgPlayerProfile withBorderWidth:1.5f andBorderColor:WhiteColor];
    self.lblPlayerName.text = self.userProfileData.userFullNameUpperCase;
    self.lblPlayerUserName.text = self.userProfileData.userNameForDisplay;
    self.lblPlayerAddress.text = self.userProfileData.userLocation.locationCityName;
    [self.btnPlayerActiveGames setTitle:[NSString stringWithFormat:@"%d", self.userProfileData.userTotalActiveGames] forState:UIControlStateNormal];
    self.btnPlayerActiveGames.enabled = self.userProfileData.userTotalActiveGames > 0;
    [self.btnPlayerFriendsCount setTitle:[NSString stringWithFormat:@"%d", self.userProfileData.userTotalFriends] forState:UIControlStateNormal];
    self.btnPlayerFriendsCount.enabled = self.userProfileData.userTotalFriends;
}

- (void)updateFriendRequestStatusImage
{
    if (self.isFromNotification)
    {
        if (self.userProfileData.userIsFriend && self.userProfileData.userFriendStatus == 0)
        {
            [self.btnFriendRequestState setImage:kFriendAddFriendImage forState:UIControlStateNormal];
        }
        else
        {
            [self.btnFriendRequestState setImage:[UIImage imageNamed:@"requestConfirmed.png"] forState:UIControlStateNormal];
        }
    }
    else
    {
        [self.btnFriendRequestState setImage:self.userProfileData.userIsFriend?kFriendRequestStatusImage(self.userProfileData.userFriendStatus):kFriendAddFriendImage forState:UIControlStateNormal];
    }
}


#pragma mark - Line Graph View

- (void)createGraphView
{
    self.lblAvgSkillLevel.text = [NSString stringWithFormat:@"Avg Skill Level: %@", [[userGraphRatingData objectAtIndex:currentGraphViewIndex] objectForKeyNotNull:@"avgRating"]];
    self.imgGame.image = [SASportsList imageForSportTypeID:[[userGraphRatingData objectAtIndex:currentGraphViewIndex] objectForKeyNotNull:@"typeId"]];
    
    self.lineChartView.data = userGraphRating[currentGraphViewIndex];
}

- (void)showGameDetailsForGameId:(NSUInteger)gameId
{
    [self getMyGameInfo:gameId];
}

- (void)nextGameDataRequired
{
    if (userGraphRating.count > 0)
    {
        currentGraphViewIndex += 1;
        
        if (currentGraphViewIndex > (userGraphRating.count-1))
        {
            currentGraphViewIndex = 0;
        }
        
        [self createGraphView];
    }
}

- (void)previousGameDataRequired
{
    if (userGraphRating.count > 0)
    {
        currentGraphViewIndex = currentGraphViewIndex == 0 ? userGraphRating.count-1:currentGraphViewIndex-1;
        
        [self createGraphView];
    }
}


#pragma mark - Buttons Action

- (IBAction)btnFriendRequestStateClicked:(id)sender
{
    if (self.isFromNotification)
    {
        if (self.userProfileData.userIsFriend && self.userProfileData.userFriendStatus == 0)
        {
            [self.btnFriendRequestState setImage:[UIImage imageNamed:@"requestConfirmed.png"] forState:UIControlStateNormal];
            
            [self updateFriendRequestWithPlayerID:self.userProfileData.userId status:YES];
        }
    }
    else
    {
        if (!self.userProfileData.userIsFriend)
        {
            [self sendFriendRequestToPlayerWithID:self.userProfileData.userId];
        }
    }
}

- (IBAction)btnSharingClicked:(id)sender
{
    [UIView animateWithDuration:0.5f delay:0.0 usingSpringWithDamping:0.6f initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^
    {
        [self.viewSharing setFrame:CGRectMake(self.viewSharing.frame.origin.x, self.viewSharing.frame.origin.y, self.viewSharing.frame.size.width, self.viewSharing.frame.size.height > 0 ? 0:SHARINGVIEW_HIEGHT)];
    } completion:nil];
}

- (IBAction)btnMenuClicked:(id)sender
{
    [self backButtonClicked:sender];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (IBAction)btnCompleteStatsClicked:(id)sender
{
    [self getPlayerCompleteStats:self.userProfileData.userId];
}

- (IBAction)btnShareViaFacebookClicked:(id)sender
{
    [[SASocialSharingManager sharedInstance] sharePostOnFacebook:kSharingMsgProfileFb(self.userProfileData.userName) image:nil url:kSportanWebURL fromViewController:self];
}

- (IBAction)btnShareViaTwitterClicked:(id)sender
{
    [[SASocialSharingManager sharedInstance] sharePostOnTwitter:kSharingMsgProfileTw(self.userProfileData.userName) image:nil url:kSportanWebURL fromViewController:self];
}

- (IBAction)btnShareViaGPlusClicked:(id)sender
{
    [[SASocialSharingManager sharedInstance] sharePostOnGooglePlus:kSharingMsgProfileFb(self.userProfileData.userName) image:nil url:kSportanWebURL];
}

- (IBAction)btnMessageClicked:(id)sender
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    SAMessageDetailsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SAMessageDetailsViewController"];
    controller.showNavigationBarOnPop = NO;
    controller.messageSendToId = self.userProfileData.userId;
    controller.thread = [Utilities threadForUserID:self.userProfileData.userId];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)btnFriendsClicked:(id)sender
{
    if (self.userProfileData.userId == [SAUserInfo getUserInfo].userId) // if my profile then show my Friends view
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kShowMyFriendsNotification object:nil];
    }
    else
    {
        if (self.userProfileData.userTotalFriends > 0 && (self.userProfileData.userProfileVisibility==0 || (self.userProfileData.userProfileVisibility==1 && self.userProfileData.userIsFriend)))
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
            
            if (self.userProfileData.userId != [SAUserInfo getUserInfo].userId)
            {
                SAUserFriendsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SAUserFriendsViewController"];
                controller.userID = self.userProfileData.userId;
                controller.showNavigationBarOnPop = NO;
                
                [self.navigationController pushViewController:controller animated:YES];
            }
        }
    }
}

- (IBAction)btnActiveGamesClicked:(id)sender
{
    if (self.userProfileData.userTotalActiveGames > 0 && (self.userProfileData.userProfileVisibility==0 || (self.userProfileData.userProfileVisibility==1 && self.userProfileData.userIsFriend)))
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
        
        if (self.userProfileData.userId == [SAUserInfo getUserInfo].userId) // if my profile then show my Games view
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowMyGamesNotification object:nil];
        }
        else
        {
            SAUserGamesViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SAUserGamesViewController"];
            controller.userID = self.userProfileData.userId;
            controller.showNavigationBarOnPop = NO;
            
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
}

#pragma mark - API Delegates

- (void)sendFriendRequestToPlayerWithID:(int)playerId
{
    [SVProgressHUD show];
    
    SAAPIManager *apiManager = [[SAAPIManager alloc] init];
    apiManager.delegate = self;
    [apiManager sendFriendRequest:@{@"reqType":@"sendfriendrequest", @"accessToken":[Utilities getUserAccessToken], @"friendId":[NSNumber numberWithInt:playerId]}];
}

- (void)updateFriendRequestWithPlayerID:(int)playerId status:(BOOL)accept
{
    [SVProgressHUD show];
    
    SAAPIManager *apiManager = [[SAAPIManager alloc] init];
    apiManager.delegate = self;
    [apiManager updateFriendRequest:@{@"reqType":@"updatefriendrequest", @"accessToken":[Utilities getUserAccessToken], @"senderId":[NSNumber numberWithInt:playerId], @"status":[NSNumber numberWithBool:accept]}];
}

- (void)didSendFriendRequest:(SAAPIManager *)manager
{
    [SVProgressHUD showSuccessWithStatus:@"Friend request sent"];
    
    self.userProfileData.userIsFriend = 1;
    self.userProfileData.userFriendStatus = 0;
    
    [self updateFriendRequestStatusImage];
}

- (void)didFailToSendFriendRequest:(SAAPIManager *)manager error:(Error *)error
{
    [SVProgressHUD showErrorWithStatus:error.message];
}

- (void)didUpdateFriendRequest:(SAAPIManager *)manager
{
    [SVProgressHUD dismiss];
    
    self.userProfileData.userIsFriend = 1;
    self.userProfileData.userFriendStatus = 1;
    
    [self updateFriendRequestStatusImage];
}

- (void)didFailToUpdateFriendRequest:(SAAPIManager *)manager error:(Error *)error
{
    [SVProgressHUD showErrorWithStatus:error.message];
}

- (void)getPlayerCompleteStats:(int)playerID
{
    [SVProgressHUD show];
    
    SAAPIManager *apiManager = [[SAAPIManager alloc] init];
    apiManager.delegate = self;
    [apiManager getPlayerCompleteStatistics:@{@"reqType":@"playercompletestats", @"accessToken":[Utilities getUserAccessToken], @"playerId":[NSNumber numberWithInt:playerID]}];
}

- (void)didGetPlayerCompleteStatistics:(SAAPIManager *)manager
{
    [SVProgressHUD dismiss];
    
    if (manager.data)
    {
        SACompleteStatsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SACompleteStatsViewController"];
        controller.userProfileData = self.userProfileData;
        controller.userCompleteStats = manager.data;
        
        [self.navigationController pushViewController:controller animated:YES];
    }
    else
    {
        [SVProgressHUD showErrorWithStatus:kMsgNoGamePlayed];
    }
}

- (void)didFailToGetPlayerCompleteStatistics:(SAAPIManager *)manager error:(Error *)error
{
    [SVProgressHUD showErrorWithStatus:kMsgNoGamePlayed];
}

- (void)getMyGraphRatings
{
    SAAPIManager *apiManager = [[SAAPIManager alloc] init];
    apiManager.delegate = self;
    
    [apiManager getPlayerStatsGraph:@{@"reqType":@"playergraphstats", @"accessToken":[Utilities getUserAccessToken], @"playerId":[NSNumber numberWithInt:self.userProfileData.userId]}];
}

- (void)didGetPlayerStatsGraph:(SAAPIManager *)manager
{
    [userGraphRating removeAllObjects];
    
    if (manager.data)
    {
        userGraphRatingData = manager.data;
        
        for (int i = 0; i < userGraphRatingData.count; i++)
        {
            UIImage *sportImage = [SASportsList imageForSportTypeID:[[userGraphRatingData objectAtIndex:i] objectForKey:@"typeId"]];
            
            NSArray *gamesArray = [[userGraphRatingData objectAtIndex:i] objectForKey:@"games"];
            
            NSMutableArray *lineChartItems = [[NSMutableArray alloc] init];
            
            for (int j = 0; j < gamesArray.count; j ++)
            {
                NSDictionary *lineItemDict = gamesArray[j];
                
                SALineChartItem *lineChartItem = [SALineChartItem lineChartItemWithTitle:[[lineItemDict objectForKeyNotNull:@"title"] uppercaseString] gameImage:sportImage rating:[[lineItemDict objectForKeyNotNull:@"avgRating"] intValue] gameId:[[lineItemDict objectForKeyNotNull:@"gameId"] intValue]];
                
                [lineChartItems addObject:lineChartItem];
            }
            
            [userGraphRating addObject:lineChartItems];
        }
    }
    
    [self showNoGraphRatingLabel:NO];
    
    [self createGraphView];
}

- (void)didFailToGetPlayerStatsGraph:(SAAPIManager *)manager error:(Error *)error
{
    [self showNoGraphRatingLabel:YES];
}

- (void)showNoGraphRatingLabel:(BOOL)show
{
    currentGraphViewIndex = 0;
    
    [self.lblNoRatingFound setHidden:!show];
    [self.lblAvgSkillLevel setHidden:show];
    [self.imgGame setHidden:show];
    
    if (show)
    {
        [userGraphRating removeAllObjects];
        userGraphRatingData = nil;
    }
}

- (void)showMyGameInfo:(SAGame *)myGame
{
    SAPostGameViewController *postGamesController =[self.storyboard instantiateViewControllerWithIdentifier:@"SAPostGameViewController"];
    postGamesController.showNavigationBarOnPop = NO;
    postGamesController.game = myGame;
    [self.navigationController pushViewController:postGamesController animated:YES];
}

- (void)getMyGameInfo:(NSUInteger)gameID
{
    [SVProgressHUD show];
    
    SAAPIManager *apiManager = [[SAAPIManager alloc] init];
    apiManager.delegate = self;
    [apiManager getGameInfo:@{@"reqType":@"getpregamedata", @"accessToken":[Utilities getUserAccessToken], @"gameId":[NSNumber numberWithInteger:gameID]}];
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



@end