//
//  SAUserGamesViewController.m
//
//  Copyright (c) 2014. All rights reserved.
//

#import "SAUserGamesViewController.h"
#import "SAGameCell.h"
#import "SASportsList.h"
#import "SAAPIManager.h"

#define VISIBLE_CELLS IS_IPHONE5 ? 4:3

@interface SAUserGamesViewController ()<APIManagerDelegate, SABaseViewControllerDelegate>

@property (strong, nonatomic) NSArray *gamessArray;
@property (strong, nonatomic) NSMutableArray *filteredGamesArray;
@property (strong, nonatomic) NSMutableArray *animatedSkills;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentMyGameFilter;
@property (weak, nonatomic) IBOutlet UITableView *tblGames;

@end

@implementation SAUserGamesViewController

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
    
    self.animatedSkills = [NSMutableArray new];
    self.filteredGamesArray = [NSMutableArray new];
    
    [self setupNavigationBarTitle:@"GAMES LIST" showRightButton:NO rightButtonType:UINavigationBarRightButtonTypeDefault topBarImage:NO showBackGround:NO];

    [Utilities setupSegmentControlUI:self.segmentMyGameFilter];
    
    [self.segmentMyGameFilter addTarget:self action:@selector(getGamesBySelectSegment:) forControlEvents:UIControlEventValueChanged];    
    
    [self getUserGames:self.userID];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableView Delegates & Data Source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredGamesArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SAGameCell *cell = (SAGameCell *)[tableView dequeueReusableCellWithIdentifier:@"gameCell"];
    
    SAGame *myGame = [self.filteredGamesArray objectAtIndex:indexPath.row];
    
    cell.lblAverageAge.text = [NSString stringWithFormat:@"%d", myGame.gameAvgPlayerAge];
    cell.lblGameTitle.text = myGame.gameTitleUpperCase;
    cell.imgGameGender.image = [Utilities gameGenderImageByGenderID:myGame.gameGender];
    cell.imgGameIcon.image = [SASportsList imageForSportTypeID:[NSString stringWithFormat:@"%d", myGame.gameTypeId]];
    cell.lblGameSkill.text = [NSString stringWithFormat:@"%d", myGame.gameAvgSkillLevel];
    cell.lblGameOwner.text = myGame.gameOwnerUserNameForDisplay;
    cell.lblGameLeft.text = [NSString stringWithFormat:@"%d", myGame.gameSpotsLeft];
    cell.lblGameLeft.textColor = myGame.gameSpotsLeft < 2 ? [UIColor redColor]:kPlaceholderColor;
    cell.lblGameDueDate.attributedText = [Utilities gameStartingDateAttributedString:myGame.gameStaringDateTime];
    cell.lblGameLoction.attributedText = [Utilities gameAddressAttributedString:myGame.gameLocation.locationLatitude longitude:myGame.gameLocation.locationLongitude address:myGame.gameLocation.locationAddress];
    cell.isSkillFreeGame = myGame.isSkillFreeGame;
    
    CGFloat nameLabelWidth = [Utilities getWidthOfLabel:cell.lblGameTitle].width;
    
    [cell.imgGameGender setFrame:CGRectMake(nameLabelWidth + 55, cell.imgGameGender.frame.origin.y, cell.imgGameGender.image.size.width, cell.imgGameGender.image.size.height)];
    [cell.imgGameGender sizeToFit];
    
    if (indexPath.row < VISIBLE_CELLS && ![self.animatedSkills containsObject:[NSNumber numberWithInteger:indexPath.row]])
    {
        [self.animatedSkills addObject:[NSNumber numberWithInteger:indexPath.row]];
        [cell showGameSkillBar:YES];
    }
    else
    {
        [cell showGameSkillBar:NO];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SAGame *myGame = [self.filteredGamesArray objectAtIndex:indexPath.row];
    
    [self getMyGameInfo:myGame.gameId];
}

- (void)scrollToTopAnimated:(BOOL)animated
{
    if (self.filteredGamesArray.count > 0)
    {
        [self.tblGames scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }
}

#pragma mark - Story Board Delegate Method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[SABaseViewController class]])
    {
        [(SABaseViewController *)segue.destinationViewController setShowNavigationBarOnPop:YES];
    }
}

#pragma mark - API Delegate Methods

- (void)getGamesBySelectSegment:(UISegmentedControl *)segmentControl
{
    NSInteger selectedSegmentIndex = segmentControl.selectedSegmentIndex;
    [self.filteredGamesArray removeAllObjects];
    
    switch (selectedSegmentIndex)
    {
        case 0:
            for (SAGame *game in self.gamessArray)
            {
                if ([game.gameStaringDateTime compare:[Utilities threeHoursBackDate]] == NSOrderedDescending)
                {
                    [self.filteredGamesArray addObject:game];
                }
            }
            break;
        case 1:
            for (SAGame *game in self.gamessArray)
            {
                if ([game.gameStaringDateTime compare:[Utilities threeHoursBackDate]] == NSOrderedAscending)
                {
                    [self.filteredGamesArray addObject:game];
                }
            }
            break;
        case 2:
            for (SAGame *game in self.gamessArray)
            {
                if (game.isOwner)
                {
                    [self.filteredGamesArray addObject:game];
                }
            }
            break;
        default:
            
            break;
    }
    
    self.filteredGamesArray = [[self.filteredGamesArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
    {
        SAGame *game1 = (SAGame *)obj1;
        SAGame *game2 = (SAGame *)obj2;
        
        if (selectedSegmentIndex == 0)
        {
            return [game1.gameStaringDateTime compare:game2.gameStaringDateTime] == NSOrderedDescending;
        }
        else
        {
            return [game1.gameStaringDateTime compare:game2.gameStaringDateTime] == NSOrderedAscending;
        }
    }] mutableCopy];
    
    [self.tblGames reloadData];
    
    [self scrollToTopAnimated:YES];
}

#pragma mark - API Delegate Methods

- (void)getUserGames:(int)userID
{
    SAAPIManager *apiManager = [[SAAPIManager alloc] init];
    apiManager.delegate = self;
    [apiManager getPlayerGamesListByID:@{@"reqType":@"getplayergames", @"accessToken":[Utilities getUserAccessToken], @"playerId":[NSNumber numberWithInt:self.userID]}];
}

- (void)didGetPlayerGamesListByID:(SAAPIManager *)manager
{
    self.gamessArray = [SAGame gamesArray:manager.data];
    
    [self getGamesBySelectSegment:self.segmentMyGameFilter];
}

- (void)didFailToGetPlayerGamesListByID:(SAAPIManager *)manager error:(Error *)error
{
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

- (void)getMyGameInfo:(int)gameID
{
    [SVProgressHUD show];
    
    SAAPIManager *apiManager = [[SAAPIManager alloc] init];
    apiManager.delegate = self;
    [apiManager getGameInfo:@{@"reqType":@"getpregamedata", @"accessToken":[Utilities getUserAccessToken], @"gameId":[NSNumber numberWithInt:gameID]}];
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
