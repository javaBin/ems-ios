//
//  EMS
//

#import "EMSTopAlignCellTableViewCell.h"

@interface EMSTopAlignCellTableViewCell ()

@property(readwrite, nonatomic) IBOutlet UILabel *nameLabel;

@property(readwrite, nonatomic) IBOutlet UILabel *descriptionLabel;

@property(readwrite, nonatomic) IBOutlet UIImageView *thumbnailView;

@end

@implementation EMSTopAlignCellTableViewCell

- (void)dealloc {
    self.nameLabel = nil;
    self.descriptionLabel = nil;
    self.thumbnailView = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat leftInset = 15;
    CGFloat rightInset = 15;
    self.descriptionLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.bounds) - (leftInset + rightInset);
    
    [super layoutSubviews];
}


@end
