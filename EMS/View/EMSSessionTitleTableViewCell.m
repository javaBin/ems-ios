//
//  EMSSessionTitleTableViewCell.m
//  EMS
//
//  Created by Jobb on 24.08.14.
//  Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import "EMSSessionTitleTableViewCell.h"

@interface EMSSessionTitleTableViewCell ()

@end

@implementation EMSSessionTitleTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

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
