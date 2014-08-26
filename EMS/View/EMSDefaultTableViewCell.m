//
//  EMSDefaultTableViewCell.m
//

#import "EMSDefaultTableViewCell.h"

@implementation EMSDefaultTableViewCell

- (CGSize)intrinsicContentSize {

    CGFloat preferredWidth = CGRectGetWidth(self.bounds) - self.separatorInset.left * 2;
    
    CGSize constraintSize = CGSizeMake(preferredWidth, MAXFLOAT);
    
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = self.textLabel.lineBreakMode;
    paragraphStyle.alignment = self.textLabel.textAlignment;
    
    NSDictionary *attributes = @{NSFontAttributeName : self.textLabel.font };
    
    CGRect rect = [self.textLabel.text boundingRectWithSize:constraintSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    
    return CGSizeMake(CGRectGetWidth(self.frame), ceil(CGRectGetHeight(rect)) + 20);
}

@end
