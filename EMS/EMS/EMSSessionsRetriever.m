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
#import "EMSTracking.h"


@interface EMSSession (JsonParser)

+ (EMSSession *) sessionWithItem:(CJItem *) item;

@end

@implementation EMSSession(JsonParser)

+ (EMSSession *)sessionWithItem:(CJItem *) item
{
    EMSSession *session = [[EMSSession alloc] init];
    
    session.keywords = nil;
    
    session.href = item.href;
    
    for (NSDictionary *dict in item.data) {
        
        NSString *field = dict[@"name"];
        NSObject *value = dict[@"value"];
        
        if ([@"format" isEqualToString:field]) {
            session.format = (NSString *) value;
        }
        if ([@"body" isEqualToString:field]) {
            session.body = (NSString *) value;
        }
        if ([@"state" isEqualToString:field]) {
            session.state = (NSString *) value;
        }
        if ([@"audience" isEqualToString:field]) {
            session.audience = (NSString *) value;
        }
        if ([@"title" isEqualToString:field]) {
            session.title = (NSString *) value;
        }
        if ([@"lang" isEqualToString:field]) {
            session.language = (NSString *) value;
        }
        if ([@"summary" isEqualToString:field]) {
            session.summary = (NSString *) value;
        }
        if ([@"level" isEqualToString:field]) {
            session.level = (NSString *) value;
        }
        if ([@"keywords" isEqualToString:field]) {
            session.keywords = [NSArray arrayWithArray:dict[@"array"]];
        }
    }
    
    NSMutableArray *speakers = [[NSMutableArray alloc] init];
    
    
    for (CJLink *link in item.links) {
        
        if ([@"alternate video" isEqualToString:link.rel]) {
            session.videoLink = link.href;
        }
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
    }
    
    session.speakers = [NSArray arrayWithArray:speakers];
    
    return session;
}
@end

@implementation EMSSessionsRetriever

NSDate *timer;

- (NSArray *)processData:(NSData *)data forHref:(NSURL *)href {
    NSError *error = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&error];

    if (!collection) {
        EMS_LOG(@"Failed to retrieve sessions %@ - %@ - %@", href, error, [error userInfo]);

        return [NSArray array];
    }

    NSMutableArray *temp = [[NSMutableArray alloc] init];
    
    for (CJItem *item in collection.items) {
        EMSSession *session = [EMSSession sessionWithItem:item];
        [temp addObject:session];
    }

    return [NSArray arrayWithArray:temp];
}

- (void)fetchedSessions:(NSData *)responseData forHref:(NSURL *)href {
    NSArray *collection = [self processData:responseData forHref:href];

    [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"sessions"];
    [EMSTracking dispatch];

    [self.delegate finishedSessions:collection forHref:href];
}

- (void)fetch:(NSURL *)url withParseQueue:(dispatch_queue_t)queue {
    if (url == nil) {
        EMS_LOG(@"Asked to fetch nil sessions url");

        return;
    }

    NSURLSession *session = [NSURLSession sharedSession];

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", url, error, [error userInfo]);
        }

        dispatch_async(queue, ^{
            [self fetchedSessions:data forHref:url];
        });

        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];
}

@end
