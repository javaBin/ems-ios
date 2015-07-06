#import "EMSSessionTitleTableViewCell.h"

@interface EMSSessionTitleTableViewCell ()

@end

@implementation EMSSessionTitleTableViewCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat leftInset = 15;
    CGFloat rightInset = 15;
    CGFloat favoriteButtonWidth = 44;
    CGFloat favoriteButtonSpacing = 8;
    CGFloat preferredWidth = CGRectGetWidth(self.bounds) - (leftInset + rightInset + favoriteButtonWidth + favoriteButtonSpacing);
    
    self.titleLabel.preferredMaxLayoutWidth = preferredWidth;
    
    [super layoutSubviews];
}

@end
