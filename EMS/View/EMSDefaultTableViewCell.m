//
//  EMSDefaultTableViewCell.m
//

#import "EMSDefaultTableViewCell.h"

@implementation EMSDefaultTableViewCell

- (CGSize)intrinsicContentSize {

    CGFloat prefferedWidth = CGRectGetWidth(self.bounds) - 20;
    
    
    UIFont *cellFont = self.textLabel.font;
    CGSize constraintSize = CGSizeMake(prefferedWidth, MAXFLOAT);
    CGSize labelSize = [self.textLabel.text sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
    
    
    return CGSizeMake(CGRectGetWidth(self.frame), labelSize.height + 20);
}

@end
