//
//  EMSConferenceDetailViewController.h
//  EMS
//
//  Created by Chris Searle on 29.08.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Conference.h"

@interface EMSConferenceDetailViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) Conference *conference;

@end
