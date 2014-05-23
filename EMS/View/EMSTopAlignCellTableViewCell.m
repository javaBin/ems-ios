//
//  EMS
//

#import "EMSTopAlignCellTableViewCell.h"

@implementation EMSTopAlignCellTableViewCell

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect frame = self.imageView.frame;

    self.imageView.frame = CGRectMake(10, 10, frame.size.height, frame.size.height);
}

@end
