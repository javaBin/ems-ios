#import <UIKit/UIKit.h>

@class TintButton;

@interface EMSSessionTitleTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *timeAndRoomLabel;

@property (weak, nonatomic) IBOutlet TintButton *favoriteButton;

@end
