//
//  EMSSessionCell.h
//

#import <UIKit/UIKit.h>

#import "Session.h"

@interface EMSSessionCell : UITableViewCell

@property(nonatomic, strong) IBOutlet UILabel *title;
@property(nonatomic, strong) IBOutlet UILabel *room;
@property(nonatomic, strong) IBOutlet UILabel *speaker;
@property(nonatomic, strong) IBOutlet UILabel *summary;
@property(nonatomic, strong) IBOutlet UILabel *keywords;
@property(nonatomic, strong) IBOutlet TintButton *icon;
@property(nonatomic, strong) IBOutlet UIImageView *level;
@property(nonatomic, strong) IBOutlet UIImageView *video;
@property(nonatomic, strong) Session *session;

@end
