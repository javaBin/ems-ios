//
//  EMSSessionCell.h
//

#import <UIKit/UIKit.h>

@class Session;

@interface EMSSessionCell : UITableViewCell

+ (NSArray *) colorsForLevel:(NSString *) level;

@property(nonatomic, strong) Session *session;

@end
