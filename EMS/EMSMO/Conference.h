//
//  Conference.h
//  EMS
//
//  Created by Chris Searle on 6/19/13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ConferenceKeyword, ConferenceLevel, Room, Session, Slot;

@interface Conference : NSManagedObject

@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSNumber * hintCount;
@property (nonatomic, retain) NSString * href;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * roomCollection;
@property (nonatomic, retain) NSString * sessionCollection;
@property (nonatomic, retain) NSString * slotCollection;
@property (nonatomic, retain) NSString * slug;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSString * venue;
@property (nonatomic, retain) NSSet *conferenceKeywords;
@property (nonatomic, retain) NSSet *conferenceLevels;
@property (nonatomic, retain) NSSet *rooms;
@property (nonatomic, retain) NSSet *sessions;
@property (nonatomic, retain) NSSet *slots;
@end

@interface Conference (CoreDataGeneratedAccessors)

- (void)addConferenceKeywordsObject:(ConferenceKeyword *)value;
- (void)removeConferenceKeywordsObject:(ConferenceKeyword *)value;
- (void)addConferenceKeywords:(NSSet *)values;
- (void)removeConferenceKeywords:(NSSet *)values;

- (void)addConferenceLevelsObject:(ConferenceLevel *)value;
- (void)removeConferenceLevelsObject:(ConferenceLevel *)value;
- (void)addConferenceLevels:(NSSet *)values;
- (void)removeConferenceLevels:(NSSet *)values;

- (void)addRoomsObject:(Room *)value;
- (void)removeRoomsObject:(Room *)value;
- (void)addRooms:(NSSet *)values;
- (void)removeRooms:(NSSet *)values;

- (void)addSessionsObject:(Session *)value;
- (void)removeSessionsObject:(Session *)value;
- (void)addSessions:(NSSet *)values;
- (void)removeSessions:(NSSet *)values;

- (void)addSlotsObject:(Slot *)value;
- (void)removeSlotsObject:(Slot *)value;
- (void)addSlots:(NSSet *)values;
- (void)removeSlots:(NSSet *)values;

@end
