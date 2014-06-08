//
//  EMSSyncService.h
//  EMS
//
//  Created by Jobb on 05.06.14.
//  Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMSSyncService : NSObject

@property(readonly) BOOL syncing;

- (void) sync;

@end
