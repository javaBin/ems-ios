//
//  EMSSlot.h
//  EMS
//
//  Created by Chris Searle on 12.06.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMSSlot : NSObject

@property (strong, nonatomic) NSDate   *start;
@property (strong, nonatomic) NSDate   *end;

@property (strong, nonatomic) NSURL *href;

@end
