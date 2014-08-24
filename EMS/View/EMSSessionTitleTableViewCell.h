//
//  EMSSessionTitleTableViewCell.h
//  EMS
//
//  Created by Jobb on 24.08.14.
//  Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMSSessionTitleTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *timeAndRoomLabel;

@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;

@end
