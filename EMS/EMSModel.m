//
//  EMSModel.m
//

#import "EMSModel.h"

#import "EMSConference.h"
#import "EMSSlot.h"
#import "EMSRoom.h"
#import "EMSSession.h"

#import "EMSAppDelegate.h"

@implementation EMSModel

@synthesize managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc {
    self = [super init];
    
    self.managedObjectContext = moc;
    
    return self;
}

#pragma mark - get list of objects

- (NSArray *)objectsForPredicate:(NSPredicate *)predicate andSort:(NSArray *)sort withType:(NSString *)type{
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    [fetchRequest setEntity:[NSEntityDescription entityForName:type inManagedObjectContext:[self managedObjectContext]]];
    
    [fetchRequest setPredicate: predicate];
    
    if (sort != nil) {
        [fetchRequest setSortDescriptors:sort];
    }
    
    NSError *error;
    
    NSArray *objects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    
    // TODO - handle error
    
    return objects;
}

- (NSArray *)conferencesForPredicate:(NSPredicate *)predicate andSort:(NSArray *)sort {
    return [self objectsForPredicate:predicate andSort:sort withType:@"Conference"];
}

- (NSArray *)slotsForPredicate:(NSPredicate *)predicate andSort:(NSArray *)sort {
    return [self objectsForPredicate:predicate andSort:sort withType:@"Slot"];
}

- (NSArray *)sessionsForPredicate:(NSPredicate *)predicate andSort:(NSArray *)sort {
    return [self objectsForPredicate:predicate andSort:sort withType:@"Session"];
}

- (NSArray *)roomsForPredicate:(NSPredicate *)predicate andSort:(NSArray *)sort {
    return [self objectsForPredicate:predicate andSort:sort withType:@"Room"];
}

#pragma mark - get single object

- (NSManagedObject *)conferenceForHref:(NSString *)url {
    NSArray *matched = [self
                        conferencesForPredicate:[NSPredicate predicateWithFormat: @"(href LIKE %@)", url]
                        andSort:nil];
    
    if (matched.count > 0) {
        return [matched objectAtIndex:0];
    }
    
    return nil;
}

- (NSManagedObject *)slotForHref:(NSString *)url {
    NSArray *matched = [self
                        slotsForPredicate:[NSPredicate predicateWithFormat: @"(href LIKE %@)", url]
                        andSort:nil];
    
    if (matched.count > 0) {
        return [matched objectAtIndex:0];
    }
    
    return nil;
}

- (NSManagedObject *)roomForHref:(NSString *)url {
    NSArray *matched = [self
                        roomsForPredicate:[NSPredicate predicateWithFormat: @"(href LIKE %@)", url]
                        andSort:nil];
    
    if (matched.count > 0) {
        return [matched objectAtIndex:0];
    }
    
    return nil;
}

- (NSManagedObject *)sessionForHref:(NSString *)url {
    NSArray *matched = [self
                        sessionsForPredicate:[NSPredicate predicateWithFormat: @"(href LIKE %@)", url]
                        andSort:nil];
    
    if (matched.count > 0) {
        return [matched objectAtIndex:0];
    }
    
    return nil;
}

#pragma mark - create hash from href to object

- (NSDictionary *)conferencesKeyedByHref:(NSArray *)conferences {
    NSMutableDictionary *hrefKeyed = [[NSMutableDictionary alloc] init];
    
    [conferences enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EMSConference *ems = (EMSConference *)obj;
        [hrefKeyed setValue:ems forKey:[ems.href absoluteString]];
    }];
    
    return [NSDictionary dictionaryWithDictionary:hrefKeyed];
}

- (NSDictionary *)slotsKeyedByHref:(NSArray *)slots {
    NSMutableDictionary *hrefKeyed = [[NSMutableDictionary alloc] init];
    
    [slots enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EMSSlot *ems = (EMSSlot *)obj;
        [hrefKeyed setValue:ems forKey:[ems.href absoluteString]];
    }];
    
    return [NSDictionary dictionaryWithDictionary:hrefKeyed];
}

- (NSDictionary *)roomsKeyedByHref:(NSArray *)slots {
    NSMutableDictionary *hrefKeyed = [[NSMutableDictionary alloc] init];
    
    [slots enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EMSRoom *ems = (EMSRoom *)obj;
        [hrefKeyed setValue:ems forKey:[ems.href absoluteString]];
    }];
    
    return [NSDictionary dictionaryWithDictionary:hrefKeyed];
}

- (NSDictionary *)sessionsKeyedByHref:(NSArray *)slots {
    NSMutableDictionary *hrefKeyed = [[NSMutableDictionary alloc] init];
    
    [slots enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EMSSession *ems = (EMSSession *)obj;
        [hrefKeyed setValue:ems forKey:[ems.href absoluteString]];
    }];
    
    return [NSDictionary dictionaryWithDictionary:hrefKeyed];
}

#pragma mark - populate managed object from EMS object

- (void)populateManagedObject:(NSManagedObject *)object withConference:(EMSConference *)conference {
    [object setValue:conference.name forKey:@"name"];
    [object setValue:conference.slug forKey:@"slug"];
    [object setValue:conference.venue forKey:@"venue"];
    [object setValue:[conference.href absoluteString] forKey:@"href"];
    [object setValue:conference.start forKey:@"start"];
    [object setValue:conference.end forKey:@"end"];
    [object setValue:[conference.roomCollection absoluteString] forKey:@"roomCollection"];
    [object setValue:[conference.sessionCollection absoluteString] forKey:@"sessionCollection"];
    [object setValue:[conference.slotCollection absoluteString] forKey:@"slotCollection"];
}

- (void)populateManagedObject:(NSManagedObject *)object withSlot:(EMSSlot *)slot forConference:(NSManagedObject *)conference {
    [object setValue:slot.start forKey:@"start"];
    [object setValue:slot.end forKey:@"end"];
    [object setValue:[slot.href absoluteString] forKey:@"href"];
    [object setValue:conference forKey:@"conference"];
}

- (void)populateManagedObject:(NSManagedObject *)object withRoom:(EMSRoom *)room forConference:(NSManagedObject *)conference {
    [object setValue:room.name forKey:@"name"];
    [object setValue:[room.href absoluteString] forKey:@"href"];
    [object setValue:conference forKey:@"conference"];
}

- (void)populateManagedObject:(NSManagedObject *)object withSession:(EMSSession *)session forConference:(NSManagedObject *)conference {
    [object setValue:[session.href absoluteString] forKey:@"href"];
    [object setValue:session.title forKey:@"title"];
    [object setValue:session.format forKey:@"format"];
    [object setValue:session.body forKey:@"body"];
    [object setValue:session.state forKey:@"state"];
    [object setValue:session.slug forKey:@"slug"];
    [object setValue:session.audience forKey:@"audience"];
    [object setValue:session.language forKey:@"language"];
    [object setValue:session.summary forKey:@"summary"];
    [object setValue:session.level forKey:@"level"];
    // TODO keywords
    [object setValue:[session.attachmentCollection absoluteString] forKey:@"attachmentCollection"];
    [object setValue:[session.speakerCollection absoluteString] forKey:@"speakerCollection"];

    [object setValue:conference forKey:@"conference"];

    if (session.roomItem != nil) {
        NSManagedObject *room = [self roomForHref:[session.roomItem absoluteString]];
        [object setValue:room forKey:@"room"];
        [object setValue:[room valueForKey:@"name"] forKey:@"roomName"];
    }
    
    if (session.slotItem != nil) {
        NSManagedObject *slot = [self slotForHref:[session.slotItem absoluteString]];

        [object setValue:slot forKey:@"slot"];
    
        NSDateFormatter *dateFormatterDate = [[NSDateFormatter alloc] init];
        NSDateFormatter *dateFormatterTime = [[NSDateFormatter alloc] init];
    
        [dateFormatterDate setDateFormat:@"yyyy-MM-dd"];
        [dateFormatterTime setDateFormat:@"HH:mm"];
    
        [object setValue:[NSString stringWithFormat:@"%@ %@ - %@",
                          [dateFormatterDate stringFromDate:[slot valueForKey:@"start"]],
                          [dateFormatterTime stringFromDate:[slot valueForKey:@"start"]],
                          [dateFormatterTime stringFromDate:[slot valueForKey:@"end"]]]
                  forKey:@"slotName"];
    }
}

#pragma mark - public interface

- (void) storeConferences:(NSArray *)conferences error:(NSError**)error {
    NSDictionary *hrefKeyed = [self conferencesKeyedByHref:conferences];

    NSArray *sortedHrefs = [hrefKeyed.allKeys sortedArrayUsingSelector: @selector(compare:)];

    NSArray *sort = @[[[NSSortDescriptor alloc] initWithKey: @"href" ascending:YES]];
    
    // Get two lists - all matching - all not matching
    NSArray *matched = [self
                        conferencesForPredicate:[NSPredicate predicateWithFormat: @"(href IN %@)", sortedHrefs]
                        andSort:sort];

    NSArray *unmatched = [self
                          conferencesForPredicate:[NSPredicate predicateWithFormat: @"NOT (href IN %@)", sortedHrefs]
                          andSort:sort];

    
    // Walk thru non-matching and delete
    CLS_LOG(@"Deleting %d conferences", [unmatched count]);

    [unmatched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSManagedObject *managedObject = (NSManagedObject *)obj;

        [[self managedObjectContext] deleteObject:managedObject];
    }];
    
    // Walk thru matching and for each one - update. Store in list
    CLS_LOG(@"Updating %d conferences", [matched count]);

    NSMutableSet *seen = [[NSMutableSet alloc] init];
    
    [matched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSManagedObject *managedObject = (NSManagedObject *)obj;

        [seen addObject:[managedObject valueForKey:@"href"]];

        [self populateManagedObject:managedObject withConference:[hrefKeyed objectForKey:[managedObject valueForKey:@"href"]]];
    }];
    
    // Walk thru any new ones left
    CLS_LOG(@"Inserting from %d conferences with %d seen", [hrefKeyed count], [seen count]);

    [hrefKeyed enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![seen containsObject:key]) {
            NSManagedObject *managedObject = [NSEntityDescription
                                            insertNewObjectForEntityForName:@"Conference"
                                            inManagedObjectContext:[self managedObjectContext]];
            
            EMSConference *ems = (EMSConference *)obj;
            
            [self populateManagedObject:managedObject withConference:ems];
        }
    }];
    
    // TODO error
    [[self managedObjectContext] save:nil];
    
}

- (void) storeSlots:(NSArray *)slots forConference:(NSString *)href error:(NSError **)error {
    NSArray *conferences = [self
                            conferencesForPredicate:[NSPredicate predicateWithFormat: @"(slotCollection LIKE %@)", href]
                            andSort:nil];
    
    if (conferences.count == 0) {
        // TODO error
        return;
    }
    
    NSManagedObject *conference = [conferences objectAtIndex:0];

    NSDictionary *hrefKeyed = [self slotsKeyedByHref:slots];

    NSArray *sortedHrefs = [hrefKeyed.allKeys sortedArrayUsingSelector: @selector(compare:)];
    
    NSArray *sort = @[[[NSSortDescriptor alloc] initWithKey: @"href" ascending:YES]];
    
    // Get two lists - all matching - all not matching
    NSArray *matched = [self
                        slotsForPredicate:[NSPredicate predicateWithFormat: @"((href IN %@) AND conference == %@)", sortedHrefs, conference]
                        andSort:sort];
    
    NSArray *unmatched = [self
                          slotsForPredicate:[NSPredicate predicateWithFormat: @"((NOT (href IN %@)) AND conference == %@)", sortedHrefs, conference]
                          andSort:sort];
    
    
    // Walk thru non-matching and delete
    CLS_LOG(@"Deleting %d slots", [unmatched count]);

    [unmatched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSManagedObject *managedObject = (NSManagedObject *)obj;
        
        [[self managedObjectContext] deleteObject:managedObject];
    }];
    
    // Walk thru matching and for each one - update. Store in list
    CLS_LOG(@"Updating %d slots", [matched count]);

    NSMutableSet *seen = [[NSMutableSet alloc] init];
    
    [matched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSManagedObject *managedObject = (NSManagedObject *)obj;
        
        [seen addObject:[managedObject valueForKey:@"href"]];
        
        [self populateManagedObject:managedObject withSlot:[hrefKeyed objectForKey:[managedObject valueForKey:@"href"]] forConference:conference];
    }];
    
    // Walk thru any new ones left
    CLS_LOG(@"Inserting from %d slots with %d seen", [hrefKeyed count], [seen count]);

    [hrefKeyed enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![seen containsObject:key]) {
            NSManagedObject *managedObject = [NSEntityDescription
                                     insertNewObjectForEntityForName:@"Slot"
                                     inManagedObjectContext:[self managedObjectContext]];
            
            EMSSlot *ems = (EMSSlot *)obj;
            
            [self populateManagedObject:managedObject withSlot:ems forConference:conference];
        }
    }];
    
    // TODO error
    [[self managedObjectContext] save:nil];
}

- (void) storeRooms:(NSArray *)rooms forConference:(NSString *)href error:(NSError **)error {
    NSArray *conferences = [self
                            conferencesForPredicate:[NSPredicate predicateWithFormat: @"(roomCollection LIKE %@)", href]
                            andSort:nil];
    
    if (conferences.count == 0) {
        // TODO error
        return;
    }
    
    NSManagedObject *conference = [conferences objectAtIndex:0];
    
    NSDictionary *hrefKeyed = [self roomsKeyedByHref:rooms];
    
    NSArray *sortedHrefs = [hrefKeyed.allKeys sortedArrayUsingSelector: @selector(compare:)];
    
    NSArray *sort = @[[[NSSortDescriptor alloc] initWithKey: @"href" ascending:YES]];
    
    // Get two lists - all matching - all not matching
    NSArray *matched = [self
                        roomsForPredicate:[NSPredicate predicateWithFormat: @"((href IN %@) AND conference == %@)", sortedHrefs, conference]
                        andSort:sort];
    
    NSArray *unmatched = [self
                          roomsForPredicate:[NSPredicate predicateWithFormat: @"((NOT (href IN %@)) AND conference == %@)", sortedHrefs, conference]
                          andSort:sort];
    
    
    // Walk thru non-matching and delete
    CLS_LOG(@"Deleting %d rooms", [unmatched count]);

    [unmatched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSManagedObject *managedObject = (NSManagedObject *)obj;
        
        [[self managedObjectContext] deleteObject:managedObject];
    }];
    
    // Walk thru matching and for each one - update. Store in list
    CLS_LOG(@"Updating %d rooms", [matched count]);

    NSMutableSet *seen = [[NSMutableSet alloc] init];
    
    [matched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSManagedObject *managedObject = (NSManagedObject *)obj;
        
        [seen addObject:[managedObject valueForKey:@"href"]];
        
        [self populateManagedObject:managedObject withRoom:[hrefKeyed objectForKey:[managedObject valueForKey:@"href"]] forConference:conference];
    }];
    
    // Walk thru any new ones left
    CLS_LOG(@"Inserting from %d rooms with %d seen", [hrefKeyed count], [seen count]);

    [hrefKeyed enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![seen containsObject:key]) {
            NSManagedObject *managedObject = [NSEntityDescription
                                              insertNewObjectForEntityForName:@"Room"
                                              inManagedObjectContext:[self managedObjectContext]];
            
            EMSRoom *ems = (EMSRoom *)obj;
            
            [self populateManagedObject:managedObject withRoom:ems forConference:conference];
        }
    }];
    
    // TODO error
    [[self managedObjectContext] save:nil];
}

- (void) storeSessions:(NSArray *)sessions forConference:(NSString *)href error:(NSError **)error {
    NSArray *conferences = [self
                            conferencesForPredicate:[NSPredicate predicateWithFormat: @"(sessionCollection LIKE %@)", href]
                            andSort:nil];
    
    if (conferences.count == 0) {
        // TODO error
        return;
    }
    
    NSManagedObject *conference = [conferences objectAtIndex:0];
    
    NSDictionary *hrefKeyed = [self sessionsKeyedByHref:sessions];
    
    NSArray *sortedHrefs = [hrefKeyed.allKeys sortedArrayUsingSelector: @selector(compare:)];
    
    NSArray *sort = @[[[NSSortDescriptor alloc] initWithKey: @"href" ascending:YES]];
    
    // Get two lists - all matching - all not matching
    NSArray *matched = [self
                        sessionsForPredicate:[NSPredicate predicateWithFormat: @"((href IN %@) AND conference == %@)", sortedHrefs, conference]
                        andSort:sort];
    
    NSArray *unmatched = [self
                          sessionsForPredicate:[NSPredicate predicateWithFormat: @"((NOT (href IN %@)) AND conference == %@)", sortedHrefs, conference]
                          andSort:sort];
    
    
    // Walk thru non-matching and delete
    CLS_LOG(@"Deleting %d sessions", [unmatched count]);

    [unmatched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSManagedObject *managedObject = (NSManagedObject *)obj;
        
        [[self managedObjectContext] deleteObject:managedObject];
    }];
    
    // Walk thru matching and for each one - update. Store in list
    CLS_LOG(@"Updating %d sessions", [matched count]);

    NSMutableSet *seen = [[NSMutableSet alloc] init];
    
    [matched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSManagedObject *managedObject = (NSManagedObject *)obj;
        
        [seen addObject:[managedObject valueForKey:@"href"]];
        
        [self populateManagedObject:managedObject withSession:[hrefKeyed objectForKey:[managedObject valueForKey:@"href"]] forConference:conference];
    }];
    

    // Walk thru any new ones left
    CLS_LOG(@"Inserting from %d sessions with %d seen", [hrefKeyed count], [seen count]);
    
    [hrefKeyed enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![seen containsObject:key]) {
            NSManagedObject *managedObject = [NSEntityDescription
                                              insertNewObjectForEntityForName:@"Session"
                                              inManagedObjectContext:[self managedObjectContext]];
            
            EMSSession *ems = (EMSSession *)obj;
            
            [self populateManagedObject:managedObject withSession:ems forConference:conference];
        }
    }];
    
    // TODO error
    [[self managedObjectContext] save:nil];
}

@end
