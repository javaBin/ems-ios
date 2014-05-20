//
//  EMSTopAlignCellTableViewCell.m
//  EMS
//
//  Created by Chris Searle on 20.05.14.
//  Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import "EMSTopAlignCellTableViewCell.h"

@implementation EMSTopAlignCellTableViewCell

- (void) layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.imageView.frame;
    
    self.imageView.frame = CGRectMake( 10, 10, frame.size.height, frame.size.height );
}

@end
