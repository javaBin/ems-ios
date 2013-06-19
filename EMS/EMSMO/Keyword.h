//
//  Keyword.h
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface Keyword : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Session *session;

@end
