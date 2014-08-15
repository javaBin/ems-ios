//
//  EMSDefaultTableViewCell.m
//  EMS
//
//  Created by Jobb on 16.08.14.
//  Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import "EMSDefaultTableViewCell.h"

@implementation EMSDefaultTableViewCell

- (void)layoutSubviews {
    
    self.textLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.bounds) - 20;
    
    [self.textLabel sizeToFit];
    
    [super layoutSubviews];
}

- (CGSize)intrinsicContentSize {
    [self.textLabel sizeToFit];
    return CGSizeMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.textLabel.frame) + 20);
}

@end
