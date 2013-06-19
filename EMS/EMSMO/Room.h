//
//  Room.h
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conference, Session;

@interface Room : NSManagedObject

@property (nonatomic, retain) NSString * href;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Conference *conference;
@property (nonatomic, retain) NSSet *sessions;
@end

@interface Room (CoreDataGeneratedAccessors)

- (void)addSessionsObject:(Session *)value;
- (void)removeSessionsObject:(Session *)value;
- (void)addSessions:(NSSet *)values;
- (void)removeSessions:(NSSet *)values;

@end
