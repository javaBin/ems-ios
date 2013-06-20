//
//  Slot.h
//  EMS
//
//  Created by Chris Searle on 20.06.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conference, Session;

@interface Slot : NSManagedObject

@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSString * href;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) Conference *conference;
@property (nonatomic, retain) NSSet *sessions;
@end

@interface Slot (CoreDataGeneratedAccessors)

- (void)addSessionsObject:(Session *)value;
- (void)removeSessionsObject:(Session *)value;
- (void)addSessions:(NSSet *)values;
- (void)removeSessions:(NSSet *)values;

@end
