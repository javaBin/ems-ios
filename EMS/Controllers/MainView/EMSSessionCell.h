//
//  EMSSessionCell.h
//

#import <UIKit/UIKit.h>

#import "Session.h"

@interface EMSSessionCell : UITableViewCell

+ (NSArray *) colorsForLevel:(NSString *) level;

@property(nonatomic, strong) Session *session;

@end
