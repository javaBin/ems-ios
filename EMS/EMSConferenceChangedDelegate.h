//
//  EMSConferenceChangedDelegate.h
//  EMS
//
//  Created by Chris Searle on 17.06.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EMSConferenceChangedDelegate <NSObject>

@required

- (void)conferenceChanged:(id)sender;

@end
