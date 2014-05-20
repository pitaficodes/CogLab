//
//  SAProfileViewController.h
//

#import "SABaseViewController.h"
#import "SAFindPlayersViewController.h"
#import "SAUserInfo.h"
#import "SAMessageDetailsViewController.h"
#import "SAAPIManager.h"

@interface SAProfileViewController : SABaseViewController <UINavigationControllerDelegate, APIManagerDelegate>

@property (strong, nonatomic) SAUserInfo *userProfileData;
@property (nonatomic) BOOL isFromNotification;

@end
