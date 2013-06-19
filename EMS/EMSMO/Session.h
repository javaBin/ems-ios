//
//  Session.h
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conference, Keyword, Room, Slot, Speaker;

@interface Session : NSManagedObject

@property (nonatomic, retain) NSString * attachmentCollection;
@property (nonatomic, retain) NSString * audience;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * favourite;
@property (nonatomic, retain) NSString * format;
@property (nonatomic, retain) NSString * href;
@property (nonatomic, retain) NSString * language;
@property (nonatomic, retain) NSString * level;
@property (nonatomic, retain) NSString * roomName;
@property (nonatomic, retain) NSString * slotName;
@property (nonatomic, retain) NSString * slug;
@property (nonatomic, retain) NSString * speakerCollection;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Conference *conference;
@property (nonatomic, retain) NSSet *keywords;
@property (nonatomic, retain) Room *room;
@property (nonatomic, retain) Slot *slot;
@property (nonatomic, retain) NSSet *speakers;
@end

@interface Session (CoreDataGeneratedAccessors)

- (void)addKeywordsObject:(Keyword *)value;
- (void)removeKeywordsObject:(Keyword *)value;
- (void)addKeywords:(NSSet *)values;
- (void)removeKeywords:(NSSet *)values;

- (void)addSpeakersObject:(Speaker *)value;
- (void)removeSpeakersObject:(Speaker *)value;
- (void)addSpeakers:(NSSet *)values;
- (void)removeSpeakers:(NSSet *)values;

@end
