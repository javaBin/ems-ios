//
//  Speaker.h
//  EMS
//
//  Created by Chris Searle on 20.06.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface Speaker : NSManagedObject

@property (nonatomic, retain) NSString * bio;
@property (nonatomic, retain) NSString * href;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * thumbnailUrl;
@property (nonatomic, retain) Session *session;

@end
