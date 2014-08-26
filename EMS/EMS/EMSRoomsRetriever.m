//
//  EMSRoomsRetriever.m
//

#import "EMSAppDelegate.h"

#import "EMSRoomsRetriever.h"
#import "EMSRoom.h"

#import "CJCollection.h"
#import "CJItem.h"
#import "EMSTracking.h"

@implementation EMSRoomsRetriever

NSDate *timer;

- (NSArray *)processData:(NSData *)data forHref:(NSURL *)href {
    NSError *error = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&error];

    if (!collection) {
        EMS_LOG(@"Failed to retrieve rooms %@ - %@ - %@", href, error, [error userInfo]);

        return [NSArray array];
    }

    NSMutableArray *temp = [[NSMutableArray alloc] init];

    [collection.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CJItem *item = (CJItem *) obj;

        EMSRoom *room = [[EMSRoom alloc] init];

        room.href = item.href;

        [item.data enumerateObjectsUsingBlock:^(id dataObj, NSUInteger dataIdx, BOOL *dataStop) {
            NSDictionary *dict = (NSDictionary *) dataObj;

            NSString *field = dict[@"name"];
            NSString *value = dict[@"value"];

            if ([@"name" isEqualToString:field]) {
                room.name = value;
            }
        }];

        [temp addObject:room];
    }];

    return [NSArray arrayWithArray:temp];
}

- (void)fetchedRooms:(NSData *)responseData forHref:(NSURL *)href {
    NSArray *collection = [self processData:responseData forHref:href];

    [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"rooms"];
    [EMSTracking dispatch];

    [self.delegate finishedRooms:collection forHref:href];
}


- (void)parse:(NSData *)data forHref:(NSURL *)url withParseQueue:(dispatch_queue_t)queue; {
    if (url == nil) {
        EMS_LOG(@"Asked to fetch nil rooms url");

        return;
    }

    dispatch_async(queue, ^{
        [self fetchedRooms:data forHref:url];
    });
}

@end
