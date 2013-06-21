//
//  EMSSessionsRetriever.m
//

#import "EMSAppDelegate.h"

#import "EMSSessionsRetriever.h"
#import "EMSSession.h"
#import "EMSSpeaker.h"

#import "CJCollection.h"
#import "CJItem.h"
#import "CJLink.h"

@implementation EMSSessionsRetriever

- (NSArray *)processData:(NSData *)data forHref:(NSURL *)href {
    NSError *error = nil;
    
    CJCollection *collection = [CJCollection collectionForNSData:data error:&error];
    
    if (!collection) {
        CLS_LOG(@"Failed to retrieve sessions %@ - %@ - %@", href, error, [error userInfo]);
        
        return [NSArray array];
    }
    
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    
    [collection.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CJItem *item = (CJItem *)obj;
        
        EMSSession *session = [[EMSSession alloc] init];
        
        session.keywords = nil;
        
        session.href = item.href;
        
        [item.data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dict = (NSDictionary *)obj;
            
            NSString *field = [dict objectForKey:@"name"];
            NSObject *value = [dict objectForKey:@"value"];
            
            if ([@"format" isEqualToString:field]) {
                session.format = (NSString *)value;
            }
            if ([@"body" isEqualToString:field]) {
                session.body = (NSString *)value;
            }
            if ([@"state" isEqualToString:field]) {
                session.state = (NSString *)value;
            }
            if ([@"slug" isEqualToString:field]) {
                session.slug = (NSString *)value;
            }
            if ([@"audience" isEqualToString:field]) {
                session.audience = (NSString *)value;
            }
            if ([@"title" isEqualToString:field]) {
                session.title = (NSString *)value;
            }
            if ([@"lang" isEqualToString:field]) {
                session.language = (NSString *)value;
            }
            if ([@"summary" isEqualToString:field]) {
                session.summary = (NSString *)value;
            }
            if ([@"level" isEqualToString:field]) {
                session.level = (NSString *)value;
            }
            if ([@"keywords" isEqualToString:field]) {
                session.keywords = [NSArray arrayWithArray:[dict objectForKey:@"array"]];
            }
        }];
        
        NSMutableArray *speakers = [[NSMutableArray alloc] init];
        
        [item.links enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CJLink *link = (CJLink *)obj;
            
            if ([@"attachment collection" isEqualToString:link.rel]) {
                session.attachmentCollection = link.href;
            }
            if ([@"speaker collection" isEqualToString:link.rel]) {
                session.speakerCollection = link.href;
            }
            if ([@"room item" isEqualToString:link.rel]) {
                session.roomItem = link.href;
            }
            if ([@"slot item" isEqualToString:link.rel]) {
                session.slotItem = link.href;
            }
            if ([@"speaker item" isEqualToString:link.rel]) {
                EMSSpeaker *speaker = [[EMSSpeaker alloc] init];
                
                speaker.href = link.href;
                speaker.name = link.prompt;
                
                [speakers addObject:speaker];
            }
        }];
        
        session.speakers = [NSArray arrayWithArray:speakers];
        
        [temp addObject:session];
    }];

    return [NSArray arrayWithArray:temp];
}

- (void)fetchedSessions:(NSData *)responseData forHref:(NSURL *)href {
    NSArray *collection = [self processData:responseData forHref:href];
    
    [[EMSAppDelegate sharedAppDelegate] stopNetwork];

    [self.delegate finishedSessions:collection forHref:href];
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
            [self fetchedSessions:root forHref:url];
        });
    });
}

@end
