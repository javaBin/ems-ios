//
//  ConferenceType.h

//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conference;

@interface ConferenceType : NSManagedObject

@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) Conference *conference;

@end
