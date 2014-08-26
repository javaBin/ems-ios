//
//  EMSSessionCell.m
//

#import "EMSSessionCell.h"

@implementation EMSSessionCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width = CGRectGetWidth(self.contentView.bounds) - 60;
    
    self.title.preferredMaxLayoutWidth = width;
    
    [super layoutSubviews];
}

@end
