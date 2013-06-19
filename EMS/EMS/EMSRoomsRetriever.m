//
//  EMSRoomsRetriever.m
//

#import "EMSAppDelegate.h"

#import "EMSRoomsRetriever.h"
#import "EMSRoom.h"

#import "CJCollection.h"
#import "CJItem.h"

@implementation EMSRoomsRetriever

- (void)fetchedRooms:(NSData *)responseData forHref:(NSURL *)href {
    CJCollection *collection = [CJCollection collectionForNSData:responseData];
    
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
    
    [[EMSAppDelegate sharedAppDelegate] stopNetwork];

    [self.delegate finishedRooms:[NSArray arrayWithArray:temp] forHref:href];
}


- (void) fetch:(NSURL *)url {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    dispatch_async(queue, ^{
        NSData* root = [NSData dataWithContentsOfURL:url];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedRooms:root forHref:url];
        });
    });
}

@end
