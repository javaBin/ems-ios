//
//  EMSRoomsRetriever.m
//

#import "EMSAppDelegate.h"

#import "EMSRoomsRetriever.h"
#import "EMSRoom.h"

#import "CJCollection.h"
#import "CJItem.h"

@implementation EMSRoomsRetriever

NSDate *timer;

- (NSArray *)processData:(NSData *)data forHref:(NSURL *)href {
    NSError *error = nil;
    
    CJCollection *collection = [CJCollection collectionForNSData:data error:&error];
    
    if (!collection) {
        CLS_LOG(@"Failed to retrieve rooms %@ - %@ - %@", href, error, [error userInfo]);
        
        return [NSArray array];
    }
    
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    
    [collection.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CJItem *item = (CJItem *)obj;
        
        EMSRoom *room = [[EMSRoom alloc] init];
        
        room.href = item.href;
        
        [item.data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dict = (NSDictionary *)obj;
            
            NSString *field = [dict objectForKey:@"name"];
            NSString *value = [dict objectForKey:@"value"];
            
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
    
    [[EMSAppDelegate sharedAppDelegate] stopNetwork];

#ifndef DO_NOT_USE_GA
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendTimingWithCategory:@"retrieval"
                          withValue:[[NSDate date] timeIntervalSinceDate:timer]
                           withName:@"rooms"
                          withLabel:nil];

    [[GAI sharedInstance] dispatch];
#endif
    
    [self.delegate finishedRooms:collection forHref:href];
}


- (void) fetch:(NSURL *)url {
    if (url == nil) {
        CLS_LOG(@"Asked to fetch nil rooms url");

        return;
    }
    
    dispatch_queue_t queue = dispatch_queue_create("ems_room_queue", DISPATCH_QUEUE_CONCURRENT);
    
    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    timer = [NSDate date];

    dispatch_async(queue, ^{
        NSError *rootError = nil;
        
        NSData* root = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&rootError];
        
        if (root == nil) {
            CLS_LOG(@"Retrieved nil root %@ - %@ - %@", url, rootError, [rootError userInfo]);
        }
        
        dispatch_async(queue, ^{
            [self fetchedRooms:root forHref:url];
        });
    });
}

@end
