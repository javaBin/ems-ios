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
    
    self.titleLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.bounds) - 44 - 15;
}

@end