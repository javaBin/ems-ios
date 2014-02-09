//
//  Speaker.h
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface Speaker : NSManagedObject

@property(nonatomic, retain) NSString *bio;
@property(nonatomic, retain) NSString *href;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *thumbnailUrl;
@property(nonatomic, retain) Session *session;

@end
