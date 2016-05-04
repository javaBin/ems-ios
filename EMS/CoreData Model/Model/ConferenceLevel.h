//
//  ConferenceLevel.h
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conference;

@interface ConferenceLevel : NSManagedObject

@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) Conference *conference;

@end
