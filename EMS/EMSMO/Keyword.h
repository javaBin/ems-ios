//
//  Keyword.h
//  EMS
//
//  Created by Chris Searle on 6/19/13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface Keyword : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Session *session;

@end
