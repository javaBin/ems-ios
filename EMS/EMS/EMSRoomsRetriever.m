//
//  EMSRoomsRetriever.m
//

#import "EMSAppDelegate.h"

#import "EMSRoomsRetriever.h"
#import "EMSRoom.h"

#import "CJCollection.h"
#import "CJItem.h"

@implementation EMSRoomsRetriever

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

    [self.delegate finishedRooms:collection forHref:href];
}


- (void) fetch:(NSURL *)url {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    dispatch_async(queue, ^{
        NSError *rootError = nil;
        
        NSData* root = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&rootError];
        
        if (root == nil) {
            CLS_LOG(@"Retrieved nil root %@ - %@ - %@", url, rootError, [rootError userInfo]);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedRooms:root forHref:url];
        });
    });
}

@end
