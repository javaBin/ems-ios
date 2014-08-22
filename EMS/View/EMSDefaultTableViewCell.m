//
//  EMSDefaultTableViewCell.m
//

#import "EMSDefaultTableViewCell.h"

@implementation EMSDefaultTableViewCell

- (void)layoutSubviews {
    
    self.textLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.bounds) - 20;
    
    [super layoutSubviews];
}

- (CGSize)intrinsicContentSize {
    [self.textLabel sizeToFit];
    return CGSizeMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.textLabel.frame) + 20);
}

@end
