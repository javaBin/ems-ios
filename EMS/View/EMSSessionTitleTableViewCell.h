#import <UIKit/UIKit.h>

@interface EMSSessionTitleTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *timeAndRoomLabel;

@property (weak, nonatomic) IBOutlet TintButton *favoriteButton;

@end
