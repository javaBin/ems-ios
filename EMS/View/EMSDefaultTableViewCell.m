//
//  EMSDefaultTableViewCell.m
//

#import "EMSDefaultTableViewCell.h"

@implementation EMSDefaultTableViewCell

- (CGSize)intrinsicContentSize {

    CGFloat preferredWidth = CGRectGetWidth(self.bounds) - self.separatorInset.left * 2;
    
    
    UIFont *cellFont = self.textLabel.font;
    CGSize constraintSize = CGSizeMake(preferredWidth, MAXFLOAT);
    CGSize labelSize = [self.textLabel.text sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
    
    
    return CGSizeMake(CGRectGetWidth(self.frame), labelSize.height + 20);
}

@end
